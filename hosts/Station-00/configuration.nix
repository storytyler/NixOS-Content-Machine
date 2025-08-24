{ config, lib, pkgs, videoDriver, hostname, browser, editor, terminal, terminalFileManager, machineConfig, ... }:

let
  # Conditionally import Station-00 home modules
  stationHomeModules = lib.mkIf (hostname == "Station-00") (
    import ../../flake-parts/home-profiles.nix { inherit pkgs; }
  ).homeModules;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/hardware/video/${videoDriver}.nix
    ../../modules/hardware/drives

    ../common.nix
    ../../modules/scripts

    ../../modules/desktop/hyprland
    ../../modules/programs/games
    ../../modules/programs/browser/${browser}
    ../../modules/programs/terminal/${terminal}
    ../../modules/programs/editor/${editor}
    ../../modules/programs/cli/${terminalFileManager}
    ../../modules/programs/cli/starship
    ../../modules/programs/cli/tmux
    ../../modules/programs/cli/direnv
    ../../modules/programs/cli/lazygit
    ../../modules/programs/cli/cava
    ../../modules/programs/cli/btop
    ../../modules/programs/shell/bash
    ../../modules/programs/shell/zsh
    ../../modules/programs/media/discord
    ../../modules/programs/media/youtube-music
    ../../modules/programs/media/thunderbird
    ../../modules/programs/media/obs-studio
    ../../modules/programs/media/mpv
    ../../modules/programs/misc/tlp
    ../../modules/programs/misc/thunar
    ../../modules/programs/misc/lact
    ../../modules/services/claude-code
  ];
 services.claude-code = {
    enable = true;
    apiKeyFile = "/run/secrets/claude.key";
  };
  programs.zsh.enable = true;

  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";
    settings = {
      General = {
        HaltCommand = "/run/current-system/systemd/bin/systemctl poweroff";
        RebootCommand = "/run/current-system/systemd/bin/systemctl reboot";
      };
      Theme = {
        Current = "sddm-astronaut-theme";
        ThemeDir = "/run/current-system/sw/share/sddm/themes";
      };
    };
    wayland.enable = true;
  };

  # Home Manager integration (Station-00 only)
  home-manager.sharedModules = lib.mkIf (hostname == "Station-00") [
    stationHomeModules
  ];

  environment.systemPackages = with pkgs; [
    sddm-astronaut
  ];

  networking.hostName = hostname;

  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      friendly_name = "NixOS-DLNA";
      media_dir = [];
      inotify = "yes";
      log_level = "error";
    };
  };

  users.users.minidlna = {
    extraGroups = ["users"];
  };
}
