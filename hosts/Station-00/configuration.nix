{ pkgs,
  videoDriver,
  hostname,
  browser,
  editor,
  terminal,
  terminalFileManager,
  machineConfig,
  ...
}: {

  imports = [
    ./hardware-configuration.nix
    ../../modules/hardware/video/${videoDriver}.nix # Enable GPU drivers defined in flake.nix
    ../../modules/hardware/drives

    ../common.nix
    ../../modules/scripts

    ../../modules/desktop/hyprland # Enable Hyprland window manager
    # ../../modules/desktop/i3-gaps # Enable i3 window manager

    ../../modules/programs/games
    ../../modules/programs/browser/${browser} # Set browser defined in flake.nix
    ../../modules/programs/terminal/${terminal} # Set terminal defined in flake.nix
    ../../modules/programs/editor/${editor} # Set editor defined in flake.nix
    ../../modules/programs/cli/${terminalFileManager} # Set file-manager defined in flake.nix
    ../../modules/programs/cli/starship
    ../../modules/programs/cli/tmux
    ../../modules/programs/cli/direnv
    ../../modules/programs/cli/lazygit
    ../../modules/programs/cli/cava
    ../../modules/programs/cli/btop
    ../../modules/programs/shell/bash
    ../../modules/programs/shell/zsh
    ../../modules/programs/media/discord
    # ../../modules/programs/media/spicetify
    ../../modules/programs/media/youtube-music
    ../../modules/programs/media/thunderbird
    ../../modules/programs/media/obs-studio
    ../../modules/programs/media/mpv
    ../../modules/programs/misc/tlp
    ../../modules/programs/misc/thunar
    ../../modules/programs/misc/lact # GPU fan, clock and power configuration
    # ../../modules/programs/misc/nix-ld
    # ../../modules/programs/misc/virt-manager
  ];

  programs.zsh.enable = true;

  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;

    # The themed package is instantiated via machine-level overlay
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

    wayland.enable = true; # Enable Wayland support for SDDM
  };

  # Home-manager config
  home-manager.sharedModules = [
    # Import Station-00 Home Manager profile from home-profiles.nix
    (import ../../flake-parts/home-profiles.nix { inherit pkgs; }).homeModules
  ];

  # System packages - themed package available automatically
  environment.systemPackages = with pkgs; [
    sddm-astronaut # Automatically instantiated with correct theme
  ];

  networking.hostName = hostname; # Set hostname defined in flake.nix

  # Stream my media to my devices via the network
  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      friendly_name = "NixOS-DLNA";
      media_dir = [
        # A = Audio, P = Pictures, V, = Videos, PV = Pictures and Videos.
        # "A,/mnt/work/Pimsleur/Russian"
        # "/mnt/work/NixOS"
        # "/mnt/work/Media/Films"
        # "/mnt/work/Media/Series"
        # "/mnt/work/Media/Videos"
        # "/mnt/work/Media/Music"
      ];
      inotify = "yes";
      log_level = "error";
    };
  };

  users.users.minidlna = {
    extraGroups = ["users"]; # so minidlna can access the files.
  };
}
