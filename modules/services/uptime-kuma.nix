# Uptime Kuma - Self-hosted monitoring tool
# Thin wrapper around the built-in NixOS module
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.uptime-kuma-custom;
in
{
  options.services.uptime-kuma-custom = {
    enable = mkEnableOption "Uptime Kuma monitoring service";

    port = mkOption {
      type = types.port;
      default = 3001;
      description = "Port for Uptime Kuma to listen on";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall for Uptime Kuma port";
    };
  };

  config = mkIf cfg.enable {
    # Use the built-in NixOS uptime-kuma service
    services.uptime-kuma = {
      enable = true;
      settings = {
        PORT = toString cfg.port;
        HOST = "0.0.0.0";
      };
    };

    # Optionally open firewall
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
