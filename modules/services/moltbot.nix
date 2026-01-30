# Moltbot - AI assistant gateway with Telegram integration
# https://github.com/moltbot/moltbot
# https://github.com/moltbot/nix-moltbot
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.moltbot;

  # Generate the moltbot configuration JSON
  moltbotConfig = pkgs.writeText "moltbot.json" (builtins.toJSON {
    agent = {
      model = cfg.llmModel;
    };
    providers = {
      telegram = {
        enable = true;
        allowFrom = cfg.telegramAllowedUsers;
      };
    };
  });
in
{
  options.services.moltbot = {
    enable = mkEnableOption "Moltbot AI assistant gateway";

    telegramBotTokenFile = mkOption {
      type = types.path;
      description = "Path to file containing the Telegram bot token";
    };

    telegramAllowedUsers = mkOption {
      type = types.listOf types.int;
      default = [ ];
      description = "List of Telegram user IDs allowed to interact with the bot";
    };

    llmModel = mkOption {
      type = types.str;
      default = "openai/codex";
      description = "LLM model to use (e.g., openai/codex, openai/gpt-4, anthropic/claude-opus-4-5)";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/moltbot";
      description = "Directory for moltbot state and workspace (OAuth tokens stored here)";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall for the gateway port (18789)";
    };

    package = mkOption {
      type = types.package;
      default = inputs.nix-moltbot.packages.${pkgs.system}.moltbot-gateway;
      description = "The moltbot-gateway package to use";
    };
  };

  config = mkIf cfg.enable {
    users.users.moltbot = {
      isSystemUser = true;
      group = "moltbot";
      home = cfg.dataDir;
    };
    users.groups.moltbot = { };

    # Ensure data directories exist with correct permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 moltbot moltbot -"
      "d ${cfg.dataDir}/workspace 0755 moltbot moltbot -"
    ];

    systemd.services.moltbot = {
      description = "Moltbot AI Assistant Gateway";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = "moltbot";
        Group = "moltbot";
        StateDirectory = "moltbot";
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        RestartSec = 10;

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [ cfg.dataDir ];
      };

      environment = {
        HOME = cfg.dataDir;
        MOLTBOT_CONFIG = "${moltbotConfig}";
        MOLTBOT_STATE_DIR = cfg.dataDir;
        MOLTBOT_WORKSPACE_DIR = "${cfg.dataDir}/workspace";
      };

      script = ''
        export TELEGRAM_BOT_TOKEN="$(cat ${cfg.telegramBotTokenFile})"
        exec ${cfg.package}/bin/moltbot-gateway
      '';
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 18789 ];
  };
}
