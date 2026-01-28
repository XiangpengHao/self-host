## Repository Structure

```
.
├── flake.nix              # Main flake with host definitions
├── .sops.yaml             # Sops encryption rules
├── hosts/
│   └── hostA/
│       ├── configuration.nix
│       └── hardware-configuration.nix
├── modules/
│   ├── common.nix         # Shared configuration
│   ├── sops.nix           # Sops-nix setup
│   └── services/
│       └── uptime-kuma.nix
└── secrets/
    └── hostA.yaml         # Encrypted secrets for hostA
```

### Reference Secrets in NixOS

In your host configuration:

```nix
sops.secrets."api-key" = {
  owner = "myservice";
  mode = "0400";
};

sops.secrets."database/password" = { };
```

Secrets are available at `/run/secrets/<name>`.

## Adding a New Host

1. Create `hosts/<hostname>/configuration.nix` and `hardware-configuration.nix`
2. Add to `flake.nix`:
    ```nix
    hostB = mkHost { hostname = "hostB"; };
    ```
3. Get the host's age key and add to `.sops.yaml`
4. Add creation rule for `secrets/<hostname>.yaml`
5. Create encrypted secrets: `sops secrets/<hostname>.yaml`

## Adding a New Service

1. Create module in `modules/services/<service>.nix`
2. Import in relevant host configurations
3. Add any required secrets to the host's secrets file
