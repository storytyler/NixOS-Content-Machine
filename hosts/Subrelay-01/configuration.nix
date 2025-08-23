{
  config,
  lib,
  pkgs,
  machineConfig,
  ...
}: {
  # Subrelay-01 Server specific configuration

  # Server-optimized boot configuration
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "auto";
      };
      timeout = 2;
    };

    # Server kernel parameters
    kernelParams = [
      "console=tty1"
      "console=ttyS0,115200" # Serial console for remote management
      "panic=30" # Reboot after 30 seconds on kernel panic
      "boot.panic_on_fail" # Panic on boot failure
    ];

    # Use LTS kernel for stability
    kernelPackages = pkgs.linuxPackages;
  };

  # No GUI for server
  services.xserver.enable = false;
  environment.noXlibs = true;

  # Essential server services
  services = {
    # SSH with security hardening
    openssh = {
      enable = true;
      ports = [22];
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        X11Forwarding = false;
        PermitEmptyPasswords = false;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
        MaxAuthTries = 3;
        MaxSessions = 2;
        TCPKeepAlive = false;
        Compression = false;
        UseDNS = false;

        # Only allow specific users
        AllowUsers = [machineConfig.username "admin"];
      };

      extraConfig = ''
        AuthenticationMethods publickey
        PubkeyAuthentication yes
        LogLevel VERBOSE
      '';
    };

    # Fail2ban for SSH protection
    fail2ban = {
      enable = true;
      maxretry = 3;
      ignoreIP = ["127.0.0.1" "192.168.1.0/24"];
      bantime = "1h";
      bantime-increment = {
        enable = true;
        rndtime = "5m";
        maxtime = "24h";
        multiplier = "2";
      };

      jails = {
        sshd = {
          settings = {
            enabled = true;
            port = "22";
            filter = "sshd";
            maxretry = 3;
          };
        };
      };
    };

    # Media server
    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    # Alternative to minidlna
    minidlna = {
      enable = false; # Using Jellyfin instead
    };

    # Container services
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = ["--all" "--volumes"];
      };

      daemon.settings = {
        log-driver = "json-file";
        log-opts = {
          max-size = "10m";
          max-file = "3";
        };
      };
    };

    # Monitoring stack
    prometheus = {
      enable = true;
      port = 9090;
      retentionTime = "30d";

      exporters = {
        node = {
          enable = true;
          port = 9100;
          enabledCollectors = [
            "systemd"
            "processes"
            "cpu"
            "meminfo"
            "diskstats"
            "filesystem"
            "netdev"
            "stat"
            "time"
            "uname"
            "loadavg"
          ];
        };

        systemd = {
          enable = true;
          port = 9558;
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
        {
          job_name = "systemd";
          static_configs = [
            {
              targets = ["localhost:9558"];
            }
          ];
        }
      ];
    };

    grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3000;
          domain = "localhost";
          root_url = "http://localhost:3000";
          serve_from_sub_path = true;
        };

        security = {
          admin_password = "$__file{/run/secrets/grafana-admin-password}";
          cookie_secure = true;
          cookie_samesite = "strict";
        };

        analytics.reporting_enabled = false;
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:9090";
            isDefault = true;
          }
        ];
      };
    };

    # Nginx reverse proxy
    nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts = {
        "grafana.local" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
            proxyWebsockets = true;
          };
        };
      };
    };

    # Automatic updates (security patches only)
    system.autoUpgrade = {
      enable = true;
      allowReboot = false;
      channel = "https://nixos.org/channels/nixos-24.11";
      dates = "02:00";
      randomizedDelaySec = "45min";
      flags = ["--update-input" "nixpkgs"];
    };

    # Log rotation
    journald = {
      extraConfig = ''
        SystemMaxUse=1G
        SystemMaxFileSize=100M
        MaxRetentionSec=1month
        ForwardToSyslog=false
      '';
    };

    # NTP time synchronization
    chrony = {
      enable = true;
      servers = [
        "0.nixos.pool.ntp.org"
        "1.nixos.pool.ntp.org"
      ];
    };
  };

  # Security hardening
  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
      execWheelOnly = true;
      extraConfig = ''
        Defaults lecture = never
        Defaults passwd_tries = 3
        Defaults timestamp_timeout = 15
        Defaults requiretty
      '';
    };

    # Firewall configuration
    firewall = {
      enable = true;

      allowedTCPPorts = [
        22 # SSH
        80 # HTTP
        443 # HTTPS
        3000 # Grafana
        8096 # Jellyfin
        9090 # Prometheus
      ];

      allowedUDPPorts = [
        # Jellyfin discovery
        1900
        7359
      ];

      # Drop all other traffic
      extraCommands = ''
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT

        # Allow established connections
        iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

        # Rate limit SSH connections
        iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
        iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
      '';
    };
  };

  # Server packages
  environment.systemPackages = with pkgs; [
    # Administration
    tmux
    htop
    iotop
    iftop
    ncdu

    # Network tools
    nmap
    tcpdump
    dig
    traceroute
    mtr

    # System monitoring
    sysstat
    dstat

    # Backup tools
    borgbackup
    restic
    rclone

    # Container management
    docker-compose
    lazydocker

    # Text processing
    jq
    yq
    ripgrep
  ];

  # Networking
  networking = {
    useDHCP = false;
    useNetworkd = true;

    # Static IP configuration (adjust as needed)
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.1.100";
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = "192.168.1.1";
    nameservers = ["1.1.1.1" "1.0.0.1"];
  };

  # Systemd network configuration
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
  };

  # Mount points for data drives
  fileSystems."/srv/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "ext4";
    options = ["defaults" "noatime" "nodiratime"];
  };

  # Users
  users.users.${machineConfig.username} = {
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
    ];
  };
}
