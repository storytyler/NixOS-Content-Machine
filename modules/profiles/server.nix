{
  config,
  lib,
  pkgs,
  machineConfig,
  ...
}:
with lib; {
  imports =
    [
      # Minimal imports for headless server
      ../programs/editor/neovim
      ../programs/cli/${machineConfig.terminalFileManager}
      ../programs/shell/${machineConfig.shell}

      # Server monitoring
      ../programs/cli/btop
    ]
    ++ (optionals machineConfig.features.virtualization [
      ../programs/misc/virt-manager
    ]);

  # Server-specific configuration
  boot = {
    # Minimal kernel for server
    kernelPackages = pkgs.linuxPackages;

    # No need for splash screen
    plymouth.enable = false;

    # Faster boot
    loader.timeout = 2;
  };

  # No GUI
  services.xserver.enable = false;

  # Essential server services
  services = {
    # SSH access
    openssh = mkIf (machineConfig.features.services.ssh or false) {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        X11Forwarding = false;
      };
      ports = [22];
    };

    # Fail2ban for security
    fail2ban = {
      enable = machineConfig.features.services.ssh or false;
      maxretry = 3;
      bantime = "1h";
    };

    # MinDLNA for media streaming
    minidlna = mkIf (machineConfig.features.services.minidlna or false) {
      enable = true;
      openFirewall = true;
      settings = {
        friendly_name = "${config.networking.hostName}-DLNA";
        media_dir = [
          "/srv/media/videos"
          "/srv/media/music"
          "/srv/media/pictures"
        ];
        inotify = "yes";
        log_level = "warn";
      };
    };

    # Monitoring with Prometheus and Grafana
    prometheus = mkIf (machineConfig.features.services.monitoring or false) {
      enable = true;
      port = 9090;
      exporters = {
        node = {
          enable = true;
          port = 9100;
        };
      };
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = ["localhost:9100"];
            }
          ];
        }
      ];
    };

    grafana = mkIf (machineConfig.features.services.monitoring or false) {
      enable = true;
      settings = {
        server = {
          http_port = 3000;
          domain = "localhost";
        };
      };
    };

    # Automatic updates
    system.autoUpgrade = {
      enable = true;
      allowReboot = false;
      dates = "04:00";
      flake = "github:yourusername/nixos-config";
    };
  };

  # Container support
  virtualisation = mkIf (machineConfig.features.containers or false) {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    podman = {
      enable = false; # Alternative to Docker
      dockerCompat = true;
    };
  };

  # Server packages
  environment.systemPackages = with pkgs;
    [
      # Administration
      vim
      tmux
      htop
      iotop
      iftop
      ncdu

      # Network tools
      nmap
      tcpdump
      dig
      curl
      wget

      # System tools
      rsync
      borgbackup
      restic

      # Monitoring
      lm_sensors
      smartmontools
    ]
    ++ (optionals machineConfig.features.containers [
      docker-compose
      lazydocker
    ]);

  # Networking for server
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts =
        (optionals (machineConfig.features.services.ssh or false) [22])
        ++ (optionals (machineConfig.features.services.monitoring or false) [3000 9090 9100]);
    };

    # Use systemd-networkd for servers
    useNetworkd = true;
    useDHCP = false;
  };

  # Security hardening
  security = {
    sudo.wheelNeedsPassword = true;

    # AppArmor for additional security
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # Minimal user setup
  users.users.${machineConfig.username} = {
    isNormalUser = true;
    extraGroups =
      ["wheel"]
      ++ (optionals machineConfig.features.containers ["docker"]);
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
    ];
  };
}
