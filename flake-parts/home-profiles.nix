{
  lib,
  pkgs,
  config,
  machineConfig,
  ...
}: let
  homeModules = {
    # CLI tools
    tmux = import ../modules/programs/cli/tmux/home.nix;
    btop = import ../modules/programs/cli/btop/home.nix;
    direnv = import ../modules/programs/cli/direnv/home.nix;
    starship = import ../modules/programs/cli/starship/home.nix;

    # Editors
    neovim = import ../modules/programs/editor/neovim/home.nix;
    emacs = import ../modules/programs/editor/emacs/home.nix;

    # Terminal emulators
    wezterm = import ../modules/programs/terminal/wezterm/home.nix;
    alacritty = import ../modules/programs/terminal/alacritty/home.nix;
    kitty = import ../modules/programs/terminal/kitty/home.nix;

    # Hyprland desktop modules
    hyprlock = import ../modules/desktop/hyprland/programs/hyprlock/home.nix;
    hypridle = import ../modules/desktop/hyprland/programs/hypridle/home.nix;
    rofi = import ../modules/desktop/hyprland/programs/rofi/home.nix;
    waybar = import ../modules/desktop/hyprland/programs/waybar/home.nix;
    dunst = import ../modules/desktop/hyprland/programs/dunst/home.nix;

    # Themes (only if desktop role / Station-00)
    dracula = import ../modules/themes/Dracula/home.nix;
    catppuccin = import ../modules/themes/Catppuccin/home.nix;
    rosepine = import ../modules/themes/rose-pine/home.nix;
  };
in {
  home-manager.users.player00 = {...}: {
    imports =
      [
        homeModules.tmux
        homeModules.btop
        homeModules.direnv
        homeModules.starship
        homeModules.neovim
        homeModules.emacs
        homeModules.wezterm
        homeModules.alacritty
        homeModules.kitty
        homeModules.hyprlock
        homeModules.hypridle
        homeModules.rofi
        homeModules.waybar
        homeModules.dunst
      ]
      ++ lib.optionals (machineConfig.role == "desktop") [
        homeModules.dracula
        homeModules.catppuccin
        homeModules.rosepine
      ];
  };
}
