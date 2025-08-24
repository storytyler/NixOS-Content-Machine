#!/usr/bin/env bash
# performance-benchmark.sh - Quantitative optimization measurement

echo ""
echo "📊 Performance Benchmarking:"
echo "==========================="

# Function to measure build time
measure_build_time() {
    local start_time=$(date +%s)
    nix build --dry-run .#Station-00 &>/dev/null
    local end_time=$(date +%s)
    echo $((end_time - start_time))
}

# Function to measure evaluation memory
measure_memory_usage() {
    local max_memory=0
    while IFS= read -r line; do
        if [[ $line =~ resident\ set\ size:\ ([0-9]+) ]]; then
            local memory=${BASH_REMATCH[1]}
            if (( memory > max_memory )); then
                max_memory=$memory
            fi
        fi
    done < <(nix eval .#Station-00 --show-stats 2>&1)
    echo $max_memory
}

# Build time measurement
echo ""
log_info "Measuring build evaluation time..."
build_time=$(measure_build_time)
log_info "Build evaluation time: ${build_time}s"

# Storage usage analysis  
echo ""
log_info "Analyzing storage utilization..."
if command -v nix-tree &>/dev/null; then
    store_size=$(nix path-info --closure-size .#Station-00 2>/dev/null | awk '{print $NF}')
    log_info "Configuration closure size: $store_size"
else
    log_warning "nix-tree not available for storage analysis"
fi

# Flake.lock complexity measurement
echo ""
log_info "Measuring flake dependency complexity..."
lock_inputs=$(jq '.nodes | keys | length' flake.lock 2>/dev/null || echo "unknown")
log_info "Flake input nodes: $lock_inputs"

# File count metrics
echo ""
log_info "Configuration file statistics:"
total_nix_files=$(find . -name "*.nix" -type f | wc -l)
total_rasi_files=$(find . -name "*.rasi" -type f | wc -l)
total_script_files=$(find . -name "*.sh" -type f | wc -l)

echo "  📄 Nix files: $total_nix_files"
echo "  🎨 Rasi files: $total_rasi_files"  
echo "  📜 Shell scripts: $total_script_files"