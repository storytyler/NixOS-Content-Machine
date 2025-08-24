# flake-parts/dev-shells.nix - Centralized shell management
{
  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    system,
    ...
  }: {
    devShells = {
      # Consolidated shells with shared dependency management
      nix = pkgs.mkShell {
        buildInputs = with pkgs; [
          nil
          nixd
          alejandra
          nixpkgs-fmt
          nix-tree
          nix-diff
          nvd
        ];
      };

      rust = pkgs.mkShell {
        buildInputs = with pkgs; [
          rustc
          cargo
          clippy
          rustfmt
          rust-analyzer
          pkg-config
        ];
      };

      python = pkgs.mkShell {
        buildInputs = with pkgs; [
          python3
          python3Packages.pip
          python3Packages.virtualenv
          ruff
        ];
      };

      shell = pkgs.mkShell {
        buildInputs = with pkgs; [
          shellcheck
          shfmt
          bash-language-server
        ];
      };
    };
  };
}
