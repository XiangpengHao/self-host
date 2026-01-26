# Related Work - Academic paper search/browse application
# https://github.com/XiangpengHao/related-work
{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.related-work;
in
{
  options.services.related-work = {
    enable = mkEnableOption "Related Work academic paper browser";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port for the web application";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/related-work/data";
      description = "Directory containing the paper data (Parquet files)";
    };

    openRouterApiKeyFile = mkOption {
      type = types.path;
      description = "Path to file containing OPENROUTER_API_KEY";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall for the web application port";
    };

    package = mkOption {
      type = types.package;
      default = inputs.related-work.packages.${pkgs.system}.server;
      description = "The related-work package to use";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.related-work = {
      description = "Related Work - Academic Paper Browser";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        StateDirectory = "related-work";
        Restart = "on-failure";
        RestartSec = 5;

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadOnlyPaths = [ cfg.dataDir ];
      };

      environment = {
        IP = "0.0.0.0";
        PORT = toString cfg.port;
        DATA_DIR = cfg.dataDir;
      };

      script = ''
        export OPENROUTER_API_KEY="$(cat ${cfg.openRouterApiKeyFile})"
        exec ${cfg.package}/bin/related-work
      '';
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
