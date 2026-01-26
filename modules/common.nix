# Common configuration shared across all hosts
{ config, lib, pkgs, hostname, ... }:

{
  networking.hostName = hostname;

  # Enable flakes
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Allow the wheel group to manage nix
    trusted-users = [ "root" "@wheel" ];
    # Cachix binary cache
    substituters = [
      "https://cache.nixos.org"
      "https://xiangpeng.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "xiangpeng.cachix.org-1:ZmNrfIhNF9o/1F06sov5aNzGmKDv+4N0QEUgXHr0hh8="
    ];
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    age
    sops
  ];

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Firewall defaults
  networking.firewall.enable = true;

  # Timezone
  time.timeZone = "UTC";

  # Shared user configuration
  users.users.hao = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINo3/3dfsnQvaFW+hG63w+rOmngogaXtzYoi3/rbOdD6"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZ48C66n+ufpKM3jVhby+eUBE4ZmiEc1Xa1nGOVJIAa"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWHg5wa4nzGfoupxbYPnbspSBg45ETQYQUlYwYCi7v7"
    ];
  };

  system.stateVersion = "24.11";
}
