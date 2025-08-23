{
  config,
  lib,
  pkgs,
  machineConfig,
  ...
}:
with lib; {
  imports = [
    # Base imports similar to workstation but optimized for mobile
    ../hardware/video/${machineConfig.videoDriver}.nix
    ../desktop/hyprland

    ../programs/browser/${machineConfig.browser}
    ../programs/terminal/${machineConfig.terminal}
    ../programs/editor/${machineConfig.editor}
    ../programs/cli/${machineConfig.terminalFileManager}

    # Essential CLI tools
    ../programs/cli/starship
    ../programs/cli/tmux
    ../programs/cli/btop

    ../programs/shell/${machineConfig.shell}

    # Power management
    ../programs/misc/tlp
  ];

  # Laptop-specific configuration
  services = {
    # Advanced power management
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 60;

        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;

        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";

        RUNTIME_PM_ON_AC = "on";
        RUNTIME_PM_ON_BAT = "auto";

        USB_AUTOSUSPEND = 1;
      };
    };

    # Automatic CPU frequency scaling
    auto-cpufreq = {
      enable = false; # Disable if using TLP
    };

    # Battery monitoring
    upower.enable = true;

    # Bluetooth for peripherals
    blueman.enable = true;

    # Automatic brightness adjustment
    clight = {
      enable = true;
      settings = {
        verbose = false;
        backlight.trans_step = 0.05;
        backlight.trans_duration = 10;
      };
    };

    # Thermald for Intel CPUs
    thermald.enable = machineConfig.videoDriver == "intel";
  };

  # Laptop-specific packages
  environment.systemPackages = with pkgs;
    [
      # Power management tools
      powertop
      acpi
      brightnessctl

      # Lightweight alternatives
      zathura # PDF viewer
      mpv # Video player
      feh # Image viewer

      # Network tools
      networkmanagerapplet

      # Battery notification script (if exists)
    ]
    ++ (optionals machineConfig.features.development [
      # Lightweight dev tools
      vscodium
      git
      gh
    ]);

  # Hardware configuration for laptops
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false; # Save battery
    };

    # Enable firmware updates
    enableRedistributableFirmware = true;
  };

  # Suspend/hibernate configuration
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=1h
    HandleLidSwitch=suspend
    HandleLidSwitchExternalPower=ignore
  '';

  # Network optimizations for mobile use
  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        powersave = true;
        scanRandMacAddress = true;
      };
    };
  };

  # Home Manager configuration for laptop users
  home-manager.sharedModules = [
    {
      # Battery widget for status bar
      programs.waybar.settings.mainBar.modules-right =
        mkBefore ["battery"];

      # Power menu shortcuts
      wayland.windowManager.hyprland.settings.bind = [
        "$mainMod, B, exec, notify-send 'Battery' \"$(acpi -b)\""
      ];
    }
  ];
}
