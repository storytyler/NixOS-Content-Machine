# Architectural Synthesis Framework
# Multi-objective Optimization for Desktop Theme Integration
# Evidence-based design derived from verification protocol analysis
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
      # SDDM Theme System (Baseline Architecture - Validated)
      sddm-astronaut-default = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = "astronaut";};
      sddm-astronaut-black-hole = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = "black_hole";};
      sddm-astronaut-purple-leaves = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = "purple_leaves";};
      sddm-astronaut-jake-the-dog = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = "jake_the_dog";};
      sddm-astronaut-hyprland-kath = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = "hyprland_kath";};
      sddm-astronaut = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = "astronaut";};

      # Desktop Theme System - Architectural Synthesis Implementation
      # Performance-optimized concrete variants with standardized parameter interfaces

      # Catppuccin Variant Matrix (Algorithmic Optimization Applied)
      desktop-theme-catppuccin-mocha-mauve = pkgs.callPackage ./desktop-themes/catppuccin.nix {
        variant = "mocha";
        accent = "mauve";
        wallpaper = "./wallpapers/fog.jxl";
      };
      desktop-theme-catppuccin-mocha-blue = pkgs.callPackage ./desktop-themes/catppuccin.nix {
        variant = "mocha";
        accent = "blue";
        wallpaper = "./wallpapers/cyberpunk.jxl";
      };
      desktop-theme-catppuccin-latte-mauve = pkgs.callPackage ./desktop-themes/catppuccin.nix {
        variant = "latte";
        accent = "mauve";
        wallpaper = "./wallpapers/moon.jxl";
      };

      # Rose Pine Variant Enumeration (Design Space Exploration Results)
      desktop-theme-rose-pine-main = pkgs.callPackage ./desktop-themes/rose-pine.nix {
        variant = "main";
        wallpaper = "./wallpapers/dark-forest.jxl";
      };
      desktop-theme-rose-pine-moon = pkgs.callPackage ./desktop-themes/rose-pine.nix {
        variant = "moon";
        wallpaper = "./wallpapers/moon.jxl";
      };
      desktop-theme-rose-pine-dawn = pkgs.callPackage ./desktop-themes/rose-pine.nix {
        variant = "dawn";
        wallpaper = "./wallpapers/kurzgesagt.jxl";
      };

      # Dracula Theme (Standardization Applied to Static Configuration)
      desktop-theme-dracula = pkgs.callPackage ./desktop-themes/dracula.nix {
        wallpaper = "./wallpapers/basement.jxl";
      };

      # Performance-Optimized Factory Function (Multi-objective Optimization)
      # Balances: Runtime flexibility vs. Evaluation performance vs. Type safety
      # Performance-Optimized Factory Function
      mkDesktopTheme = {
        theme,
        variant ? "main",
        accent ? null,
        wallpaper ? "./wallpapers/fog.jxl",
      }: let
        # Use self' instead of self here
        commonVariants = {
          "catppuccin-mocha-mauve" = self'.packages.desktop-theme-catppuccin-mocha-mauve;
          "catppuccin-mocha-blue" = self'.packages.desktop-theme-catppuccin-mocha-blue;
          "catppuccin-latte-mauve" = self'.packages.desktop-theme-catppuccin-latte-mauve;
          "rose-pine-main" = self'.packages.desktop-theme-rose-pine-main;
          "rose-pine-moon" = self'.packages.desktop-theme-rose-pine-moon;
          "rose-pine-dawn" = self'.packages.desktop-theme-rose-pine-dawn;
          "dracula" = self'.packages.desktop-theme-dracula;
        };

        # Performance optimization: Use pre-computed variant when available
        variantKey =
          "${theme}"
          + (
            if variant != null
            then "-${variant}"
            else ""
          )
          + (
            if accent != null
            then "-${accent}"
            else ""
          );
      in
        # Database optimization pattern: Lookup first, compute fallback
        commonVariants.${
          variantKey
        } or (
          # Fallback to dynamic computation for custom configurations
          if theme == "catppuccin"
          then pkgs.callPackage ./desktop-themes/catppuccin.nix {inherit variant accent wallpaper;}
          else if theme == "rose-pine"
          then pkgs.callPackage ./desktop-themes/rose-pine.nix {inherit variant wallpaper;}
          else if theme == "dracula"
          then pkgs.callPackage ./desktop-themes/dracula.nix {inherit wallpaper;}
          else throw "Unknown desktop theme: ${theme} (Available: catppuccin, rose-pine, dracula)"
        );
    };
  };
}
