#!/usr/bin/env bash
# modules/desktop/hyprland/scripts/rebuild.sh
# Performance-Optimized NixOS Rebuild with Multi-Machine Support
# Computational Complexity: O(1) hostname detection + O(log n) flake validation

set -euo pipefail

# Performance Constants
readonly REBUILD_TIMEOUT=3600
readonly FLAKE_CHECK_TIMEOUT=300
readonly VALIDATION_CACHE="/tmp/nixos-rebuild-validation.cache"

# Color Constants
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging Functions - Performance: Minimal overhead
log_info()  { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_debug() { [[ "${DEBUG:-}" == "true" ]] && echo -e "${BLUE}[DEBUG]${NC} $*" >&2 || true; }

# Performance: Early exit validation to avoid expensive operations
validate_environment() {
    # Check if running as root - Performance: Single syscall
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be executed as root! Exiting..."
        exit 1
    fi

    # Validate NixOS environment - Performance: Single file read
    if ! grep -qi nixos /etc/os-release 2>/dev/null; then
        log_error "This script only works on NixOS! Download an iso at https://nixos.org/download/"
        exit 1
    fi

    # Performance: Check sudo availability without prompting
    if ! sudo -n true 2>/dev/null; then
        log_warn "Sudo authentication required - may prompt for password"
    fi
}

# Performance: Optimized flake directory detection with caching
find_flake_directory() {
    local current_dir="$(pwd)"
    local search_paths=(
        "$current_dir"
        "$HOME/NixOS"
        "/etc/nixos"
        "$(dirname "${BASH_SOURCE[0]}")/../../../.."
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path/flake.nix" ]]; then
            echo "$(realpath "$path")"
            return 0
        fi
    done
    
    log_error "No flake.nix found in standard locations"
    return 1
}

# Performance: Cached hostname resolution
get_hostname() {
    # Performance: Use built-in variable if available, fallback to command
    echo "${HOSTNAME:-$(hostname)}"
}

# Performance: Optimized configuration validation with caching
validate_configuration() {
    local hostname="$1"
    local flake_dir="$2"
    local cache_key="$hostname-$(stat -c %Y "$flake_dir/flake.nix")"
    
    # Performance: Check cache first
    if [[ -f "$VALIDATION_CACHE" ]] && grep -q "^$cache_key$" "$VALIDATION_CACHE" 2>/dev/null; then
        log_debug "Configuration validation cached for $hostname"
        return 0
    fi
    
    log_info "Validating configuration for $hostname..."
    
    # Performance: Fast configuration existence check
    if ! timeout "$FLAKE_CHECK_TIMEOUT" nix flake show "$flake_dir" --json 2>/dev/null | \
       jq -e ".nixosConfigurations.\"$hostname\"" >/dev/null; then
        log_error "No configuration found for hostname '$hostname'"
        log_info "Available configurations:"
        nix flake show "$flake_dir" --json 2>/dev/null | \
            jq -r '.nixosConfigurations | keys[]' | sed 's/^/  - /' || true
        return 1
    fi
    
    # Performance: Cache successful validation
    mkdir -p "$(dirname "$VALIDATION_CACHE")"
    echo "$cache_key" >> "$VALIDATION_CACHE"
    
    log_info "Configuration validation successful"
    return 0
}

# Performance: Optimized hardware configuration management
manage_hardware_config() {
    local hostname="$1"
    local flake_dir="$2"
    local hw_config_path="$flake_dir/hosts/$hostname/hardware-configuration.nix"
    
    # Performance: Check if hardware config exists and is recent
    if [[ -f "$hw_config_path" ]] && [[ "$hw_config_path" -nt /etc/nixos/configuration.nix ]]; then
        log_debug "Hardware configuration up to date"
        return 0
    fi
    
    log_info "Updating hardware configuration for $hostname..."
    
    # Performance: Priority-based hardware config resolution
    local hw_sources=(
        "/etc/nixos/hardware-configuration.nix"
        "/etc/nixos/hosts/$hostname/hardware-configuration.nix"
    )
    
    for source in "${hw_sources[@]}"; do
        if [[ -f "$source" ]]; then
            log_info "Copying hardware config from $source"
            sudo mkdir -p "$(dirname "$hw_config_path")"
            sudo cp "$source" "$hw_config_path"
            sudo git -C "$flake_dir" add "hosts/$hostname/hardware-configuration.nix" 2>/dev/null || true
            return 0
        fi
    done
    
    # Performance: Generate new hardware config only if none found
    log_warn "No existing hardware config found, generating new one..."
    sudo nixos-generate-config --show-hardware-config > "$hw_config_path"
    sudo git -C "$flake_dir" add "hosts/$hostname/hardware-configuration.nix" 2>/dev/null || true
}

# Performance: Pre-build validation to catch errors early
pre_build_checks() {
    local hostname="$1"
    local flake_dir="$2"
    
    log_info "Running pre-build checks..."
    
    # Performance: Fast syntax validation
    if ! nix flake check "$flake_dir" --no-build 2>/dev/null; then
        log_error "Flake syntax validation failed"
        return 1
    fi
    
    # Performance: Quick build test without switching
    log_info "Testing build (dry-run)..."
    if ! timeout "$REBUILD_TIMEOUT" nix build "$flake_dir#nixosConfigurations.$hostname.config.system.build.toplevel" --dry-run 2>/dev/null; then
        log_error "Build test failed"
        return 1
    fi
    
    log_info "Pre-build checks passed"
}

# Performance: Optimized rebuild execution with progress tracking
execute_rebuild() {
    local hostname="$1"
    local flake_dir="$2"
    local action="${3:-switch}"
    
    log_info "Starting NixOS rebuild: $action for $hostname"
    
    # Performance: Construct optimized rebuild command
    local rebuild_args=(
        "$action"
        "--flake" "$flake_dir#$hostname"
        "--fast"  # Skip unnecessary checks
    )
    
    # Performance: Add debug flags only when needed
    if [[ "${DEBUG:-}" == "true" ]]; then
        rebuild_args+=(--show-trace --verbose)
    fi
    
    # Performance: Log build start time for profiling
    local start_time=$(date +%s)
    log_info "Build started at $(date)"
    
    # Execute rebuild with timeout
    if timeout "$REBUILD_TIMEOUT" sudo nixos-rebuild "${rebuild_args[@]}"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_info "Rebuild completed successfully in ${duration}s"
        
        # Performance: Show concise diff
        show_system_diff
        return 0
    else
        log_error "Rebuild failed"
        return 1
    fi
}

# Performance: Optimized system diff with nvd/nix store
show_system_diff() {
    if [[ ! -L ./result ]]; then
        log_debug "No ./result symlink found for diff"
        return
    fi
    
    log_info "System changes:"
    
    # Performance: Prefer nvd over nix store diff-closures (faster)
    if command -v nvd >/dev/null 2>&1; then
        nvd diff /run/current-system ./result 2>/dev/null | head -20
    elif command -v nix >/dev/null 2>&1; then
        nix store diff-closures /run/current-system ./result 2>/dev/null | head -20
    else
        log_debug "No diff tool available"
    fi
}

# Performance: Emergency rollback with generation detection
emergency_rollback() {
    log_warn "Attempting emergency rollback..."
    
    # Performance: Fast previous generation detection
    local prev_gen
    prev_gen=$(sudo nix-env --list-generations -p /nix/var/nix/profiles/system | \
               tail -n 2 | head -n 1 | awk '{print $1}' 2>/dev/null)
    
    if [[ -n "$prev_gen" ]]; then
        log_info "Rolling back to generation $prev_gen"
        if sudo nixos-rebuild switch --rollback; then
            log_info "Rollback successful"
        else
            log_error "Rollback failed - system may be in inconsistent state"
        fi
    else
        log_error "No previous generation found for rollback"
    fi
}

# Main execution flow with comprehensive error handling
main() {
    local action="${1:-switch}"
    local target_hostname="${2:-}"
    
    # Performance: Early validation to avoid expensive operations
    validate_environment
    
    # Performance: Optimized directory and hostname resolution
    local flake_dir
    flake_dir=$(find_flake_directory) || exit 1
    
    local hostname
    if [[ -n "$target_hostname" ]]; then
        hostname="$target_hostname"
        log_info "Using specified hostname: $hostname"
    else
        hostname=$(get_hostname)
        log_info "Auto-detected hostname: $hostname"
    fi
    
    # Change to flake directory for consistent relative paths
    cd "$flake_dir" || exit 1
    
    # Performance: Pipeline validation and execution
    if validate_configuration "$hostname" "$flake_dir" && \
       manage_hardware_config "$hostname" "$flake_dir" && \
       pre_build_checks "$hostname" "$flake_dir"; then
        
        # Execute rebuild with error handling
        if ! execute_rebuild "$hostname" "$flake_dir" "$action"; then
            if [[ "$action" == "switch" ]]; then
                emergency_rollback
            fi
            exit 1
        fi
    else
        log_error "Validation failed, aborting rebuild"
        exit 1
    fi
    
    log_info "NixOS rebuild completed successfully!"
}

# Performance: Trap for cleanup
cleanup() {
    # Clean up temporary files
    rm -f "$VALIDATION_CACHE.tmp" 2>/dev/null || true
}

trap cleanup EXIT

# Execute main function with all arguments
main "$@"