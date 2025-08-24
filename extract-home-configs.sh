#!/usr/bin/env bash
# extract-home-configs.sh

find modules -name "default.nix" -exec grep -l "home-manager.sharedModules" {} \; | while read file; do
  dir=$(dirname "$file")
  
  # Extract home config to separate file
  awk '
    /home-manager.sharedModules.*\[/,/\]\];/ {
      if (/\(_:.*{/) inblock=1
      if (inblock && !/home-manager.sharedModules/) print
      if (/}\)/) inblock=0
    }
  ' "$file" > "$dir/home.nix.tmp"
  
  # Clean up if extraction succeeded
  if [ -s "$dir/home.nix.tmp" ]; then
    echo "{config, lib, pkgs, ...}: {" > "$dir/home.nix"
    cat "$dir/home.nix.tmp" | sed 's/^\s*(_:\s*{//' | sed 's/^\s*})/}/' >> "$dir/home.nix"
    rm "$dir/home.nix.tmp"
    echo "Extracted: $dir/home.nix"
  fi
done