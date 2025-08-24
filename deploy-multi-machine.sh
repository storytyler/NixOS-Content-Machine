#!/usr/bin/env bash
# Core multi-machine functions with offline detection

# Logging
log_message() {
    local level="$1"
    local machine="${2:-SYSTEM}"
    local message="$3"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local color_map=([ERROR]='\033[0;31m' [WARN]='\033[1;33m' [INFO]='\033[0;32m' [DEBUG]='\033[0;34m')
    local color="${color_map[$level]:-'\033[0m'}"

    printf "${color}[%s]${C_NC} ${machine}: %s\n" "$level" "$message" >&2

    [[ -d "$DEPLOYMENT_LOG_DIR" ]] && \
        printf "[%s] %-8s %-12s %s\n" "$timestamp" "$level" "$machine" "$message" >> "$DEPLOYMENT_LOG_DIR/deployment-$(date +%Y%m%d).log" &
}

log_error() { log_message "ERROR" "$1" "$2"; }
log_warn()  { log_message "WARN"  "$1" "$2"; }
log_info()  { log_message "INFO"  "$1" "$2"; }
log_debug() { [[ "${DEBUG:-}" == "true" ]] && log_message "DEBUG" "$1" "$2"; }

# Machine discovery
discover_machines() {
    local cache_file="$HOME/.cache/nixos-machine-discovery"
    local cache_timeout=3600

    if [[ -f "$cache_file" ]] && [[ $(( $(date +%s) - $(stat -c %Y "$cache_file") )) -lt $cache_timeout ]]; then
        log_debug "SYSTEM" "Using cached machine discovery"
        cat "$cache_file"
        return 0
    fi

    log_info "SYSTEM" "Discovering machines..."
    local machines
    machines=$(nix flake show "$FLAKE_DIR" --json 2>/dev/null | \
               jq -r '.nixosConfigurations | keys[]' | grep -v '^Default$' | sort) || {
        log_error "SYSTEM" "Failed to discover machines"
        return 1
    }

    mkdir -p "$(dirname "$cache_file")"
    echo "$machines" > "$cache_file"
    echo "$machines"
}

# Check connectivity and skip offline/unknown machines
check_connectivity() {
    local machines=("$@")
    declare -A connectivity=()

    for machine in "${machines[@]}"; do
        if [[ "$machine" == "$(hostname)" ]]; then
            connectivity["$machine"]="online"
        elif [[ -n "${MACHINE_NETWORK[$machine]:-}" ]]; then
            ping -c 1 -W 2 "${MACHINE_NETWORK[$machine]}" &>/dev/null && \
                connectivity["$machine"]="online" || connectivity["$machine"]="offline"
        else
            connectivity["$machine"]="unknown"
        fi
    done

    # Print status
    for m in "${machines[@]}"; do
        log_info "$m" "Connectivity: ${connectivity[$m]}"
    done

    # Return only online machines
    local online_machines=()
    for m in "${machines[@]}"; do
        [[ "${connectivity[$m]}" == "online" ]] && online_machines+=("$m")
    done

    echo "${online_machines[@]}"
}

# Batch deployment with offline skipping
deploy_batch() {
    local machines=("$@")
    local action="${ACTION:-switch}"
    local failed_deployments=()

    # Filter offline machines
    read -ra machines <<< "$(check_connectivity "${machines[@]}")"
    [[ ${#machines[@]} -eq 0 ]] && { log_warn "SYSTEM" "No online machines to deploy"; return 0; }

    log_info "SYSTEM" "Deploying to: ${machines[*]}"

    # Build order
    readarray -t ordered_machines < <(calculate_build_order "${machines[@]}")

    local deployment_semaphore=0
    for machine in "${ordered_machines[@]}"; do
        # Limit parallel builds
        while [[ $deployment_semaphore -ge $MAX_PARALLEL_BUILDS ]]; do
            wait -n
            ((deployment_semaphore--))
        done

        deploy_machine "$machine" "$action" &
        ((deployment_semaphore++))
    done

    wait
    log_info "SYSTEM" "Batch deployment completed"
}
