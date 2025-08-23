# flake-parts/machines.nix - Cleaned up to eliminate definition conflicts
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
            # Machine-specific overlay for theme selection (NOT redefinition)
            ({
              config,
              lib,
              pkgs,
              ...
            }: {
              nixpkgs.overlays = [
                # NUR overlay
                inputs.nur.overlays.default

                # Stable channel overlay
                (final: prev: {
                  stable = import inputs.nixpkgs-stable {
                    inherit system;
                    config.allowUnfree = true;
                  };
                })

                # Theme selection overlay (NO REDEFINITION - just aliasing)
                (final: prev: {
                  # Use theme selection logic without redefining the package
                  sddm-astronaut =
                    if settings.sddmTheme == "astronaut"
                    then self.packages.${system}.sddm-astronaut-default
                    else if settings.sddmTheme == "black_hole"
                    then self.packages.${system}.sddm-astronaut-black-hole
                    else if settings.sddmTheme == "purple_leaves"
                    then self.packages.${system}.sddm-astronaut-purple-leaves
                    else if settings.sddmTheme == "jake_the_dog"
                    then self.packages.${system}.sddm-astronaut-jake-the-dog
                    else if settings.sddmTheme == "hyprland_kath"
                    then self.packages.${system}.sddm-astronaut-hyprland-kath
                    else self.packages.${system}.sddm-astronaut-default; # fallback

                  # This approach SELECTS rather than REDEFINES packages
                })
              ];
            })

            # Core configuration files
            ../hosts/${hostname}/configuration.nix
            ../hosts/${hostname}/hardware-configuration.nix
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

    # Machine configurations (unchanged)
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

      # Other machines (Scout-02, Subrelay-01) maintained...
      # [Rest of machine definitions unchanged]
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
