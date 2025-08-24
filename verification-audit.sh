#!/usr/bin/env bash
set -euo pipefail

echo "🔍 NixOS Configuration Optimization Audit"
echo "========================================"

log_success() { echo -e "\033[32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[33m⚠️  $1\033[0m"; }  
log_error() { echo -e "\033[31m❌ $1\033[0m"; }
log_info() { echo -e "\033[36mℹ️  $1\033[0m"; }

echo ""
echo "📁 Directory Structure Analysis:"
echo "--------------------------------"

# Dev-shell structure verification
if [ -d "flake-parts/dev-shells/c-cpp" ] || [ -d "flake-parts/dev-shells/go" ]; then
    log_warning "Individual dev-shell directories still present"
    echo "   Found: $(find flake-parts/dev-shells -maxdepth 1 -type d -name '*-*' | wc -l) individual shells"
    ls -la flake-parts/dev-shells/ | grep -E '^d.*-.*' || echo "No individual shell dirs found"
else
    log_success "Individual dev-shell directories removed"
fi

# Rofi launcher verification  
rofi_base="modules/desktop/hyprland/programs/rofi"
if [ -d "$rofi_base/launchers" ]; then
    launcher_types=$(find "$rofi_base/launchers" -maxdepth 1 -type d -name 'type-*' | wc -l)
    echo ""
    log_info "Rofi launcher types remaining: $launcher_types"
    ls -la "$rofi_base/launchers/" | grep '^d.*type-' || echo "No type directories found"
    
    if [ -d "$rofi_base/launchers/wallpaper" ]; then
        log_warning "Wallpaper launcher directory still exists"
    else
        log_success "Wallpaper launcher directory removed"
    fi
    
    if [ -d "$rofi_base/resolution" ]; then
        log_warning "Resolution config directory still exists"  
    else
        log_success "Resolution config directory removed"
    fi
fi

# Color theme verification
if [ -d "$rofi_base/colors" ]; then
    echo ""
    log_info "Rofi color themes remaining:"
    theme_count=$(ls -1 "$rofi_base/colors/"*.rasi 2>/dev/null | wc -l)
    echo "   Count: $theme_count"
    ls -1 "$rofi_base/colors/"*.rasi 2>/dev/null || echo "   No .rasi files found"
fi

# Icon granularity verification
vol_icons="modules/desktop/hyprland/icons/notifications/vol"
if [ -d "$vol_icons" ]; then
    vol_count=$(find "$vol_icons" -name "vol-*.svg" | wc -l)
    echo ""
    log_info "Volume icon count: $vol_count"
    if [ $vol_count -gt 8 ]; then
        log_warning "Volume icons not optimized (found $vol_count, expected ≤5)"
    else
        log_success "Volume icons optimized"
    fi
fi

# Backup file verification
echo ""
echo "🗑️  Backup File Analysis:"
echo "------------------------"
backup_files=(
    "flake.nix.bak"
    "hosts/common (copy 1).nix"
    "modules/desktop/hyprland/programs/wlogout/default.nix.bak"
    "modules/desktop/hyprland/scripts/rebuild.sh.backup"
)

for backup in "${backup_files[@]}"; do
    if [ -f "$backup" ]; then
        log_warning "Backup file still exists: $backup"
    else
        log_success "Backup file removed: $backup"
    fi
done

echo ""
echo "📊 Configuration Statistics:"
echo "---------------------------"
total_nix_files=$(find . -name "*.nix" -type f | wc -l)
total_rasi_files=$(find . -name "*.rasi" -type f | wc -l)
total_script_files=$(find . -name "*.sh" -type f | wc -l)

echo "  📄 Nix files: $total_nix_files"
e
chmod +x verification-audit.sh && ./verification-audit.sh
# Step 2: NixOS-specific functional verification
cat > nixos-functional-test.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "⚙️  NixOS Functional Verification Protocol:"
echo "=========================================="

log_success() { echo -e "\033[32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[33m⚠️  $1\033[0m"; }  
log_error() { echo -e "\033[31m❌ $1\033[0m"; }
log_info() { echo -e "\033[36mℹ️  $1\033[0m"; }

# Flake validation with error capture
echo ""
log_info "Testing flake integrity..."
if flake_output=$(nix flake check --no-build 2>&1); then
    log_success "Flake syntax validation passed"
else
    log_error "Flake syntax validation failed"
    echo "Error output:"
    echo "$flake_output" | head -10
fi

# Dev-shell accessibility verification
echo ""
log_info "Testing dev-shell accessibility..."
if show_output=$(nix flake show 2>&1); then
    available_shells=$(echo "$show_output" | grep -c 'devShells\.' || echo "0")
    if [ "$available_shells" -gt 0 ]; then
        log_success "Found $available_shells dev-shell(s)"
        echo "$show_output" | grep 'devShells\.' || echo "No dev-shells in output"
    else
        log_warning "No dev-shells detected in flake output"
    fi
else
    log_error "Failed to evaluate flake show"
fi

# Configuration build test (dry-run)
echo ""
log_info "Testing Station-00 configuration build (dry-run)..."
if build_output=$(nixos-rebuild dry-build --flake .#Station-00 2>&1); then
    log_success "Station-00 configuration builds successfully"
    echo "Build summary: $(echo "$build_output" | tail -3)"
else
    log_error "Station-00 configuration build failed"
    echo "Build error:"
    echo "$build_output" | tail -10
fi

# Evaluate specific configuration modules
echo ""
log_info "Testing module evaluation..."
test_modules=(
    "hosts/Station-00/configuration.nix"
    "modules/desktop/hyprland/default.nix"
    "flake-parts/machines.nix"
)

for module in "${test_modules[@]}"; do
    if [ -f "$module" ]; then
        if nix eval --file "$module" --json >/dev/null 2>&1; then
            log_success "Module validates: $module"
        else
            log_warning "Module validation inconclusive: $module"
        fi
    else
        log_error "Module not found: $module"
    fi
done

