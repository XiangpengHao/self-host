# Host-specific configuration for nixnas
{ config, lib, pkgs, inputs, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/sops.nix
    ../../modules/services/uptime-kuma.nix
    ../../modules/services/related-work.nix
  ];

  # Sops secrets for this host
  sops.secrets = {
    "openrouter-api-key" = { };
  };

  # Enable Uptime Kuma
  services.uptime-kuma-custom = {
    enable = true;
    port = 3001;
    openFirewall = true;
  };

  # Enable Related Work - academic paper browser
  services.related-work = {
    enable = true;
    port = 8080;
    dataDir = "/var/lib/related-work/data";
    openRouterApiKeyFile = config.sops.secrets."openrouter-api-key".path;
    openFirewall = true;
  };

  # Boot configuration (adjust for your hardware)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network configuration
  networking = {
    useDHCP = true;
    firewall.allowedTCPPorts = [ 22 ];
  };
}
