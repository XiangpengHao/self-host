# Self-Hosted Cloud

Self-host everything.

- Support open source.
- Digital independence.
- Privacy.

Features:

1. Fully declaritive, deterministic. No need to remember any command.
2. Easy secrets management.
3. One command to deploy the full OS.

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

## Deployment

On each host:

```bash
cd /path/to/self-host
git pull
sudo nixos-rebuild switch --flake .#hostA
```
