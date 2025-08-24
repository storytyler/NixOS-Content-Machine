# modules/services/claude-code/default.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.claude-code;
in
{
  options.services.claude-code = {
    enable = lib.mkEnableOption "Claude Code AI coding assistant service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.claude-code or (throw "claude-code package not available. Please add the claude-code-nix overlay to your configuration.");
      defaultText = lib.literalExpression "pkgs.claude-code";
      description = "Claude Code package to use. Requires claude-code-nix overlay.";
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to file containing the Claude API key.
        This file should contain only the API key and be readable by the claude-code service.
        Example: /run/secrets/claude.key
      '';
      example = "/run/secrets/claude.key";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "claude-code";
      description = "User to run the Claude Code service as";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "claude-code";
      description = "Group to run the Claude Code service as";
    };

    workingDirectory = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/claude-code";
      description = "Working directory for the Claude Code service";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.workingDirectory;
      createHome = true;
      description = "Claude Code service user";
    };

    users.groups.${cfg.group} = { };

    # Set up environment configuration for the API key
    environment.etc."claude-code/api-key".source = cfg.apiKeyFile;

    # Create the working directory
    systemd.tmpfiles.rules = [
      "d ${cfg.workingDirectory} 0755 ${cfg.user} ${cfg.group} -"
    ];

    # System packages (make claude available system-wide)
    environment.systemPackages = [ cfg.package ];

    # Main systemd service
    systemd.services.claude-code = {
      description = "Claude Code AI coding assistant service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.workingDirectory;
        
        # Use DynamicUser for additional security
        DynamicUser = true;
        
        # Environment setup
        Environment = [
          "ANTHROPIC_API_KEY_FILE=${cfg.apiKeyFile}"
        ];
        EnvironmentFile = cfg.apiKeyFile;
        
        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        
        # Restart policy
        Restart = "on-failure";
        RestartSec = "5s";
        
        # Resource limits
        MemoryMax = "1G";
        CPUQuota = "50%";
        
        # Command to run (simple health check service)
        ExecStart = "${cfg.package}/bin/claude --version";
        ExecStartPost = "${pkgs.coreutils}/bin/sleep 1";
        
        # Service remains active after start
        RemainAfterExit = true;
      };

      # Service dependencies
      requires = [ "network.target" ];
    };

    # Optional: Create a convenience script for users
    environment.etc."claude-code/init-user".source = pkgs.writeScript "claude-init-user" ''
      #!/bin/sh
      # Initialize Claude Code for current user
      echo "Initializing Claude Code for user $(whoami)..."
      if [ -f "${cfg.apiKeyFile}" ]; then
        export ANTHROPIC_API_KEY="$(cat ${cfg.apiKeyFile})"
        ${cfg.package}/bin/claude --version
        echo "Claude Code is ready! Run 'claude --help' to get started."
      else
        echo "Error: API key file not found at ${cfg.apiKeyFile}"
        exit 1
      fi
    '';
  };

  meta = {
    maintainers = with lib.maintainers; [ ];
    doc = ./README.md;
  };
}