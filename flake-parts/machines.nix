{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations = let
    # Shared function to create a NixOS system
    mkSystem = {
      hostname,
      system ? "x86_64-linux",
      modules,
      settings,
    }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs =
          {
            inherit self inputs;
            inherit (settings) username;
            machineConfig = settings;
          }
          // settings;
        modules =
          [
            # Core configuration
            ../hosts/${hostname}/configuration.nix
            ../hosts/${hostname}/hardware-configuration.nix

            # Common configuration for all machines
            ../hosts/common.nix

            # Home Manager integration
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs =
                  {
                    inherit inputs self;
                    inherit (settings) username;
                    machineConfig = settings;
                  }
                  // settings;
              };
            }
          ]
          ++ modules;
      };

    # Machine-specific settings
    machines = {
      # Desktop workstation
      "Station-00" = {
        system = "x86_64-linux";
        settings = {
          username = "player00";
          role = "desktop";
          profile = "workstation";

          # Hardware
          videoDriver = "intel";
          drives = ["games" "work"];

          # Software preferences
          editor = "vscode";
          browser = "zen";
          terminal = "wezterm";
          terminalFileManager = "yazi";
          shell = "zsh";

          # Desktop environment
          desktop = "hyprland";
          sddmTheme = "astronaut";
          wallpaper = "fog";

          # Localization
          locale = "en_US.UTF-8";
          timezone = "America/Chicago";
          kbdLayout = "us";
          kbdVariant = "";
          consoleKeymap = "us";

          # Features
          features = {
            gaming = true;
            development = true;
            multimedia = true;
            virtualization = false;
          };
        };
        modules = [
          ../modules/profiles/workstation.nix
        ];
      };

      # Laptop configuration
      "Scout-02" = {
        system = "x86_64-linux";
        settings = {
          username = "player00";
          role = "laptop";
          profile = "mobile";

          # Hardware
          videoDriver = "intel";
          drives = [];

          # Software preferences (can override per-machine)
          editor = "nixvim";
          browser = "firefox";
          terminal = "alacritty";
          terminalFileManager = "yazi";
          shell = "zsh";

          # Desktop environment
          desktop = "hyprland";
          sddmTheme = "astronaut";
          wallpaper = "moon";

          # Localization (inherit from Station-00 or override)
          locale = "en_US.UTF-8";
          timezone = "America/Chicago";
          kbdLayout = "us";
          kbdVariant = "";
          consoleKeymap = "us";

          # Features
          features = {
            gaming = false;
            development = true;
            multimedia = false;
            virtualization = false;
            battery = true; # Enable battery optimizations
          };
        };
        modules = [
          ../modules/profiles/laptop.nix
          ../modules/hardware/power-management.nix
        ];
      };

      # Server/Homelab configuration
      "Subrelay-01" = {
        system = "x86_64-linux";
        settings = {
          username = "admin";
          role = "server";
          profile = "headless";

          # No GUI components
          videoDriver = null;
          drives = ["data"];

          # Minimal tools for server
          editor = "neovim";
          browser = null;
          terminal = null;
          terminalFileManager = "lf";
          shell = "bash";

          # No desktop for server
          desktop = null;
          sddmTheme = null;
          wallpaper = null;

          # Localization
          locale = "en_US.UTF-8";
          timezone = "UTC";
          kbdLayout = "us";
          kbdVariant = "";
          consoleKeymap = "us";

          # Features
          features = {
            gaming = false;
            development = false;
            multimedia = false;
            virtualization = true;
            containers = true;
            services = {
              minidlna = true;
              ssh = true;
              monitoring = true;
            };
          };
        };
        modules = [
          ../modules/profiles/server.nix
          ../modules/services/server-stack.nix
        ];
      };
    };
  in
    builtins.mapAttrs (
      hostname: config:
        mkSystem {
          inherit hostname;
          inherit (config) system settings modules;
        }
    )
    machines;
}
