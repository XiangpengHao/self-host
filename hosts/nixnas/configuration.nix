# Host-specific configuration for nixnas
{
  config,
  lib,
  pkgs,
  inputs,
  hostname,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/sops.nix
    ../../modules/services/uptime-kuma.nix
    ../../modules/services/related-work.nix
    ../../modules/services/cloudflare-ddns.nix
    ../../modules/services/moltbot.nix
  ];

  # Sops secrets for this host
  sops.secrets = {
    "openrouter-api-key" = {
      owner = "related-work";
      group = "related-work";
    };
    "cloudflare-api-token" = { };
    "telegram-bot-token" = {
      owner = "moltbot";
      group = "moltbot";
    };
  };

  # Enable Uptime Kuma
  services.uptime-kuma-custom = {
    enable = true;
    port = 3001;
    openFirewall = false;
  };

  # Enable Related Work - academic paper browser
  services.related-work = {
    enable = true;
    port = 8080;
    openRouterApiKeyFile = config.sops.secrets."openrouter-api-key".path;
    openFirewall = false;
  };

  # Public HTTPS reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts."related-work.xiangpeng.systems" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:8080
      '';
    };
  };

  # Moltbot - AI assistant with Telegram integration
  # Note: OpenAI uses OAuth login - run `moltbot onboard` to authenticate
  services.moltbot = {
    enable = true;
    telegramBotTokenFile = config.sops.secrets."telegram-bot-token".path;
    telegramAllowedUsers = [ 132580810 ];
    llmModel = "openai/codex";
    openFirewall = false;
  };

  # Cloudflare DDNS - keeps DNS records updated with dynamic IP
  services.cloudflare-ddns = {
    enable = true;
    domains = [ "related-work.xiangpeng.systems" ];
    apiTokenFile = config.sops.secrets."cloudflare-api-token".path;
  };

  # Boot configuration (adjust for your hardware)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network configuration
  networking = {
    useDHCP = true;
    firewall = {
      allowedTCPPorts = [
        22
        80
        443
      ];
      interfaces.tailscale0.allowedTCPPorts = [ 3001 ];
    };
  };
}
