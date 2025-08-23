{...}: {
  perSystem = {pkgs, ...}: {
    devShells = {
      # Enhanced default development shell for configuration work ONLY
      default = pkgs.mkShell {
        name = "nixos-config-development";
        buildInputs = with pkgs; [
          git gh alejandra
          nixd deadnix statix nvd
          nix-update nixpkgs-review npins
          nix-du nix-tree
        ];
        shellHook = ''
          echo "NixOS Configuration Development Environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Use 'nix develop' for NixOS config work"
          echo "Use 'nix flake init -t .#template-name' for language projects"
        '';
        NIX_CONFIG = "experimental-features = nix-command flakes";
      };
    };
  };
}
