{
  description = "Multi-machine NixOS configuration with modular architecture";

  inputs = {
    # Core inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Flake utilities for better organization
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Additional tools
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:Sly-Harvey/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    betterfox = {
      url = "github:yokoffing/Betterfox";
      flake = false;
    };

    thunderbird-catppuccin = {
      url = "github:catppuccin/thunderbird";
      flake = false;
    };

    zen-browser = {
      url = "github:maximoffua/zen-browser.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Development tools
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Automated quality checks for configuration files
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # High-performance nix-shell replacement with caching
    nix-direnv = {
      url = "github:nix-community/nix-direnv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Advanced Nix language server for development
    nixd = {
      url = "github:nix-community/nixd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      imports = [
        ./flake-parts/dev-shells.nix
        ./flake-parts/machines.nix
        ./flake-parts/packages.nix
      ];

      # Shared configuration across all flake parts
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        formatter = pkgs.alejandra;

        # System-specific packages can be defined here
        packages = {
          # Custom packages if needed
        };
      };

      flake = {
        # Templates for development environments
        templates = import ./dev-shells;

        # Shared modules available to all configurations
        nixosModules = {
          common = import ./modules/common;
          desktop = import ./modules/desktop;
          server = import ./modules/server;
          laptop = import ./modules/laptop;
        };
      };
    };
}
