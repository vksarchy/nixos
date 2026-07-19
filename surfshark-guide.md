# Surfshark VPN on NixOS — from scratch

How to add a toggleable Surfshark VPN to any NixOS host using WireGuard + agenix secrets. No proprietary client, no manual config files lying around.

---

## 1. How it works (architecture)

```
Surfshark website           Your NixOS flake
┌─────────────────┐        ┌──────────────────────────┐
│ gives you:      │        │                          │
│  private key ───┼─encrypt→ agenix → secrets/        │
│  public key  ───┼─Nix───→ modules/surfshark.nix     │
│  endpoint    ───┼─Nix───→ device config             │
└─────────────────┘        │         ↓                │
                           │  networking.wireguard    │
                           │  systemd.network (DNS)   │
                           │         ↓                │
                           │  wg-surfshark interface  │
                           └──────────────────────────┘
```

- **WireGuard** handles the tunnel — NixOS has it built-in
- **agenix** handles the private key — encrypted at rest, decrypted at boot via SSH host key
- **Module toggle** (`workstation.surfshark.enable`) — flip on/off, rebuild, done

---

## 2. Prerequisites

Your flake needs agenix imported. In `flake.nix`:

```nix
inputs.agenix.url = "github:ryantm/agenix";
inputs.agenix.inputs.nixpkgs.follows = "nixpkgs-stable";

# In your mkSystem/mkWorkstation function:
agenix.nixosModules.default
```

If agenix wasn't already set up, you'd also need:
```nix
# In the NixOS config:
age.identityPaths = [ "/home/sid/.ssh/agenix_sid" ];  # for CLI usage
```

---

## 3. Step-by-step

### Step 1 — Get Surfshark WireGuard credentials

Go to https://my.surfshark.com/vpn/manual-setup → **WireGuard** → pick a server → generate.

You get three values:

| Field | Secret? | Where it goes |
|---|---|---|
| Private key | **Yes** | agenix (encrypted) |
| Public key | No | Nix module (plain text) |
| Endpoint | No | Nix module (plain text) |

---

### Step 2 — Create the secrets registry

**`secrets/secrets.nix`** is a whitelist. It says "this .age file can be decrypted by these machines".

Your machines are identified by their **SSH host public key** (from `/etc/ssh/ssh_host_ed25519_key.pub`).

```nix
# secrets/secrets.nix
let
  prometheus = "ssh-ed25519 AAAAC3Nza... sid@prometheus";
  erebos    = "ssh-ed25519 AAAAC3Nza... sid@erebos";
  workstations = [ prometheus erebos ];
in {
  "secrets/surfshark-key.age".publicKeys = workstations;
  #       ↑ full path — agenix uses this as lookup key
}
```

If you run `agenix` from the repo root, agenix looks for `./secrets.nix`. If yours lives at `secrets/secrets.nix`, create a bridge:

```nix
# secrets.nix (repo root)
import ./secrets/secrets.nix
```

---

### Step 3 — Encrypt the private key

From the repo root (`/home/sid/nixos`):

```bash
agenix -e secrets/surfshark-key.age
```

Your `$EDITOR` opens. Paste the **private key only** — one line, no quotes. Save and exit. agenix encrypts it against all public keys listed in `secrets.nix`.

The encrypted file is now at `secrets/surfshark-key.age`. It can only be decrypted by machines whose SSH host keys are in the whitelist.

---

### Step 4 — Create the NixOS module

