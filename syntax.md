Here's the complete pattern — module definition and how to call it from a host.

**The module file** (`modules/myfeature.nix`):

```nix
{ config, pkgs, lib, ... }:
let
  cfg = config.workstation.myfeature;
in
{
  # 1. Declare the options
  options.workstation.myfeature = {
    enable = lib.mkEnableOption "my feature description";

    # Optional: additional options with types
    someValue = lib.mkOption {
      type = lib.types.str;
      default = "defaultvalue";
      description = "What this controls";
    };

    someFlag = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable some sub-behaviour";
    };
  };

  # 2. Apply config only when enabled
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sometool
    ];

    services.someservice = {
      enable = true;
      setting = cfg.someValue;     # reference your option
    };

    # Conditionally apply sub-config based on another option
    programs.something.enable = lib.mkIf cfg.someFlag true;
  };
}
```

**The host** (`devices/desktop/mymachine/default.nix`):

```nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/baseline.nix
    ../../../modules/myfeature.nix    # ← import it
  ];

  workstation.baseline.enable = true;

  # Enable your module and set options
  workstation.myfeature = {
    enable = true;
    someValue = "customvalue";
    someFlag = true;
  };
}
```

The key rules from your config's own patterns:

- Options always live under `workstation.*` (or a custom namespace like `mount.*` for mount.nix)
- `lib.mkEnableOption` declares the boolean toggle — it defaults to `false`, so importing the module never activates it
- `lib.mkIf cfg.enable { ... }` wraps the entire config block — nothing applies unless you set `enable = true` in the host
- The module must be in the `imports` list of the device's `default.nix` *and* have its option set — both are required

Your `ssh.nix` in the project files is a clean real example of exactly this pattern you can reference directly.

---

## HERMES SYNTAX 
Let me check your project files to understand the current structure before answering.Good — I have everything needed. Here's the full picture adapted to your flake's exact patterns.

---

## Step 1 — Add the input to `flake.nix`

Hermes exports `nixosModules.default` which you wire in as a flake input. In your `flake.nix`, alongside your existing inputs:

```nix
inputs = {
  nixpkgs-unstable.url  = "github:nixos/nixpkgs/nixos-unstable";
  # ... all your existing inputs ...

  hermes-agent.url = "github:NousResearch/hermes-agent";
  hermes-agent.inputs.nixpkgs.follows = "nixpkgs-unstable";  # share your nixpkgs
};
```

Then pass it through `mkWorkstation` via `extraModules` (already supported in your builder):

```nix
erebos = mkWorkstation {
  hostname    = "erebos";
  system      = "x86_64-linux";
  homeFile    = ./home/niri.nix;
  extraModules = [
    inputs.hermes-agent.nixosModules.default  # ← add this
  ];
};
```

---

## Step 2 — Write the module (`modules/hermes.nix`)

This follows the exact same `lib.mkEnableOption` / `lib.mkIf` pattern your repo already uses everywhere:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.workstation.hermes;
in
{
  options.workstation.hermes = {
    enable = lib.mkEnableOption "Hermes AI agent";

    model = lib.mkOption {
      type    = lib.types.str;
      default = "anthropic/claude-sonnet-4-5";
      description = "Default LLM model for Hermes to use";
    };

    addToCli = lib.mkOption {
      type    = lib.types.bool;
      default = true;
      description = "Put hermes CLI on system PATH and share state with the service";
    };

    container = lib.mkOption {
      type    = lib.types.bool;
      default = false;
      description = "Run Hermes in an Ubuntu container (allows apt/pip installs by the agent)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.hermes-agent = {
      enable             = true;
      addToSystemPackages = cfg.addToCli;
      settings.model.default = cfg.model;

      # Point at the agenix-decrypted secret (see Step 3)
      environmentFiles = [ config.age.secrets."hermes-env".path ];

      container.enable   = cfg.container;
      # If container mode: share state with your user
      container.hostUsers = lib.optionals cfg.container [ "sid" ];
    };
  };
}
```

---

## Step 3 — Add the secret with agenix

Since you already use agenix, this fits naturally. The secret file holds your API key(s):

```bash
# 1. Add to secrets/secrets.nix
let
  erebos = "ssh-ed25519 AAAA...";   # your desktop host key
  prometheus = "ssh-ed25519 AAAA...";
in {
  # existing secrets...
  "hermes-env.age".publicKeys = [ erebos prometheus ];  # whichever machines need it
}

# 2. Encrypt it (the file contents are env vars, one per line)
cd secrets
agenix -e hermes-env.age
# Type inside the editor:
# OPENROUTER_API_KEY=sk-or-...
# or ANTHROPIC_API_KEY=sk-ant-...
```

Then in your device config (`devices/desktop/erebos/default.nix`):

```nix
age.secrets."hermes-env" = {
  file  = ../../../secrets/hermes-env.age;
  owner = "hermes";   # the user the service runs as
  group = "hermes";
  mode  = "0400";
};
```

---

## Step 4 — Enable it in your device config

```nix
# devices/desktop/erebos/default.nix
imports = [
  ./hardware-configuration.nix
  ../../../modules/baseline.nix
  ../../../modules/hermes.nix     # ← add this
  # ... rest of your imports
];

workstation.hermes = {
  enable  = true;
  model   = "anthropic/claude-sonnet-4-5";
  addToCli = true;
  container = false;   # true if you want the Ubuntu sandbox mode
};

age.secrets."hermes-env" = {
  file  = ../../../secrets/hermes-env.age;
  owner = "hermes";
  group = "hermes";
  mode  = "0400";
};
```

---

## Step 5 — Build and verify

```bash
# Dry run first
nixos-rebuild dry-build --flake .#erebos

# Apply
sudo nixos-rebuild switch --flake .#erebos

# Verify
systemctl status hermes-agent
journalctl -u hermes-agent -f

hermes version
hermes config
```

---

## Quick decision: native vs container mode

The native mode runs as a hardened systemd service with `NoNewPrivileges`, `ProtectSystem=strict`, `PrivateTmp`. The container mode runs Hermes inside a persistent Ubuntu container where the agent can `apt`/`pip`/`npm install` freely.

For a workstation like erebos where you just want the agent available, `container = false` is fine. Set `container = true` only if you want the agent to be able to install its own tools at runtime.

One important note: when `addToSystemPackages = true`, running `hermes` in your shell shares state (sessions, skills, cron) with the gateway service via `HERMES_HOME`. Without it, your shell creates a separate `~/.hermes/` directory disconnected from the service. So keep `addToCli = true` unless you specifically want isolation.
