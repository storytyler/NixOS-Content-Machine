# flake-parts/packages.nix - Clean packages only
{inputs, ...}: {
  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    system,
    lib,
    ...
  }: {
    packages = {
      # SDDM Theme System
      sddm-astronaut-default = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = "astronaut";};
      sddm-astronaut-black-hole = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = "black_hole";};
      sddm-astronaut-purple-leaves = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = "purple_leaves";};
      sddm-astronaut-jake-the-dog = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = "jake_the_dog";};
      sddm-astronaut-hyprland-kath = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = "hyprland_kath";};
      sddm-astronaut = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = "astronaut";};

      # System utility scripts
      rebuild-current = pkgs.writeShellApplication {
        name = "rebuild-current";
        runtimeInputs = with pkgs; [nixos-rebuild git jq];
        text = ''
          hostname=$(hostname)
          echo "Rebuilding NixOS configuration for: $hostname"
          exec sudo nixos-rebuild switch --flake ".#$hostname" "$@"
        '';
      };
    };
  };
}
