# Cloudflare DDNS service module
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cloudflare-ddns;
in
{
  options.services.cloudflare-ddns = {
    enable = mkEnableOption "Cloudflare DDNS updater";

    domains = mkOption {
      type = types.listOf types.str;
      description = "List of domains/subdomains to update";
      example = [ "example.com" "sub.example.com" ];
    };

    apiTokenFile = mkOption {
      type = types.path;
      description = "Path to file containing Cloudflare API token";
    };

    ipv4 = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to update IPv4 (A) records";
    };

    ipv6 = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to update IPv6 (AAAA) records";
    };

    frequency = mkOption {
      type = types.str;
      default = "*:0/5";
      description = "How often to check/update (systemd OnCalendar format)";
      example = "*:0/15"; # every 15 minutes
    };
  };

  config = mkIf cfg.enable {
    services.cloudflare-dyndns = {
      enable = true;
      domains = cfg.domains;
      apiTokenFile = cfg.apiTokenFile;
      ipv4 = cfg.ipv4;
      ipv6 = cfg.ipv6;
    };

    # Override the default timer frequency
    systemd.timers.cloudflare-dyndns.timerConfig.OnCalendar = mkForce cfg.frequency;
  };
}
