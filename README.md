# Self-Hosted Infrastructure

Declarative NixOS infrastructure with per-host secrets using sops-nix and age.

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

## Initial Setup

### 1. Generate Admin Age Key

On your workstation:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Copy the public key (starts with `age1...`) to `.sops.yaml` under `&admin`.

### 2. Get Host Age Key

For each host, derive the age public key from SSH:

```bash
# From remote
ssh-keyscan hostA | ssh-to-age

# Or locally on the host
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
```

Add the key to `.sops.yaml` under the appropriate anchor (e.g., `&hostA`).

### 3. Create Secrets File

```bash
sops secrets/hostA.yaml
```

Example secrets structure:

```yaml
api-key: supersecretkey
database:
  password: dbpassword
```

### 4. Reference Secrets in NixOS

In your host configuration:

```nix
sops.secrets."api-key" = {
  owner = "myservice";
  mode = "0400";
};

sops.secrets."database/password" = { };
```

Secrets are available at `/run/secrets/<name>`.

## Deployment

On each host:

```bash
cd /path/to/self-host
git pull
sudo nixos-rebuild switch --flake .#hostA
```

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

## Services

### Uptime Kuma

Monitoring service running on port 3001.

Access: `http://hostA:3001`

Configuration options:
- `services.uptime-kuma-custom.enable` - Enable the service
- `services.uptime-kuma-custom.port` - Port (default: 3001)
- `services.uptime-kuma-custom.openFirewall` - Open firewall port
