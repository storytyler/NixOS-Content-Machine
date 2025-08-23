{
  config,
  lib,
  pkgs,
  machineConfig,
  ...
}: {
  # Scout-02 Laptop specific configuration

  # Enable laptop-specific hardware support
  hardware = {
    # Bluetooth for wireless peripherals
    bluetooth = {
      enable = true;
      powerOnBoot = false;
      settings = {
        General = {
          FastConnectable = true;
          JustWorksRepairing = "always";
        };
      };
    };

    # Sound configuration optimized for laptop speakers
    pulseaudio.enable = false;
  };

  # Power management critical for laptop
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "powersave";

    powertop.enable = true;
  };

  # Laptop-specific services
  services = {
    # Touchpad support
    libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        naturalScrolling = true;
        scrollMethod = "twofinger";
        disableWhileTyping = true;
        accelProfile = "adaptive";
      };
    };

    # Automatic brightness based on ambient light
    illum = {
      enable = false; # Enable if laptop has ambient light sensor
    };

    # Laptop mode tools
    tlp = {
      enable = true;
      settings = {
        # CPU settings
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 50;

        # GPU settings
        RADEON_POWER_PROFILE_ON_AC = "high";
        RADEON_POWER_PROFILE_ON_BAT = "low";

        # Wifi power saving
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";

        # Sound power saving
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;

        # Battery charge thresholds (if supported)
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;

        # Runtime PM
        RUNTIME_PM_ON_AC = "on";
        RUNTIME_PM_ON_BAT = "auto";

        # USB autosuspend
        USB_AUTOSUSPEND = 1;
      };
    };

    # Lock on lid close
    logind = {
      lidSwitch = "suspend-then-hibernate";
      lidSwitchExternalPower = "suspend";
      extraConfig = ''
        HandlePowerKey=suspend
        HandleSuspendKey=suspend
        HandleHibernateKey=hibernate
        IdleAction=suspend
        IdleActionSec=20min
      '';
    };
  };

  # Hibernation support
  boot = {
    resumeDevice = "/dev/disk/by-label/swap"; # Adjust to your swap partition
    kernelParams = [
      "resume_offset=0" # Adjust if using swapfile
      "intel_pstate=enable"
    ];
  };

  # Lightweight packages for laptop
  environment.systemPackages = with pkgs; [
    # Power management
    acpi
    powertop
    brightnessctl

    # Network tools
    wirelesstools
    wpa_supplicant_gui

    # Lightweight alternatives
    zathura # PDF viewer
    sxiv # Image viewer

    # Development basics
    vscodium
    git

    # Battery monitoring in status bar
    acpilight
  ];

  # Swap configuration for hibernation
  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";
      priority = 100;
    }
  ];

  # Networking optimized for mobility
  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
        powersave = true;
        scanRandMacAddress = true;
      };
      # Connection profiles for common networks
      dispatcherScripts = [
        {
          source = pkgs.writeText "99-wifi-powersave" ''
            case "$2" in
              up)
                iw dev "$1" set power_save on
                ;;
              down)
                iw dev "$1" set power_save off
                ;;
            esac
          '';
        }
      ];
    };

    # Firewall with stricter rules for public networks
    firewall = {
      enable = true;
      allowedTCPPorts = [];
      allowedUDPPorts = [];

      # More restrictive on public networks
      checkReversePath = "strict";
      logRefusedConnections = false;
    };
  };

  # Home Manager specific config for laptop
  home-manager.users.${machineConfig.username} = {
    # Lightweight terminal config
    programs.alacritty.settings = {
      window.opacity = 0.95;
      font.size = 11.0;
    };

    # Battery indicator in waybar
    programs.waybar.settings.mainBar = {
      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{capacity}% {icon}";
        format-charging = "{capacity}% ";
        format-plugged = "{capacity}% ";
        format-icons = ["" "" "" "" ""];
      };
    };
  };
}
