#!/usr/bin/env bash
# NixOS Multi-Machine Deployment Tool
# Fully auditable, multi-host deployment with GC backups, logging, and dry-run

set -euo pipefail

# ─── Colors & Logging ──────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ─── Globals ──────────────────────────────────────────────────────
FLAKE_DIR="${FLAKE_DIR:-$HOME/NixOS}"
LOCK_FILE="/var/run/nixos-deploy.lock"
GC_ROOT_DIR="${GC_ROOT_DIR:-/nix/var/nix/gcroots/deploy}"
ENVIRONMENT="${ENVIRONMENT:-development}"
DEBUG="${DEBUG:-false}"
DRY_RUN="${DRY_RUN:-false}"
FORCE="${FORCE:-false}"
DEPLOY_TIMEOUT="${DEPLOY_TIMEOUT:-3600}"  # seconds
LOG_DIR=$(realpath "${FLAKE_DIR}/logs")
MACHINES=("Station-00" "Scout-02" "Subrelay-01")

# ─── Safety & Locking ─────────────────────────────────────────────
sudo mkdir -p "$(dirname "$LOCK_FILE")"
if sudo test -e "$LOCK_FILE"; then
    log_error "Another deployment is in progress"
    exit 1
fi
sudo touch "$LOCK_FILE"
mkdir -p "$LOG_DIR" "$GC_ROOT_DIR"
trap 'log_error "Deployment interrupted"; sudo rm -f "$LOCK_FILE"; exit 1' INT TERM

# ─── Helpers ─────────────────────────────────────────────────────
git_commit_hash() {
    local commit
    commit=$(cd "$FLAKE_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    echo "$commit"
}

quoted_cmd() {
    local arg
    for arg in "$@"; do
        printf "%q " "$arg"
    done
    printf "\n"
}

log_deployment() {
    local machine=$1 host=$2 commit_hash=$3 gen=$4
    local line
    line="[$(date '+%Y-%m-%d %H:%M:%S')] Machine: $machine | Host: $host | Commit: $commit_hash | Generation: ${gen:-unknown}"
    echo "$line" >> "${LOG_DIR}/deploy.log"
    if [[ -n "$machine" ]]; then
        echo "$line" >> "${LOG_DIR}/${machine}.log"
    fi
}

machine_log() {
    local machine=$1
    shift
    local msg="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" >> "${LOG_DIR}/${machine}.log"
}

check_sudo() { sudo -n true &>/dev/null || log_warn "Sudo required, may prompt for password"; }
check_host() { ping -c 1 -W 2 "${1%%@*}" &>/dev/null; }

validate_machine_path() {
    local machine=$1
    if [[ ! -f "${FLAKE_DIR}/hosts/${machine}/default.nix" && ! -f "${FLAKE_DIR}/hosts/${machine}/configuration.nix" ]]; then
        log_error "Invalid machine: ${machine} (expected hosts/${machine}/{default,configuration}.nix)"
        return 1
    fi
}

validate_machine() {
    local machine=$1
    if [[ ! " ${MACHINES[*]} " =~ ${machine} ]]; then
        log_error "Machine '$machine' not in allowed list: ${MACHINES[*]}"
        return 1
    fi
    validate_machine_path "$machine"
}

# ─── Deployment ───────────────────────────────────────────────────
deploy_machine() {
    local machine=$1 target_host=${2:-} build_host=${3:-}
    local machine_lock="/var/run/nixos-deploy-${machine}.lock"

    sudo mkdir -p "$(dirname "$machine_lock")"
    if sudo test -e "$machine_lock"; then
        log_warn "Another deployment is in progress for $machine"
        return 1
    fi
    sudo touch "$machine_lock"
    trap 'sudo rm -f "$machine_lock"; exit' INT TERM EXIT

    validate_machine "$machine" || return 1
    check_sudo

    if [[ "$ENVIRONMENT" == production && "$FORCE" != true ]]; then
        read -r -t 60 -p "Deploying to PRODUCTION ($machine). Continue? (y/N) " REPLY || {
            log_error "Timeout waiting for confirmation"
            return 1
        }
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_warn "Cancelled deployment"
            return 1
        fi
    fi

    lint_configuration || return 1

    # GC backup
    local commit backup_name current gen
    commit=$(git_commit_hash)
    current="/run/current-system"
    backup_name="backup-${commit}-$(date +%Y%m%d-%H%M%S)"
    if [[ -e "$current" ]]; then
        sudo ln -sfn "$current" "$GC_ROOT_DIR/$backup_name"
        log_info "Created GC root backup: $GC_ROOT_DIR/$backup_name"
    else
        log_warn "Cannot resolve /run/current-system for backup"
    fi

    machine_log "$machine" "Starting deployment; commit=${commit} host=${target_host:-local}"

    build_toplevel "$machine"
    test_configuration "$machine" || return 1

    local args=(--flake ".#${machine}" --fast)
    [[ "$DEBUG" == true ]] && args+=(--show-trace --verbose)
    [[ -n "$target_host" ]] && args+=(--target-host "$target_host" --use-remote-sudo)
    [[ -n "$build_host" ]] && args+=(--build-host "$build_host" --use-remote-sudo)

    gen=$(sudo nixos-rebuild list-generations 2>/dev/null | tail -n1 | awk '{print $1}')

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] $(quoted_cmd timeout "$DEPLOY_TIMEOUT" sudo nixos-rebuild switch "${args[@]}")"
        machine_log "$machine" "[DRY RUN] nixos-rebuild switch $(printf '%q ' "${args[@]}")"
        log_deployment "$machine" "${target_host:-local}" "$commit" "$gen"
        sudo rm -f "$machine_lock"
        trap - INT TERM EXIT
        return 0
    fi

    log_info "Running: nixos-rebuild switch ${args[*]}"
    machine_log "$machine" "Running: nixos-rebuild switch ${args[*]}"

    if timeout "$DEPLOY_TIMEOUT" sudo nixos-rebuild switch "${args[@]}"; then
        log_info "Deployment successful for $machine"
        machine_log "$machine" "Deployment successful"
        log_deployment "$machine" "${target_host:-local}" "$commit" "$gen"
        show_diff "$machine"
    else
        log_error "Deployment failed for $machine"
        machine_log "$machine" "Deployment failed, attempting rollback"
        rollback_system
        sudo rm -f "$machine_lock"
        trap - INT TERM EXIT
        return 1
    fi

    sudo rm -f "$machine_lock"
    trap - INT TERM EXIT
}