**`modules/surfshark.nix`**:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.workstation.surfshark;
in {
  options.workstation.surfshark = {
    enable = lib.mkEnableOption "Surfshark VPN via WireGuard";

    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to agenix-decrypted private key";
    };

    endpoint = lib.mkOption {
      type = lib.types.str;
      example = "sg-sng.prod.surfshark.com:51820";
    };

    serverPublicKey = lib.mkOption {
      type = lib.types.str;
    };

    address = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.14.0.2/16" ];
    };

    dns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "162.252.172.57" "149.154.159.92" ];
    };
  };

  config = lib.mkIf cfg.enable {
    # — WireGuard tunnel —
    networking.wireguard.interfaces.wg-surfshark = {
      ips = cfg.address;
      privateKeyFile = cfg.privateKeyFile;
      peers = [{
        publicKey = cfg.serverPublicKey;
        allowedIPs = [ "0.0.0.0/0" ];   # route all traffic through VPN
        endpoint = cfg.endpoint;
        persistentKeepalive = 25;
      }];
    };

    # — Push DNS through the VPN interface —
    systemd.network.networks."50-wg-surfshark" = {
      matchConfig.Name = "wg-surfshark";
      networkConfig = {
        DNS = cfg.dns;
        Domains = "~.";                    # prefer this DNS for all queries
      };
    };
  };
}
```

Key points:
- `lib.mkIf cfg.enable` — everything inside only applies when `enable = true`
- `allowedIPs = [ "0.0.0.0/0" ]` — full tunnel (all traffic through VPN)
- `Domains = "~."` — routes all DNS queries to Surfshark's DNS (prevents leaks)
- `persistentKeepalive = 25` — keeps NAT alive so you stay connected

---

### Step 5 — Wire it into a device config

In your device config (e.g. `devices/laptop/prometheus/default.nix`):

```nix
{
  imports = [
    ../../../modules/surfshark.nix    # ← import the module
    # ... other imports
  ];

  # Tell agenix where the encrypted file lives
  age.secrets."surfshark-key.age" = {
    file = ../../../secrets/surfshark-key.age;
    owner = "root";      # WireGuard runs as root
    group = "root";
    mode = "0400";
  };

  # Enable and configure
  workstation.surfshark = {
    enable = true;
    privateKeyFile = "/run/agenix/surfshark-key.age";
    endpoint = "sg-sng.prod.surfshark.com:51820";
    serverPublicKey = "MGfgkhJsMVMTO33h1wr76+z6gQr/93VcGdClfbaPsnU=";
  };
}
```

---

### Step 6 — Rebuild and verify

```bash
sudo nixos-rebuild switch --flake /home/sid/nixos#prometheus
```

Check it worked:

```bash
# Should show Singapore IP (or whatever server you picked)
curl ifconfig.me

# Check the interface is up
ip a show wg-surfshark

# Check wg status
sudo wg show
```

---

## 4. Daily usage

| Action | What to do |
|---|---|
| **Enable VPN** | Set `enable = true`, rebuild |
| **Disable VPN** | Set `enable = false`, rebuild |
| **Change server** | Update `endpoint` and `serverPublicKey`, rebuild |
| **Add a host** | Get its SSH host pubkey, add to `secrets.nix`, rekey the secret |

---

## 5. How agenix decrypts at boot

```
Boot
  │
  ├─ agenix systemd service starts
  │   reads /etc/ssh/ssh_host_ed25519_key (host's private key)
  │   decrypts secrets/*.age → /run/agenix/* (tmpfs, cleared on reboot)
  │
  ├─ systemd waits for agenix to finish
  │
  └─ WireGuard service starts
      reads /run/agenix/surfshark-key.age
      brings up wg-surfshark
```

At boot, the machine uses its own SSH host key to decrypt the secret. No manual intervention, no password prompts. The decrypted key lives only in RAM (`/run` is tmpfs).

---

## 6. Cleanup

```bash
# Delete the plaintext config file — your private key is in it
rm ~/Downloads/sg-sng.conf

# Commit the encrypted .age file (it's safe — only your machines can decrypt)
git add secrets/surfshark-key.age

# Don't commit the private key! The .age file is the encrypted version.
```

---

## Files changed (summary)

| File | Purpose |
|---|---|
| `secrets.nix` | Bridge to `secrets/secrets.nix` (agenix needs this at repo root) |
| `secrets/secrets.nix` | Whitelist — which machines can decrypt `surfshark-key.age` |
| `secrets/surfshark-key.age` | Encrypted private key (safe to commit) |
| `modules/surfshark.nix` | Toggle module — WireGuard interface + DNS |
| `devices/.../default.nix` | Import module + agenix secret + enable toggle |
