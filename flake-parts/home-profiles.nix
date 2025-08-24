{ lib, pkgs, ... }:

let
  homeModules = {
    # CLI tools
    tmux    = import ../modules/programs/cli/tmux/home.nix;
    btop    = import ../modules/programs/cli/btop/home.nix;
    direnv  = import ../modules/programs/cli/direnv/home.nix;
    starship= import ../modules/programs/cli/starship/home.nix;

    # Editors
    neovim  = import ../modules/programs/editor/neovim/home.nix;
    emacs   = import ../modules/programs/editor/emacs/home.nix;

    # Terminal emulators
    wezterm  = import ../modules/programs/terminal/wezterm/home.nix;
    alacritty = import ../modules/programs/terminal/alacritty/home.nix;
    kitty    = import ../modules/programs/terminal/kitty/home.nix;

    # Hyprland desktop modules
    hyprlock  = import ../modules/desktop/hyprland/programs/hyprlock/home.nix;
    hypridle  = import ../modules/desktop/hyprland/programs/hypridle/home.nix;
    rofi      = import ../modules/desktop/hyprland/programs/rofi/home.nix;
    waybar    = import ../modules/desktop/hyprland/programs/waybar/home.nix;
    dunst     = import ../modules/desktop/hyprland/programs/dunst/home.nix;

    # Themes
    dracula   = import ../modules/themes/Dracula/home.nix;
    catppuccin= import ../modules/themes/Catppuccin/home.nix;
    rosepine  = import ../modules/themes/rose-pine/home.nix;
  };
in
{
  inherit homeModules;
}
