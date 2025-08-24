#!/usr/bin/env bash
# master-verification.sh - Complete optimization validation

echo "🎯 NixOS Configuration Optimization Verification"
echo "==============================================="

# Make scripts executable
chmod +x verification-audit.sh functional-verification.sh performance-benchmark.sh

# Execute verification phases
echo "Phase 1: Directory Structure Validation"
./verification-audit.sh

echo -e "\nPhase 2: Functional Verification"  
./functional-verification.sh

echo -e "\nPhase 3: Performance Benchmarking"
./performance-benchmark.sh

echo -e "\nPhase 4: Nix Expression Validation"
nix eval --file validation-expressions.nix validationReport --json | jq '.'

echo -e "\n🎯 Verification Complete!"
echo "Review output above for optimization status"