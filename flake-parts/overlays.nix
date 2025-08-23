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

    # Machine-specific package selection overlay
    (final: prev: {
      # Theme-based package selection logic
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

      # Additional machine-specific package selections can follow same pattern
      # themed-wallpaper = selectWallpaperVariant settings.wallpaper;
    })
  ];
})
