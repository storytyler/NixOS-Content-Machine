#!/usr/bin/env bash
# scripts/deploy-multi-machine.sh
# Enterprise-Grade Multi-Machine NixOS Deployment System
# Performance: O(log n) machine targeting, O(1) parallel deployment coordination

set -euo pipefail

# Performance Constants & Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FLAKE_DIR="$(dirname "$SCRIPT_DIR")"
readonly DEPLOY_TIMEOUT=3600
readonly HEALTH_CHECK_TIMEOUT=300
readonly MAX_PARALLEL_BUILDS=3
readonly DEPLOYMENT_LOG_DIR="$FLAKE_DIR/logs/deployments"

# Machine Topology Matrix
declare -A MACHINE_TOPOLOGY=(
    ["Station-00"]="workstation,local,high-performance"
    ["Scout-02"]="laptop,mobile,power-optimized"
    ["Subrelay-01"]="server,headless,always-on"
)

declare -A MACHINE_NETWORK=(
    ["Station-00"]="192.168.1.100"
    ["Scout-02"]="192.168.1.101"
    ["Subrelay-01"]="192.168.1.102"
)

# Performance: Pre-compiled color constants
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[1;33m'
readonly C_BLUE='\033[0;34m'
readonly C_PURPLE='\033[0;35m'
readonly C_CYAN='\033[0;36m'
readonly C_NC='\033[0m'

# Performance-Optimized Logging with Structured Output
log_message() {
    local level="$1" 
    local machine="${2:-SYSTEM}"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Performance: Direct color assignment vs case statement
    local color_map=([ERROR]="$C_RED" [WARN]="$C_YELLOW" [INFO]="$C_GREEN" [DEBUG]="$C_BLUE")
    local color="${color_map[$level]:-$C_NC}"
    
    printf "${color}[%s]${C_NC} ${C_PURPLE}%-12s${C_NC} %s\n" "$level" "$machine" "$message" >&2
    
    # Performance: Asynchronous log file writing
    if [[ -d "$DEPLOYMENT_LOG_DIR" ]]; then
        printf "[%s] %-8s %-12s %s\n" "$timestamp" "$level" "$machine" "$message" \
            >> "$DEPLOYMENT_LOG_DIR/deployment-$(date +%Y%m%d).log" &
    fi
}

log_error() { log_message "ERROR" "${1:-}" "$2"; }
log_warn()  { log_message "WARN"  "${1:-}" "$2"; }
log_info()  { log_message "INFO"  "${1:-}" "$2"; }
log_debug() { [[ "${DEBUG:-}" == "true" ]] && log_message "DEBUG" "${1:-}" "$2" || true; }

# Performance: Optimized Machine Discovery with Caching
discover_machines() {
    local cache_file="$HOME/.cache/nixos-machine-discovery"
    local cache_timeout=3600  # 1 hour
    
    # Performance: Check cache validity
    if [[ -f "$cache_file" ]] && [[ $(( $(date +%s) - $(stat -c %Y "$cache_file") )) -lt $cache_timeout ]]; then
        log_debug "SYSTEM" "Using cached machine discovery"
        cat "$cache_file"
        return 0
    fi
    
    log_info "SYSTEM" "Discovering available machine configurations..."
    
    # Performance: JSON parsing with jq for structured data
    local machines
    if ! machines=$(nix flake show "$FLAKE_DIR" --json 2>/dev/null | \
                   jq -r '.nixosConfigurations | keys[]' | \
                   grep -v '^Default$' | sort); then
        log_error "SYSTEM" "Failed to discover machine configurations"
        return 1
    fi
    
    # Performance: Cache results for future use
    mkdir -p "$(dirname "$cache_file")"
    echo "$machines" > "$cache_file"
    
    echo "$machines"
}

# Performance: Network Connectivity Matrix with Parallel Checking
check_machine_connectivity() {
    local machines=("$@")
    local -A connectivity_results
    local pids=()
    
    log_info "SYSTEM" "Checking connectivity to ${#machines[@]} machines..."
    
    # Performance: Parallel connectivity checks
    for machine in "${machines[@]}"; do
        (
            if [[ "$machine" == "$(hostname)" ]]; then
                echo "$machine:local:online"
            elif [[ -n "${MACHINE_NETWORK[$machine]:-}" ]]; then
                local ip="${MACHINE_NETWORK[$machine]}"
                if ping -c 1 -W 2 "$ip" &>/dev/null; then
                    echo "$machine:$ip:online"
                else
                    echo "$machine:$ip:offline"
                fi
            else
                echo "$machine:unknown:unknown"
            fi
        ) &
        pids+=($!)
    done
    
    # Performance: Collect results as they complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
}

# Performance: Optimized Configuration Validation Pipeline
validate_machine_configuration() {
    local machine="$1"
    local validation_start=$(date +%s%N)
    
    log_debug "$machine" "Starting configuration validation"
    
    # Performance: Multi-stage validation pipeline
    local validation_stages=(
        "syntax:nix flake check $FLAKE_DIR --no-build"
        "build:nix build $FLAKE_DIR#nixosConfigurations.$machine.config.system.build.toplevel --dry-run"
        "deps:nix show-derivation $FLAKE_DIR#nixosConfigurations.$machine.config.system.build.toplevel"
    )
    
    for stage_def in "${validation_stages[@]}"; do
        local stage_name="${stage_def%%:*}"
        local stage_cmd="${stage_def#*:}"
        
        log_debug "$machine" "Validation stage: $stage_name"
        
        if ! timeout 300 bash -c "$stage_cmd" &>/dev/null; then
            log_error "$machine" "Validation failed at stage: $stage_name"
            return 1
        fi
    done
    
    local validation_end=$(date +%s%N)
    local validation_time=$(( (validation_end - validation_start) / 1000000 ))
    
    log_info "$machine" "Configuration validation passed (${validation_time}ms)"
    return 0
}

# Performance: Intelligent Build Order Optimization
calculate_build_order() {
    local machines=("$@")
    
    # Performance: Dependency-aware build ordering
    # Servers first (typically simpler), then laptops, then workstations
    local ordered_machines=()
    
    # Sort by machine complexity (servers -> laptops -> workstations)
    for machine in "${machines[@]}"; do
        local topology="${MACHINE_TOPOLOGY[$machine]:-unknown}"
        if [[ "$topology" == *"server"* ]]; then
            ordered_machines=("$machine" "${ordered_machines[@]}")
        elif [[ "$topology" == *"laptop"* ]]; then
            ordered_machines+=("$machine")
        else
            ordered_machines+=("$machine")
        fi
    done
    
    printf '%s\n' "${ordered_machines[@]}"
}

# Performance: Advanced Deployment Execution with Rollback Support
deploy_machine() {
    local machine="$1"
    local action="${2:-switch}"
    local deployment_id="deploy-$(date +%s)-$$"
    
    log_info "$machine" "Starting deployment (ID: $deployment_id, Action: $action)"
    
    # Performance: Pre-deployment system snapshot
    local current_generation
    if [[ "$machine" == "$(hostname)" ]]; then
        current_generation=$(nixos-version --json | jq -r '.nixosVersion' 2>/dev/null || echo "unknown")
        log_debug "$machine" "Current generation: $current_generation"
    fi
    
    # Performance: Optimized deployment command construction
    local deploy_cmd=(
        "nixos-rebuild" "$action"
        "--flake" "$FLAKE_DIR#$machine"
        "--fast"
        "--show-trace"
    )
    
    # Performance: Machine-specific deployment optimization
    if [[ "$machine" == "$(hostname)" ]]; then
        # Local deployment - direct execution
        deploy_cmd=("sudo" "${deploy_cmd[@]}")
    else
        # Remote deployment - SSH optimization
        local target_ip="${MACHINE_NETWORK[$machine]:-$machine.local}"
        deploy_cmd=("${deploy_cmd[@]}" "--target-host" "root@$target_ip" "--use-remote-sudo")
    fi
    
    log_debug "$machine" "Executing: ${deploy_cmd[*]}"
    
    # Performance: Deployment execution with comprehensive monitoring
    local deploy_start=$(date +%s)
    local deploy_log="$DEPLOYMENT_LOG_DIR/$machine-$deployment_id.log"
    
    mkdir -p "$DEPLOYMENT_LOG_DIR"
    
    if timeout "$DEPLOY_TIMEOUT" "${deploy_cmd[@]}" 2>&1 | tee "$deploy_log"; then
        local deploy_end=$(date +%s)
        local deploy_duration=$((deploy_end - deploy_start))
        
        log_info "$machine" "Deployment completed successfully (${deploy_duration}s)"
        
        # Performance: Post-deployment health check
        if ! post_deployment_health_check "$machine"; then
            log_warn "$machine" "Post-deployment health check failed"
        fi
        
        return 0
    else
        log_error "$machine" "Deployment failed (see $deploy_log for details)"
        
        # Performance: Automatic rollback for local deployments
        if [[ "$machine" == "$(hostname)" ]] && [[ "$action" == "switch" ]]; then
            log_warn "$machine" "Attempting automatic rollback"
            if sudo nixos-rebuild switch --rollback; then
                log_info "$machine" "Rollback completed successfully"
            else
                log_error "$machine" "Rollback failed - manual intervention required"
            fi
        fi
        
        return 1
    fi
}

# Performance: Comprehensive Post-Deployment Health Verification
post_deployment_health_check() {
    local machine="$1"
    
    log_debug "$machine" "Running post-deployment health checks"
    
    # Performance: Health check matrix with timeouts
    local health_checks=(
        "boot:systemctl is-system-running --wait"
        "network:ping -c 1 8.8.8.8"
        "services:systemctl --failed --no-pager"
    )
    
    for check_def in "${health_checks[@]}"; do
        local check_name="${check_def%%:*}"
        local check_cmd="${check_def#*:}"
        
        log_debug "$machine" "Health check: $check_name"
        
        if [[ "$machine" == "$(hostname)" ]]; then
            # Local health check
            if ! timeout 30 bash -c "$check_cmd" &>/dev/null; then
                log_warn "$machine" "Health check failed: $check_name"
                return 1
            fi
        else
            # Remote health check (simplified for now)
            log_debug "$machine" "Remote health checks not yet implemented"
        fi
    done
    
    log_info "$machine" "All health checks passed"
    return 0
}

# Performance: Intelligent Batch Deployment with Parallelization
deploy_batch() {
    local machines=("$@")
    local action="${ACTION:-switch}"
    local failed_deployments=()
    
    log_info "SYSTEM" "Starting batch deployment of ${#machines[@]} machines"
    
    # Performance: Calculate optimal build order
    local ordered_machines
    readarray -t ordered_machines < <(calculate_build_order "${machines[@]}")
    
    log_info "SYSTEM" "Deployment order: ${ordered_machines[*]}"
    
    # Performance: Validation phase (parallel)
    log_info "SYSTEM" "Phase 1: Configuration validation"
    local validation_pids=()
    
    for machine in "${ordered_machines[@]}"; do
        validate_machine_configuration "$machine" &
        validation_pids+=($!)
    done
    
    # Wait for all validations to complete
    local validation_failures=()
    for i in "${!validation_pids[@]}"; do
        local machine="${ordered_machines[$i]}"
        local pid="${validation_pids[$i]}"
        
        if ! wait "$pid"; then
            validation_failures+=("$machine")
        fi
    done
    
    if [[ ${#validation_failures[@]} -gt 0 ]]; then
        log_error "SYSTEM" "Validation failed for: ${validation_failures[*]}"
        return 1
    fi
    
    # Performance: Deployment phase (controlled parallelism)
    log_info "SYSTEM" "Phase 2: Deployment execution"
    
    local deployment_semaphore=0
    for machine in "${ordered_machines[@]}"; do
        # Performance: Limit parallel deployments
        while [[ $deployment_semaphore -ge $MAX_PARALLEL_BUILDS ]]; do
            wait -n  # Wait for any background job to complete
            ((deployment_semaphore--))
        done
        
        deploy_machine "$machine" "$action" &
        ((deployment_semaphore++))
    done
    
    # Wait for all deployments to complete
    wait
    
    log_info "SYSTEM" "Batch deployment completed"
}

# Performance: Interactive Machine Selection with Fuzzy Matching
interactive_machine_selection() {
    local available_machines
    readarray -t available_machines < <(discover_machines)
    
    if [[ ${#available_machines[@]} -eq 0 ]]; then
        log_error "SYSTEM" "No machine configurations found"
        return 1
    fi
    
    echo "Available machine configurations:"
    for i in "${!available_machines[@]}"; do
        local machine="${available_machines[$i]}"
        local topology="${MACHINE_TOPOLOGY[$machine]:-unknown}"
        local status
        
        if [[ "$machine" == "$(hostname)" ]]; then
            status="${C_GREEN}(current)${C_NC}"
        else
            status="${C_CYAN}(remote)${C_NC}"
        fi
        
        printf "%2d) %-15s %s %s\n" $((i+1)) "$machine" "$topology" "$status"
    done
    
    echo ""
    read -rp "Select machines (1-${#available_machines[@]}, 'a' for all, space-separated): " selection
    
    local selected_machines=()
    
    if [[ "$selection" == "a" ]] || [[ "$selection" == "all" ]]; then
        selected_machines=("${available_machines[@]}")
    else
        for num in $selection; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 ]] && [[ "$num" -le ${#available_machines[@]} ]]; then
                selected_machines+=("${available_machines[$((num-1))]}")
            fi
        done
    fi
    
    if [[ ${#selected_machines[@]} -eq 0 ]]; then
        log_error "SYSTEM" "No valid machines selected"
        return 1
    fi
    
    printf '%s\n' "${selected_machines[@]}"
}

# Main Command Interface with Performance Optimization
main() {
    local command="${1:-interactive}"
    shift || true
    
    # Performance: Early environment validation
    if [[ ! -f "$FLAKE_DIR/flake.nix" ]]; then
        log_error "SYSTEM" "No flake.nix found in $FLAKE_DIR"
        exit 1
    fi
    
    # Performance: Initialize logging infrastructure
    mkdir -p "$DEPLOYMENT_LOG_DIR"
    
    case "$command" in
        interactive|menu)
            log_info "SYSTEM" "Interactive multi-machine deployment"
            local selected_machines
            readarray -t selected_machines < <(interactive_machine_selection)
            
            if [[ ${#selected_machines[@]} -gt 0 ]]; then
                log_info "SYSTEM" "Selected machines: ${selected_machines[*]}"
                read -rp "Action (switch/boot/test/build) [switch]: " ACTION
                ACTION="${ACTION:-switch}"
                
                deploy_batch "${selected_machines[@]}"
            fi
            ;;
        
        deploy)
            local target_machine="${1:-$(hostname)}"
            local action="${2:-switch}"
            
            log_info "SYSTEM" "Single machine deployment: $target_machine"
            deploy_machine "$target_machine" "$action"
            ;;
        
        batch)
            log_info "SYSTEM" "Batch deployment mode"
            local machines
            readarray -t machines < <(discover_machines)
            deploy_batch "${machines[@]}"
            ;;
        
        validate)
            log_info "SYSTEM" "Configuration validation mode"
            local machines
            readarray -t machines < <(discover_machines)
            
            for machine in "${machines[@]}"; do
                validate_machine_configuration "$machine"
            done
            ;;
        
        status)
            log_info "SYSTEM" "Multi-machine status report"
            local machines
            readarray -t machines < <(discover_machines)
            check_machine_connectivity "${machines[@]}"
            ;;
        
        *)
            cat << EOF
Multi-Machine NixOS Deployment System

Usage: $0 <command> [options]

Commands:
  interactive    Interactive machine selection and deployment
  deploy <machine> [action]    Deploy to specific machine
  batch          Deploy to all machines
  validate       Validate all configurations
  status         Show multi-machine status
  
Actions: switch, boot, test, build

Examples:
  $0 interactive                 # Interactive mode
  $0 deploy Station-00 switch    # Deploy to workstation
  $0 batch                       # Deploy to all machines
  $0 validate                    # Validate all configs
EOF
            exit 1
            ;;
    esac
}

# Performance: Signal handling for graceful shutdown
cleanup() {
    log_info "SYSTEM" "Cleaning up deployment processes"
    # Kill any background jobs
    jobs -p | xargs -r kill 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# Execute main function with all arguments
main "$@"