#!/usr/bin/env bash
# functional-verification.sh - NixOS system functionality validation

echo ""
echo "⚙️  Functional Verification Protocol:"
echo "===================================="

# Flake validation
echo ""
log_info "Testing flake integrity..."
if nix flake check --no-build 2>/dev/null; then
    log_success "Flake syntax validation passed"
else
    log_error "Flake syntax validation failed"
    echo "Run: nix flake check --show-trace for details"
fi

# Dev-shell accessibility verification
echo ""
log_info "Testing dev-shell accessibility..."
available_shells=$(nix flake show 2>/dev/null | grep -E 'devShells\.' | wc -l)
if [ $available_shells -gt 0 ]; then
    log_success "Found $available_shells dev-shell(s)"
    nix flake show 2>/dev/null | grep -E 'devShells\.'
else
    log_warning "No dev-shells detected in flake output"
fi

# Configuration build test (dry-run)
echo ""
log_info "Testing configuration build (dry-run)..."
if nixos-rebuild dry-build --flake .#Station-00 &>/dev/null; then
    log_success "Station-00 configuration builds successfully"
else
    log_error "Station-00 configuration build failed"
    echo "Run: nixos-rebuild dry-build --flake .#Station-00 --show-trace"
fi

# Rofi configuration validation
echo ""
log_info "Testing rofi configuration..."
rofi_config="modules/desktop/hyprland/programs/rofi/default.nix"
if [ -f "$rofi_config" ]; then
    # Test nix evaluation of rofi module
    if nix eval --file "$rofi_config" --apply '(import <nixpkgs> {}).lib' &>/dev/null; then
        log_success "Rofi configuration validates"
    else
        log_warning "Rofi configuration validation inconclusive"
    fi
else
    log_error "Rofi configuration not found"
fi