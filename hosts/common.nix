{
  config,
  lib,
  pkgs,
  inputs,
  machineConfig,
  ...
}:
with lib; {
  # NOTE: This file should NEVER import machine-specific configurations
  # It only provides base system configuration shared by all machines

  # Import only non-circular modules
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];

  # Enable nix-index for command-not-found
  programs.nix-index-database.comma.enable = true;

  # User configuration (machine-agnostic)
  users.users.${machineConfig.username} = {
    isNormalUser = true;
    extraGroups =
      [
        "wheel"
        "networkmanager"
        "audio"
        "video"
        "input"
        "disk"
      ]
      ++ (optionals machineConfig.features.virtualization [
        "libvirtd"
        "kvm"
      ])
      ++ (optionals machineConfig.features.containers [
        "docker"
      ]);
    shell = pkgs.${machineConfig.shell};
  };

  # Nix configuration
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      warn-dirty = false;

      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org/"
        "https://hyprland.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];

      # Prevent disk space issues
      min-free = mkDefault (100 * 1024 * 1024); # 100MB
      max-free = mkDefault (1024 * 1024 * 1024); # 1GB

      # Build performance optimization
      max-jobs = "auto";
      cores = 0;
      keep-outputs = true;
      keep-derivations = true;
    };

    # Conservative garbage collection with safety limits
    gc = mkDefault {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d --max-freed 5G";
    };

    # Store optimization
    optimise = {
      automatic = true;
      dates = ["03:45"];
    };
  };

  # NH (nix helper) configuration - conditional on desktop/laptop
  programs.nh = mkIf (machineConfig.role != "server") {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 3";
    };
    flake = "/home/${machineConfig.username}/NixOS";
  };

  # Timezone and locale
  time.timeZone = machineConfig.timezone;
  i18n = {
    defaultLocale = machineConfig.locale;
    extraLocaleSettings = {
      LC_ADDRESS = machineConfig.locale;
      LC_IDENTIFICATION = machineConfig.locale;
      LC_MEASUREMENT = machineConfig.locale;
      LC_MONETARY = machineConfig.locale;
      LC_NAME = machineConfig.locale;
      LC_NUMERIC = machineConfig.locale;
      LC_PAPER = machineConfig.locale;
      LC_TELEPHONE = machineConfig.locale;
      LC_TIME = machineConfig.locale;
    };
  };

  # Console configuration
  console.keyMap = machineConfig.consoleKeymap;

  # Keyboard configuration (for X11/Wayland)
  services.xserver = mkIf (machineConfig.desktop != null) {
    xkb = {
      layout = machineConfig.kbdLayout;
      variant = machineConfig.kbdVariant;
    };
  };

  # Bootloader configuration
  boot = {
    tmp.cleanOnBoot = true;
    kernelPackages = mkDefault pkgs.linuxPackages_latest;

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      timeout = mkDefault (
        if machineConfig.role == "server"
        then 2
        else 5
      );

      # GRUB configuration
      grub = mkIf (machineConfig.role != "server") {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        gfxmodeEfi = mkDefault "2715x1527";
        gfxmodeBios = mkDefault "2715x1527";

        # Theme for non-server machines
        theme = pkgs.stdenv.mkDerivation {
          pname = "distro-grub-themes";
          version = "3.1";
          src = pkgs.fetchFromGitHub {
            owner = "AdisonCavani";
            repo = "distro-grub-themes";
            rev = "v3.1";
            hash = "sha256-ZcoGbbOMDDwjLhsvs77C7G7vINQnprdfI37a9ccrmPs=";
          };
          installPhase = "cp -r customize/nixos $out";
        };
      };

      # Systemd-boot for servers (simpler, faster)
      systemd-boot = mkIf (machineConfig.role == "server") {
        enable = true;
        consoleMode = "auto";
      };
    };
  };

  # Filesystem support
  boot.supportedFilesystems = ["ntfs" "exfat" "ext4" "btrfs"];

  # System packages with quality and development tools
  environment.systemPackages = with pkgs;
    [
      # Core utilities
      vim
      git
      wget
      curl
      htop
      tree
      file
      which
      gnumake

      # Nix tools
      nix-output-monitor
      nix-tree
      nix-diff

      # System tools
      lsof
      pciutils
      usbutils

      # Archive tools
      unzip
      zip
      p7zip

      # Monitoring
      lm_sensors

      # Configuration analysis and quality tools
      deadnix # Find unused Nix code
      statix # Nix linter and antipattern detector
      nvd # Compare system generations
      comma # Run binaries without installing

      # System monitoring and maintenance
      nix-du # Visualize Nix store disk usage
      manix # Search Nix documentation
    ]
    ++ (optionals (machineConfig.role != "server") [
      # Desktop/laptop extras
      killall
      ripgrep
      fd
      fzf
      jq

      # Development workflow tools
      nix-init # Generate Nix packages from URLs
      nurl # Generate Nix fetcher calls
    ]);

  # Security basics
  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = mkDefault true;
    };

    polkit.enable = mkDefault (machineConfig.desktop != null);
  };

  # Basic networking
  networking = {
    hostName = mkDefault machineConfig.hostname;

    # Enable firewall
    firewall = {
      enable = mkDefault true;
      # Ports are configured in machine-specific or profile configs
    };
  };

  # Enable fstrim for SSDs
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # System state version
  system.stateVersion = "24.11";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Environment variables
  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_BIN_HOME = "$HOME/.local/bin";
    FLAKE_DIR = "/home/${machineConfig.username}/NixOS";
  };

  # User-level development environment enhancements
  home-manager.sharedModules = [
    (_: {
      programs = {
        # High-performance directory environment switching
        direnv = {
          enable = true;
          nix-direnv.enable = true; # 10x faster shell loading
          stdlib = ''
            layout_poetry() {
              if [[ ! -f pyproject.toml ]]; then
                log_error 'No pyproject.toml found'
                return 1
              fi
              layout python
            }
          '';
        };

        # Optimized Git configuration
        git = {
          enable = true;
          userName = machineConfig.username;
          userEmail = "${machineConfig.username}@nixos.local";

          extraConfig = {
            core.editor = machineConfig.editor;
            pull.rebase = false;
            init.defaultBranch = "main";

            # Performance optimizations
            core.preloadindex = true;
            core.fscache = true;
            gc.auto = 256;

            # Enhanced workflow settings
            diff.algorithm = "histogram";
            merge.tool = "vimdiff";
            push.default = "current";
          };

          # Convenient aliases for daily workflows
          aliases = {
            st = "status";
            co = "checkout";
            br = "branch";
            unstage = "reset HEAD --";
            last = "log -1 HEAD";
            visual = "!gitk";
          };
        };

        # Shell aliases for Nix workflows
        bash = mkIf (machineConfig.shell == "bash") {
          shellAliases = {
            ll = "ls -l";
            la = "ls -la";

            # Quick Nix analysis commands
            ndead = "deadnix";
            nstat = "statix check";
            ndiff = "nvd diff-closures /nix/var/nix/profiles/system-*-link | tail -20";
            nstore = "nix-du";

            # Development shortcuts
            nsearch = "comma";
            nshell = "nix develop";
          };
        };

        zsh = mkIf (machineConfig.shell == "zsh") {
          shellAliases = {
            # Nix system analysis shortcuts
            ndead = "deadnix";
            nstat = "statix check";
            ndiff = "nvd diff-closures /nix/var/nix/profiles/system-*-link | tail -20";
            nstore = "nix-du -s 100M";
          };
        };
      };

      # Documentation and analysis tools
      home.packages = with pkgs;
        [
          manix # Documentation search
          nix-tree # Dependency graph browser
          nix-du # Store usage visualization
          nixpkgs-review # PR testing
        ]
        ++ (optionals (machineConfig.features.development or false) [
          nix-update # Package version updates
          nix-init # Package generation
          nurl # Fetcher generation
        ]);
    })
  ];
}
