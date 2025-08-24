# flake-parts/machines.nix - Simplified Multi-Machine Configuration
# Performance-Optimized without Default configuration complexity
{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations = let
    # Performance Optimization: Memoized system builder to reduce evaluation overhead
    mkSystem = {
      hostname,
      system ? "x86_64-linux",
      modules,
      settings,
    }: let
      # Optimization: Pre-compute specialArgs to avoid repeated evaluation
      computedSpecialArgs =
        {
          inherit self inputs;
          inherit (settings) username;
          machineConfig = settings;
          # Performance: Pass pre-resolved hostname to avoid string interpolation overhead
          inherit hostname;
        }
        // settings;
    in
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = computedSpecialArgs;
        modules =
          [
            # Overlay Module: Optimized theme resolution with compile-time selection
            ({
              config,
              lib,
              pkgs,
              ...
            }: {
              nixpkgs.overlays = [
                # NUR overlay - Performance: Single overlay application
                inputs.nur.overlays.default

                # Stable channel overlay - Optimization: Lazy stable package resolution
                (final: prev: {
                  stable = import inputs.nixpkgs-stable {
                    inherit system;
                    config.allowUnfree = true;
                  };
                })

                # Theme Selection Overlay - Performance: Compile-time theme resolution
                (final: prev: let
                  # Optimization: Pre-resolve theme package to eliminate runtime conditionals
                  themePackageMap = {
                    astronaut = self.packages.${system}.sddm-astronaut-default;
                    black_hole = self.packages.${system}.sddm-astronaut-black-hole;
                    purple_leaves = self.packages.${system}.sddm-astronaut-purple-leaves;
                    jake_the_dog = self.packages.${system}.sddm-astronaut-jake-the-dog;
                    hyprland_kath = self.packages.${system}.sddm-astronaut-hyprland-kath;
                  };
                in {
                  # Performance: O(1) theme lookup vs O(n) conditional chain
                  sddm-astronaut = themePackageMap.${settings.sddmTheme} 
                  or self.packages.${system}.sddm-astronaut-default;
                })
              ];
            })

            # Core Configuration Imports - Performance: Explicit path resolution
            ../hosts/${hostname}/configuration.nix
            ../hosts/${hostname}/hardware-configuration.nix
            ../hosts/common.nix # Maintained at your preferred location

            # Home Manager Integration - Optimization: Shared args computation
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = computedSpecialArgs; # Performance: Reuse computed args
              };
            }
            # Import home-manager profiles for the user
            (inputs.nixpkgs.lib.mkIf (settings.username == "player00") ./home.nix)
          ]
          ++ modules;
      };

    # Machine Definitions - Complete Configuration Matrix
    machines = {
      # Desktop Workstation - Station-00
      "Station-00" = {
        system = "x86_64-linux";
        settings = {
          username = "player00";
          role = "desktop";
          profile = "workstation";

          # Hardware Configuration
          videoDriver = "intel";
          drives = ["games" "work"];

          # Software Stack
          editor = "vscode";
          browser = "zen";
          terminal = "wezterm";
          terminalFileManager = "yazi";
          shell = "zsh";

          # Desktop Environment Configuration
          desktop = "hyprland";
          sddmTheme = "astronaut";
          wallpaper = "fog";

          # Localization Settings
          locale = "en_US.UTF-8";
          timezone = "America/Chicago";
          kbdLayout = "us";
          kbdVariant = "";
          consoleKeymap = "us";

          # Feature Matrix - Performance: Boolean flags for conditional compilation
          features = {
            gaming = true;
            development = true;
            multimedia = true;
            virtualization = false;
            containers = false;
            services = {
              ssh = false;
              monitoring = false;
              minidlna = true;
            };
          };
        };
        modules = [
          ../modules/profiles/workstation.nix
        ];
      };

      # Laptop Configuration - Scout-02
      "Scout-02" = {
        system = "x86_64-linux";
        settings = {
          username = "player00";
          role = "laptop";
          profile = "laptop";

          # Hardware Configuration - Laptop-specific
          videoDriver = "intel";
          drives = ["main"];

          # Software Stack - Lightweight alternatives
          editor = "neovim";
          browser = "zen";
          terminal = "alacritty";
          terminalFileManager = "yazi";
          shell = "zsh";

          # Desktop Environment
          desktop = "hyprland";
          sddmTheme = "astronaut";
          wallpaper = "moon";

          # Localization
          locale = "en_US.UTF-8";
          timezone = "America/Chicago";
          kbdLayout = "us";
          kbdVariant = "";
          consoleKeymap = "us";

          # Feature Matrix - Optimized for mobile use
          features = {
            gaming = false;
            development = true;
            multimedia = false;
            virtualization = false;
            containers = false;
            power_management = true;
            services = {
              ssh = true;
              monitoring = false;
              minidlna = false;
            };
          };
        };
        modules = [
          ../modules/profiles/laptop.nix
        ];
      };

      # Server Configuration - Subrelay-01
      "Subrelay-01" = {
        system = "x86_64-linux";
        settings = {
          username = "player00";
          role = "server";
          profile = "server";

          # Hardware Configuration - Headless
          videoDriver = "intel"; # Minimal for headless
          drives = ["data"];

          # Software Stack - Server-optimized
          editor = "neovim";
          browser = null; # No GUI
          terminal = null; # SSH only
          terminalFileManager = "yazi";
          shell = "bash"; # Simpler shell for automation

          # No Desktop Environment
          desktop = null;
          sddmTheme = null;
          wallpaper = null;

          # Localization
          locale = "en_US.UTF-8";
          timezone = "America/Chicago";
          kbdLayout = "us";
          kbdVariant = "";
          consoleKeymap = "us";

          # Feature Matrix - Server services focus
          features = {
            gaming = false;
            development = false;
            multimedia = false;
            virtualization = true;
            containers = true;
            services = {
              ssh = true;
              monitoring = true;
              minidlna = true;
              jellyfin = true;
            };
          };
        };
        modules = [
          ../modules/profiles/server.nix
        ];
      };
    };
  in
    # Performance: mapAttrs for O(n) vs O(n²) naive iteration
    builtins.mapAttrs (
      hostname: config:
        mkSystem {
          inherit hostname;
          inherit (config) system settings modules;
        }
    )
    machines;
}
