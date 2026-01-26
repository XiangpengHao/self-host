# Sops-nix configuration for per-host secrets
{ config, lib, pkgs, hostname, ... }:

{
  sops = {
    # Each host has its own age key derived from SSH host key
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # Default secrets file for this host
    defaultSopsFile = ../secrets/${hostname}.yaml;

    # Secrets are decrypted to /run/secrets by default
    # They're owned by root:root with mode 0400
  };
}
