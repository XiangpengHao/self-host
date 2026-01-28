# Clawdbot/Moltbot service module - AI assistant gateway with Telegram integration
# Supports OAuth login for OpenAI/Anthropic via `moltbot onboard`
{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.clawdbot;
  clawdbotPkg = pkgs.clawdbot;
in
{
  options.services.clawdbot = {
    enable = mkEnableOption "Clawdbot AI assistant gateway";

    telegramBotTokenFile = mkOption {
      type = types.path;
      description = "Path to file containing Telegram bot token";
    };

    telegramAllowedUsers = mkOption {
      type = types.listOf types.int;
      description = "List of Telegram user IDs allowed to interact with the bot";
      example = [ 123456789 ];
    };

    workspaceDir = mkOption {
      type = types.str;
      default = "/var/lib/clawdbot/workspace";
      description = "Directory for clawdbot workspace";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/clawdbot";
      description = "Directory for clawdbot state and config";
    };
  };

  config = mkIf cfg.enable {
    # Add clawdbot overlay for the package
    # (overlay is added in flake.nix)

    # Create dedicated user for clawdbot
    users.users.clawdbot = {
      isSystemUser = true;
      group = "clawdbot";
      home = cfg.stateDir;
      createHome = true;
      description = "Clawdbot service user";
      shell = pkgs.bash;
    };
    users.groups.clawdbot = { };

    # Ensure directories exist
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 clawdbot clawdbot -"
      "d ${cfg.stateDir}/.clawdbot 0750 clawdbot clawdbot -"
      "d ${cfg.workspaceDir} 0750 clawdbot clawdbot -"
    ];

    # Systemd service for moltbot gateway
    systemd.services.clawdbot-gateway = {
      description = "Clawdbot/Moltbot AI Gateway";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      environment = {
        HOME = cfg.stateDir;
        XDG_CONFIG_HOME = "${cfg.stateDir}/.config";
        XDG_DATA_HOME = "${cfg.stateDir}/.local/share";
        XDG_STATE_HOME = "${cfg.stateDir}/.local/state";
      };

      serviceConfig = {
        Type = "simple";
        User = "clawdbot";
        Group = "clawdbot";
        WorkingDirectory = cfg.workspaceDir;
        Restart = "on-failure";
        RestartSec = "10s";

        # Read Telegram token from file
        LoadCredential = "telegram-bot-token:${cfg.telegramBotTokenFile}";
      };

      # Set TELEGRAM_BOT_TOKEN from the credential file
      script = ''
        export TELEGRAM_BOT_TOKEN="$(cat $CREDENTIALS_DIRECTORY/telegram-bot-token)"
        exec ${clawdbotPkg}/bin/moltbot gateway
      '';
    };

    # Helper script to run onboard as clawdbot user
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "clawdbot-onboard" ''
        sudo -u clawdbot -i ${clawdbotPkg}/bin/moltbot onboard "$@"
      '')
    ];
  };
}