# ─── Additional Utilities ─────────────────────────────────────────
build_toplevel() { nix build --flake "${FLAKE_DIR}#${1}" || return 1; }

test_configuration() {
    local machine=$1
    log_info "Testing configuration for ${machine}..."
    if run_cmd sudo nixos-rebuild test --flake ".#${machine}" "${REBUILD_ARGS:-}"; then
        log_info "Test passed"
    else
        log_error "Test failed for ${machine}"
        return 1
    fi
}

show_diff() {
    local machine=$1
    if [[ ! -L ./result ]]; then
        log_warn "No ./result to diff against"
        return
    fi
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] $(quoted_cmd nix store diff-closures /run/current-system ./result)"
        return
    fi
    if command -v nix &>/dev/null; then
        log_info "Showing diff (nix store diff-closures)"
        nix store diff-closures /run/current-system ./result || true
    elif command -v nvd &>/dev/null; then
        log_info "Showing diff (nvd)"
        nvd diff /run/current-system ./result || true
    else
        log_warn "No diff tool found"
    fi
}

rollback_system() {
    local previous_gen
    previous_gen=$(sudo nix-env --list-generations -p /nix/var/nix/profiles/system | tail -n 2 | head -n 1 | awk '{print $1}' || true)
    if [[ -n "$previous_gen" ]]; then
        log_warn "Rolling back to generation $previous_gen"
        sudo nixos-rebuild switch --rollback || log_error "Rollback failed"
    else
        log_warn "No previous generation found to rollback"
    fi
}

lint_configuration() {
    log_info "Linting configuration..."
    if command -v alejandra &>/dev/null; then
        alejandra "$FLAKE_DIR" || return 1
    else
        nix flake check --impure "$FLAKE_DIR" || return 1
    fi
}

update_flake() {
    log_info "Updating flake inputs..."
    cd "$FLAKE_DIR" || return 1
    nix flake update
    git add flake.lock
    git commit -m "Update flake.lock" || log_warn "No changes to commit"
}

check_config() {
    local machine=$1
    if [[ -n "$machine" ]]; then
        log_info "Checking $machine..."
        nix flake check "${FLAKE_DIR}#nixosConfigurations.${machine}" || return 1
    else
        log_info "Checking all configurations..."
        nix flake check "$FLAKE_DIR" || return 1
    fi
}

build_only() {
    local machine=$1
    log_info "Building only (no switch) for $machine"
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] $(quoted_cmd nixos-rebuild build --flake "${FLAKE_DIR}#${machine}")"
    else
        nixos-rebuild build --flake "${FLAKE_DIR}#${machine}"
    fi
}

# ─── Interactive Menu ─────────────────────────────────────────────
show_menu() {
    echo "NixOS Multi-Machine Deployment Tool"
    echo "==================================="
    echo "1) Deploy to local machine"
    echo "2) Deploy to remote machine"
    echo "3) Deploy to all machines"
    echo "4) Update flake inputs"
    echo "5) Check configuration"
    echo "6) Build only (no switch)"
    echo "7) Show configuration diff"
    echo "8) Exit"
}

interactive_menu() {
    while true; do
        show_menu
        read -rp "Select option: " choice
        case $choice in
            1)
                read -rp "Machine (default: $(hostname)): " machine
                machine="${machine:-$(hostname)}"
                deploy_machine "$machine"
                ;;
            2)
                read -rp "Machine: " machine
                read -rp "Target host (user@host): " target
                read -rp "Build host (optional): " build
                deploy_machine "$machine" "$target" "$build"
                ;;
            3)
                for machine in "${MACHINES[@]}"; do
                    read -rp "Deploy to $machine? (y/n): " confirm
                    if [[ $confirm == "y" ]]; then
                        deploy_machine "$machine"
                    fi
                done
                ;;
            4) update_flake ;;
            5)
                read -rp "Machine (empty=all): " machine
                check_config "$machine"
                ;;
            6)
                read -rp "Machine: " machine
                build_only "$machine"
                ;;
            7)
                read -rp "Machine: " machine
                show_diff "$machine"
                ;;
            8) log_info "Exiting..."; exit 0 ;;
            *) log_error "Invalid option" ;;
        esac
        echo
        read -rp "Press Enter to continue..."
    done
}

# ─── CLI Handling ────────────────────────────────────────────────
case "${1:-menu}" in
    deploy)
        shift
        if [[ -z "${1:-}" ]]; then
            log_error "Machine name required for deploy command"
            exit 1
        fi
        machine="$1"
        shift
        deploy_machine "$machine" "$@"
        ;;
    update) update_flake ;;
    check) check_config "${2:-}" ;;
    build) build_only "${2:?Machine name required}" ;;
    diff) show_diff "${2:?Machine name required}" ;;
    menu|"") interactive_menu ;;
    *) log_error "Unknown command: $1"; exit 1 ;;
esac
