# NixOS Flake Deep-Dive: Teaching Guide for Sid's Configuration

> **Target audience**: Someone who knows basic Nix syntax (attribute sets, functions, `with`) but wants to understand how a real-world flake orchestrates multiple machines.
>
> **Goal**: After reading this, you should be able to explain every line of `flake.nix` and trace how a `nixos-rebuild switch --flake .#prometheus` command flows through the entire codebase.

---

## Table of Contents

1. [The Flake File Itself](#1-the-flake-file-itself)
2. [Inputs — Your Dependency Manifest](#2-inputs--your-dependency-manifest)
3. [The Outputs Function](#3-the-outputs-function)
4. [mkWorkstation and mkServer — Factory Functions](#4-mkworkstation-and-mkserver--factory-functions)
5. [How Modules Work](#5-how-modules-work)
6. [How hostName Travels Through the System](#6-how-hostname-travels-through-the-system)
7. [Full Trace: `nixos-rebuild switch --flake .#prometheus`](#7-full-trace-nixos-rebuild-switch---flake-prometheus)
8. [Q&A — Common Confusions](#8-qa--common-confusions)
9. [Visual Map of the Entire Codebase](#9-visual-map-of-the-entire-codebase)

---

## 1. The Flake File Itself

The file `/home/sid/nixos/flake.nix` is the **entry point**. When you run `nixos-rebuild switch --flake /home/sid/nixos#prometheus`, Nix reads this file and expects to find:

```nix
{
  description = "...";
  inputs = { ... };
  outputs = { ... };
}
```

This is the **flake schema**. Every flake has exactly these three top-level attributes.

### `description`
A human-readable string. Appears in `nix flake metadata`. Purely cosmetic.

### `inputs`
Where you declare **other flakes** this flake depends on. Nix downloads them, evaluates them, and passes their outputs to your `outputs` function.

### `outputs`
A **function** that receives the evaluated inputs and returns what this flake **produces**. For NixOS configs, the key output is `nixosConfigurations.<hostname>`.

**Every device you can `nixos-rebuild switch` to must appear as a key inside `nixosConfigurations`.**

---

## 2. Inputs — Your Dependency Manifest

```nix
inputs = {
  nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs-stable.url  = "github:nixos/nixpkgs/nixos-25.11";

  home-managerU = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  home-managerS = {
    url = "github:nix-community/home-manager/release-25.11";
    inputs.nixpkgs.follows = "nixpkgs-stable";
  };

  agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs-stable";
  };

  nixvim = {
    url = "github:nix-community/nixvim";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  hermes-agent = {
    url = "github:NousResearch/hermes-agent";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";
  disko.url = "github:nix-community/disko";
  disko.inputs.nixpkgs.follows = "nixpkgs-stable";

  noctalia.url = "github:noctalia-dev/noctalia-shell/";
  noctalia.inputs.nixpkgs.follows = "nixpkgs-unstable";

  nixard.url = "github:manelinux/nixard";
  nixard.inputs.nixpkgs.follows = "nixpkgs-unstable";
};
```

### What Each Input Is

| Input              | What It Provides                                | Why Two Versions?              |
|--------------------|-------------------------------------------------|--------------------------------|
| `nixpkgs-unstable` | Rolling-release package set (latest everything) | Workstations get bleeding-edge |
| `nixpkgs-stable`   | Pinned stable release (nixos-25.11)             | Servers get stability          |
| `home-managerU`    | Home Manager linked to unstable nixpkgs         | Workstation user configs       |
| `home-managerS`    | Home Manager linked to stable nixpkgs           | Server user configs            |
| `agenix`           | Secret decryption at boot (age-encrypted files) | Shared across both             |
| `nixvim`           | Declarative Neovim config as a NixOS module     | Workstations only              |
| `hermes-agent`     | This AI agent, packaged as a Nix flake          | Workstations only              |
| `nixard`           | Nix ASCII art dashboard tool                    | Workstations only              |
| `flatpaks`         | Declarative Flatpak management                  | Workstations only              |
| `disko`            | Declarative disk partitioning                   | Servers only                   |
| `noctalia`         | Custom shell theme/environment                  | Workstations only              |

### The `follows` Mechanism — CRITICAL Concept

```nix
home-managerU = {
  url = "github:nix-community/home-manager";
  inputs.nixpkgs.follows = "nixpkgs-unstable";
};
```

**Without `follows`**: `home-manager` has its OWN `nixpkgs` input. Nix would download a SEPARATE copy of nixpkgs for home-manager. Result: two copies of nixpkgs in your store, and possibly version mismatches.

**With `follows`**: The `home-manager` flake's `nixpkgs` input is REPLACED by YOUR `nixpkgs-unstable` input. They share the same nixpkgs. This is:

1. **Faster** — no duplicate download
2. **Consistent** — everything uses the same package versions
3. **Smaller closure** — fewer store paths

**Rule of thumb**: Almost every flake input that depends on nixpkgs should use `follows` to point at your nixpkgs. You have two nixpkgs (stable and unstable) and route each dependency to the appropriate one.

### Short-form vs Long-form Input Declaration

Short form (when you only need `url`):
```nix
flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";
```

Long form (when you also need `follows` or other overrides):
```nix
agenix = {
  url = "github:ryantm/agenix";
  inputs.nixpkgs.follows = "nixpkgs-stable";
};
```

Both are equivalent — the long form is just an attribute set with more keys.

---

## 3. The Outputs Function

```nix
outputs =
  {
    self,
    nixpkgs-unstable,
    nixpkgs-stable,
    home-managerU,
    home-managerS,
    noctalia,
    agenix,
    nixvim,
    flatpaks,
    disko,
    hermes-agent,
    nixard,
    ...
  }@inputs:
  let
    system = "x86_64-linux";
    libU = nixpkgs-unstable.lib;
    libS = nixpkgs-stable.lib;

    mkWorkstation = { deviceModule, hmImports }: ...;
    mkServer      = { deviceModule, hmImports }: ...;
  in
  {
    nixosConfigurations = {
      erebos     = mkWorkstation { ... };
      prometheus = mkWorkstation { ... };
      null       = mkWorkstation { ... };
      steamos    = mkWorkstation { ... };
      void       = mkServer { ... };
      v-gaia-main = mkServer { ... };
      zeus       = mkServer { ... };
    };
  };
```

### Breaking Down the Destructuring

```nix
{ self, nixpkgs-unstable, ..., ... }@inputs:
```

This is Nix function destructuring with the `@` pattern:

- `{ self, nixpkgs-unstable, ... }` — Destructures the input attribute set, pulling out named fields.
- `...` — Absorbs all remaining inputs you didn't name explicitly (in this case, none remain since you named them all above).
- `@inputs` — Binds the ENTIRE original attribute set to the name `inputs`. So `inputs` = `{ self, nixpkgs-unstable, nixpkgs-stable, ... }`.

**Why capture `inputs`?** Because `mkWorkstation` passes `inputs` via `specialArgs` to all modules, so any module can access any input flake. For example, `nixvim.nix` uses `inputs.nixvim.nixosModules.nixvim`.

### `self`

`self` is the flake itself — a self-reference. Not heavily used in this config, but always present. It lets the flake reference its own outputs (e.g., for overlays or checks).

### `system`

```nix
system = "x86_64-linux";
```

A constant. All machines in this config are x86_64 Linux. If you added an ARM machine (like an Apple Silicon Mac or Raspberry Pi), you'd need `system = "aarch64-linux"` for those entries. Many flakes use `system` from the function args directly instead of hardcoding it.

### `libU` and `libS`

```nix
libU = nixpkgs-unstable.lib;
libS = nixpkgs-stable.lib;
```

Short aliases. `lib` is the Nixpkgs standard library — provides `mkIf`, `mkEnableOption`, `mkOption`, `optionals`, and hundreds of other helpers. Stable vs. unstable libs are usually identical, but keeping them separate follows the two-channel split.

### The `let ... in` Block

```nix
let
  mkWorkstation = ...;
  mkServer = ...;
in
{
  nixosConfigurations = { ... };
}
```

`let` defines local bindings. `mkWorkstation` and `mkServer` are **helper functions** defined in this scope. After defining them in `let`, you use them inside the `in` block to build each machine's configuration.

---

## 4. `mkWorkstation` and `mkServer` — Factory Functions

These are the heart of the flake. They're **higher-order functions**: they take a device module and return a fully-assembled `nixosSystem` call.

### `mkWorkstation`

```nix
mkWorkstation =
  { deviceModule, hmImports }:
  libU.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [
      deviceModule
      home-managerU.nixosModules.home-manager
      flatpaks.nixosModules.default
      agenix.nixosModules.default
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = { inherit inputs; };
          sharedModules = [
            ({ osConfig, ... }: {
              _module.args.hostName = osConfig.networking.hostName;
            })
          ];
          users.sid = {
            imports = hmImports;
          };
        };
      }
    ];
  };
```

Let's tear this apart:

#### Function Signature

```nix
{ deviceModule, hmImports }:
```

Takes an attribute set with two keys:
- `deviceModule` — Path to the device's `default.nix` (e.g., `./devices/laptop/prometheus/default.nix`)
- `hmImports` — List of home-manager module paths (e.g., `[ ./home/common.nix ./home/zsh.nix ./home/niri.nix ]`)

#### `libU.nixosSystem`

This is THE function that creates a NixOS configuration. Arguments:

| Argument | What It Does |
|----------|-------------|
| `system` | `"x86_64-linux"` — target CPU architecture |
| `specialArgs` | Extra arguments injected into EVERY module's function parameters |
| `modules` | List of NixOS modules that define the system |

#### `specialArgs = { inherit inputs; }`

**This is how every module gets access to the flake inputs.** Without this, a module like `nixvim.nix` wouldn't have `inputs` in its scope and couldn't do:

```nix
imports = [
  inputs.nixvim.nixosModules.nixvim
];
```

`inherit inputs;` is sugar for `inputs = inputs;` — it copies a variable with the same name.

#### The Modules List

The `modules` list builds a NixOS system by merging ALL of these together. Order matters for some things (later modules override earlier ones), but NixOS modules are designed to be mostly order-independent through the options system.

1. **`deviceModule`** — The per-machine config (hostname, what's enabled, hardware). This is the user-facing file.

2. **`home-managerU.nixosModules.home-manager`** — Registers the home-manager NixOS module. This creates the `home-manager` option namespace in your NixOS config. Without it, you can't write `home-manager = { ... }`.

3. **`flatpaks.nixosModules.default`** — Declarative Flatpak module.

4. **`agenix.nixosModules.default`** — Secret decryption module (creates `/run/agenix/*` files at boot).

5. **The inline home-manager config** — This is where the magic happens. See next section.

#### The Inline Home-Manager Module

```nix
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    sharedModules = [
      ({ osConfig, ... }: {
        _module.args.hostName = osConfig.networking.hostName;
      })
    ];
    users.sid = {
      imports = hmImports;
    };
  };
}
```

This is a regular NixOS module (just written inline instead of in a file). It configures the `home-manager` option namespace.

| Setting | What It Does |
|---------|-------------|
| `useGlobalPkgs = true` | Use the system-level nixpkgs for home-manager packages (no duplicate nixpkgs) |
| `useUserPackages = true` | Allow installing packages through home-manager |
| `backupFileExtension = "backup"` | When home-manager overwrites a file, it renames the old one to `file.backup` instead of deleting it |
| `extraSpecialArgs = { inherit inputs; }` | Makes `inputs` available inside home-manager modules too (so `nixvim.nix` can still use `inputs` if needed in a HM context) |
| `sharedModules` | Modules applied to ALL home-manager users (see hostName trick below) |
| `users.sid.imports = hmImports` | The home-manager modules (common.nix, zsh.nix, niri.nix, etc.) that configure the `sid` user |

### `mkServer`

```nix
mkServer =
  { deviceModule, hmImports }:
  libS.nixosSystem {    # <-- NOTE: libS (stable), not libU
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [
      deviceModule
      disko.nixosModules.disko
      agenix.nixosModules.default
      ./modules/baseline.server.nix    # <-- hardcoded server baseline
      ./modules/ssh.nix                 # <-- hardcoded SSH module
      home-managerS.nixosModules.home-manager   # <-- stable home-manager
      { /* same home-manager inline config as mkWorkstation */ }
    ];
  };
```

Key differences from `mkWorkstation`:

| Aspect | `mkWorkstation` | `mkServer` |
|--------|----------------|------------|
| nixpkgs | `libU` (unstable) | `libS` (stable) |
| home-manager | `home-managerU` (unstable) | `home-managerS` (stable) |
| Flatpak | Included | NOT included |
| Disko | NOT included | Included (for disk partitioning) |
| Baseline module | Implicit (device imports it) | Explicitly added here |
| SSH module | Implicit (device imports it) | Explicitly added here |

**Why the difference?** Servers need stability and disk partitioning. Workstations need bleeding-edge packages and Flatpaks. The helper functions encode these assumptions so device configs stay clean.

---

## 5. How Modules Work

Every `.nix` file under `modules/` follows the same pattern. Let's use `baseline.nix` as the canonical example.

### The Pattern

```nix
{ config, lib, pkgs, inputs, ... }:   # ← Function arguments (what the module receives)
let
  cfg = config.workstation.baseline;   # ← Shortcut alias
in
{
  options.workstation.baseline.enable = lib.mkEnableOption "...";  # ← What the user can SET
  
  config = lib.mkIf cfg.enable {       # ← What HAPPENS when enabled
    boot.loader.systemd-boot.enable = true;
    networking.networkmanager.enable = true;
    # ... dozens of settings ...
  };
}
```

### The `{ config, lib, pkgs, inputs, ... }:` Parameters

Every NixOS module function receives these arguments automatically:

| Parameter | Source | What It Is |
|-----------|--------|------------|
| `config` | Built by NixOS | The FINAL merged configuration of ALL modules. Read-only reference to other options. |
| `lib` | nixpkgs | The standard library. Provides `mkIf`, `mkEnableOption`, `mkOption`, etc. |
| `pkgs` | nixpkgs | The package set. `pkgs.firefox`, `pkgs.zsh`, `pkgs.nerd-fonts.jetbrains-mono`, etc. |
| `inputs` | `specialArgs` | The flake inputs. Available ONLY because of `specialArgs = { inherit inputs; }` in the flake. |
| `...` | — | Absorbs any other args you don't care about (like `modulesPath`). |

### `options` — The "API Surface"

```nix
options.workstation.baseline = {
  enable = lib.mkEnableOption "Baseline workstation configuration";
  packages = {
    tools = lib.mkEnableOption "CLI tools";
    dev   = lib.mkEnableOption "Development tools";
    apps  = lib.mkEnableOption "Desktop applications";
  };
};
```

`lib.mkEnableOption "description"` creates a boolean option that defaults to `false`. The option `workstation.baseline.enable` can then be set by any other module — specifically by the device configs.

**This is the module system's core idea**: modules DECLARE options, users SET options, modules REACT to options via `config = lib.mkIf cfg.enable { ... }`.

### `config` — The "Reaction"

```nix
config = lib.mkIf cfg.enable {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  boot.loader.systemd-boot.enable = true;
  networking.networkmanager.enable = true;
  # ...
};
```

`lib.mkIf condition value` returns `value` when `condition` is true, or nothing when false. This is **conditional merging**: when a device sets `workstation.baseline.enable = true`, all these settings get merged into the final system configuration. When false, they're absent.

**`cfg` is a convenience**:
```nix
cfg = config.workstation.baseline;
```
Then `cfg.enable` reads the option. `cfg.packages.tools` reads the nested option. This avoids repeating `config.workstation.baseline` everywhere.

### The `packages.nix` Variant

`packages.nix` uses a slightly different pattern:

```nix
options.workstation.baseline.packages = {
  tools = lib.mkEnableOption "CLI tools and utilities";
  dev   = lib.mkEnableOption "Development tools";
  apps  = lib.mkEnableOption "Desktop applications";
};

config = {
  environment.systemPackages =
    (lib.optionals cfg.tools toolsPackages)   # ← Only if tools=true
    ++ (lib.optionals cfg.dev devPackages)    # ← Only if dev=true
    ++ (lib.optionals cfg.apps appsPackages);  # ← Only if apps=true
};
```

Here, `config` is NOT wrapped in `lib.mkIf`. The options themselves control what gets added via `lib.optionals`. The lists `toolsPackages`, `devPackages`, `appsPackages` are defined above in the `let` block.

**`lib.optionals cond list`** returns `list` if `cond` is true, or `[]` (empty list) if false. Perfect for building package lists conditionally.

### The Import Chain

The NixOS module system automatically imports files listed in `imports = [ ... ]`. For example, `nixvim.nix`:

```nix
{
  imports = [
    inputs.nixvim.nixosModules.nixvim    # ← This registers nixvim's NixOS module
  ];
  options.workstation.nixvim.enable = lib.mkEnableOption "Nvim configuration";
  config = lib.mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      # ... all the neovim config ...
    };
  };
}
```

When `workstation.nixvim.enable = true` in a device config, the `nixvim.nix` module reacts by:
1. Setting `programs.nixvim.enable = true` (which triggers nixvim's own module)
2. Setting `EDITOR`/`VISUAL` environment variables
3. Adding `ripgrep` to system packages

---

## 6. How `hostName` Travels Through the System

This is one of the trickiest parts. Home manager modules (like `zsh.nix`) need to know which machine they're on, but home manager doesn't have access to NixOS config by default.

### The Problem

In `zsh.nix`, there's a shell alias that depends on the hostname:
```nix
shellAliases = {
  borg_backup = "systemctl restart borgbackup-job-${hostName}-home";
  borg_logs   = "journalctl -u borgbackup-job-${hostName}-home";
};
```

Where does `hostName` come from? It's NOT a built-in home-manager option.

### The Solution — Step by Step

**Step 1**: In `flake.nix`, the `sharedModules` block:
```nix
sharedModules = [
  ({ osConfig, ... }: {
    _module.args.hostName = osConfig.networking.hostName;
  })
];
```

This is a home-manager module (applied to ALL users via `sharedModules`). It's an inline function:

- `osConfig` — The fully-evaluated NixOS config (home-manager exposes this)  
- `_module.args` — A special home-manager option that injects extra function arguments into ALL home-manager modules
- Result: `hostName` becomes available as a function parameter in every home-manager module

**Step 2**: In `zsh.nix`, the function receives it:
```nix
{ config, pkgs, lib, hostName, ... }:
```

**Step 3**: And uses it:
```nix
shellAliases = {
  borg_backup = "systemctl restart borgbackup-job-${hostName}-home";
};
```

### The Full Chain

```
networking.hostName = "prometheus";     ← Set in devices/laptop/prometheus/default.nix
         ↓
osConfig.networking.hostName            ← Read by the sharedModules function
         ↓
_module.args.hostName = "prometheus"    ← Injected into all HM modules
         ↓
{ ..., hostName, ... }:                 ← Received by home/zsh.nix
         ↓
${hostName}                             ← Used in string interpolation
```

### Why Not Just Hardcode?

You could just write `borgbackup-job-prometheus-home` in zsh.nix. But `zsh.nix` is SHARED across all devices (workstations AND servers). The hostname varies:

| Device | borg alias becomes |
|--------|-------------------|
| prometheus | `borgbackup-job-prometheus-home` |
| erebos | `borgbackup-job-erebos-home` |
| void | `borgbackup-job-void-home` |

By using `${hostName}`, one module works for all machines.

---

## 7. Full Trace: `nixos-rebuild switch --flake .#prometheus`

Let's trace exactly what happens when you type that command.

### Phase 1: Flake Discovery

1. Nix reads `flake.nix` from the current directory.
2. It sees `inputs = { ... }` and starts downloading/fetching ALL 10 inputs.
3. For inputs with `follows`, it resolves them to the same store path as the followed input.
4. All inputs are locked in `flake.lock` with exact Git revisions.

### Phase 2: Outputs Evaluation

5. Nix calls the `outputs` function, passing all resolved inputs as arguments.
6. `let` bindings are evaluated: `system = "x86_64-linux"`, `libU`, `libS`.
7. `mkWorkstation` and `mkServer` are defined but NOT called yet.
8. The `nixosConfigurations` attribute set is built. For `prometheus`, Nix sees:
   ```nix
   prometheus = mkWorkstation {
     deviceModule = ./devices/laptop/prometheus/default.nix;
     hmImports = [ ./home/common.nix ./home/zsh.nix ./home/niri.nix ];
   };
   ```
9. `mkWorkstation` is called, which calls `libU.nixosSystem { ... }`. BUT `nixosSystem` is LAZY — it doesn't evaluate the full system yet. It just constructs an unevaluated derivation.

### Phase 3: System Evaluation (lazy, on-demand)

10. `nixos-rebuild` asks for `nixosConfigurations.prometheus.config.system.build.toplevel`.
11. The NixOS module system kicks in and evaluates ALL modules in order:
    - `./devices/laptop/prometheus/default.nix` (deviceModule)
    - `home-managerU.nixosModules.home-manager` (registers `home-manager` option)
    - `flatpaks.nixosModules.default` (registers Flatpak options)
    - `agenix.nixosModules.default` (registers agenix options)
    - The inline home-manager config module (sets `users.sid.imports`)
12. During module evaluation, the device config's `imports` list triggers:
    - `hardware-configuration.nix` (auto-generated, defines partitions/filesystems)
    - `baseline.nix` → registers `workstation.baseline.enable` option
    - `flatpak.nix` → registers `workstation.flatpak.*` options
    - `niri.nix` → registers `workstation.niri.enable` option
    - `nixvim.nix` → registers `workstation.nixvim.enable`, imports nixvim's module
    - `packages.nix` → registers `workstation.baseline.packages.*` options
    - `yazi.nix` → registers `workstation.yazi.enable` option
    - `kanata.nix` → registers `workstation.kanata.*` options
    - `polkit.nix` → registers `workstation.polkit.enable` option
13. All options are collected. Then the device config SETS values:
    ```nix
    networking.hostName = "prometheus";
    workstation.baseline.enable = true;
    workstation.baseline.packages.tools = true;
    workstation.baseline.packages.dev = true;
    workstation.baseline.packages.apps = true;
    # ... etc ...
    ```
14. Each module's `config = lib.mkIf cfg.enable { ... }` triggers because the options are true. The entire system configuration is computed.
15. For home-manager: `users.sid.imports = [ ./home/common.nix ./home/zsh.nix ./home/niri.nix ]`. These files are evaluated as home-manager modules. The `_module.args.hostName` trick runs, injecting `hostName = "prometheus"` into all three.
16. The final `config.system.build.toplevel` is a derivation that contains all activation scripts, systemd units, and symlinks.

### Phase 4: Activation

17. `nixos-rebuild` builds the toplevel derivation (or fetches from cache).
18. It runs the activation script, which:
    - Creates `/run/current-system` → points at the new store path
    - Restarts any changed systemd services
    - Runs agenix to decrypt secrets → `/run/agenix/*`
    - Activates home-manager for user `sid`

### What is Set By Default vs. By User?

| Aspect | Where It's Set | Default? |
|--------|---------------|----------|
| `system = "x86_64-linux"` | `flake.nix` let binding | DEFAULT — hardcoded |
| Systemd-boot, NetworkManager, timezone, fonts, PipeWire, Bluetooth, Tailscale | `baseline.nix` (triggered by `enable = true`) | DEFAULT — comes with enabling baseline |
| CLI tools (eza, git, starship, etc.) | `packages.nix` (triggered by `packages.tools = true`) | DEFAULT — comes with enabling tools |
| IDE/editor (nvim config) | `nixvim.nix` (triggered by `nixvim.enable = true`) | DEFAULT — comes with enabling nixvim |
| GTK/Qt themes, cursor, Niri shortcuts | `home/niri.nix`, `home/kde.nix` (via `hmImports`) | DEFAULT — comes with importing the DE module |
| `networking.hostName = "prometheus"` | `devices/laptop/prometheus/default.nix` | USER-SET — per device |
| `workstation.niri.enable = true` | `devices/laptop/prometheus/default.nix` | USER-SET — per device |
| `workstation.kanata.layout = "colemak"` | `devices/laptop/prometheus/default.nix` | USER-SET — per device |
| Flatpak apps list | `devices/laptop/prometheus/default.nix` | USER-SET — per device |
| Extra packages (`v4l-utils`) | `devices/laptop/prometheus/default.nix` | USER-SET — per device |
| SSH authorized keys | `modules/ssh.nix` (triggered by `ssh.enable = true`) | DEFAULT — shared across devices |
| Age secret identity paths | Per-device files | USER-SET — `erebos` uses `/home/sid/.ssh/agenix_sid`; servers use `/home/sid/.ssh/id_ed25519` |

---

## 8. Q&A — Common Confusions

### Q: Why are there TWO nixpkgs inputs?

**A**: Workstations want the latest everything (unstable). Servers want stability. Using two inputs lets you mix them:
- `mkWorkstation` → uses `libU` (unstable)
- `mkServer` → uses `libS` (stable)
- Each dependency's `follows` routes it to the right one

### Q: What happens if I remove `follows` from an input?

**A**: That flake downloads its OWN copy of nixpkgs. Things will still work, but:
- Builds take longer (duplicate downloads)
- `/nix/store` grows larger
- Possible version mismatch (your system uses nixpkgs commit A, the flake uses commit B, and a package compiled against B won't work with A's libraries)

### Q: Why does `specialArgs` use `inherit inputs` instead of just `inputs = inputs`?

**A**: They're the same thing. `inherit inputs;` is syntactic sugar that means `inputs = inputs;`. It also works for multiple variables: `inherit foo bar baz;` expands to `foo = foo; bar = bar; baz = baz;`.

### Q: What's the difference between `specialArgs` and `extraSpecialArgs`?

**A**:
- `specialArgs` — Extra arguments passed to NIXOS modules (the ones under `modules = [...]` in `nixosSystem`).
- `extraSpecialArgs` — Extra arguments passed to HOME-MANAGER modules (the ones under `home-manager.users.sid.imports`).

They serve the same purpose but at different levels of nesting.

### Q: Why does `mkWorkstation` pass deviceModule as the FIRST module in the list?

**A**: Module evaluation order: all modules are collected, options are merged, THEN configs are applied. Order mostly doesn't matter for the options/config model. But it's convention to put the device module first so its imports are processed early, and its option SETTINGS are visible to later modules that might reference them.

### Q: What's `...@inputs:` in the outputs function signature?

**A**: Two things:
- `...` — Pattern match "rest" operator. Absorbs any remaining attributes not destructured by name. Prevents "unexpected argument" errors.
- `@inputs` — "As-pattern". Binds the ENTIRE argument value to the name `inputs`. So `inputs.self` works alongside destructured `self`.

### Q: Can I add a new machine without changing flake.nix?

**A**: No. Every machine needs an entry in `nixosConfigurations`. To add one:
1. Create `devices/<type>/<name>/default.nix`
2. Add the entry in `flake.nix` under `nixosConfigurations`
3. Run `nixos-rebuild switch --flake .#<name>`

### Q: What's the difference between `mkWorkstation` and `mkServer` in practice?

**A**: They're almost identical templates with different defaults:

| Trade-off | Workstation | Server |
|-----------|------------|--------|
| Package freshness | Bleeding-edge | Stable, tested |
| Desktop environment | Included | No DE |
| GPU/audio/Bluetooth | Included | No |
| Flatpaks | Included | No |
| Disk partitioning (disko) | No | Included |
| SSH server | Optional (per-device) | Forced (hardcoded) |
| QEMU guest agent | No | Included |

### Q: Why is there both `config` and `cfg`?

**A**: `config` is the module function parameter (the merged result of ALL modules). `cfg` is a local shortcut:
```nix
cfg = config.workstation.baseline;
```
Then instead of writing `config.workstation.baseline.enable` everywhere, you write `cfg.enable`. Both read from the same source.

### Q: What does `lib.mkForce` do (seen in `server.nix`)?

**A**: `lib.mkForce "value"` overrides ANY prior definition with priority, ignoring merge semantics. Used in `home/server.nix`:
```nix
home.homeDirectory = lib.mkForce "/home/sid";
```
Without `mkForce`, if multiple modules set `homeDirectory`, Nix would throw a "duplicate definition" error. `mkForce` says "I win, don't complain."

---

## 9. Visual Map of the Entire Codebase

```
flake.nix  ←── ENTRY POINT
│
├─ inputs (dependencies)
│  ├─ nixpkgs-unstable ────────→ github:nixos/nixpkgs/nixos-unstable
│  ├─ nixpkgs-stable ──────────→ github:nixos/nixpkgs/nixos-25.11
│  ├─ home-managerU ───────────→ github:nix-community/home-manager (follows unstable)
│  ├─ home-managerS ───────────→ github:nix-community/home-manager/release-25.11 (follows stable)
│  ├─ agenix ──────────────────→ github:ryantm/agenix (follows stable)
│  ├─ nixvim ──────────────────→ github:nix-community/nixvim (follows unstable)
│  ├─ hermes-agent ────────────→ github:NousResearch/hermes-agent (follows unstable)
│  ├─ nixard ──────────────────→ github:manelinux/nixard (follows unstable)
│  ├─ noctalia ────────────────→ github:noctalia-dev/noctalia-shell (follows unstable)
│  ├─ flatpaks ────────────────→ github:in-a-dil-emma/declarative-flatpak/latest
│  └─ disko ───────────────────→ github:nix-community/disko (follows stable)
│
└─ outputs
   ├─ mkWorkstation(deviceModule, hmImports) → libU.nixosSystem { ... }
   │     │
   │     └─ modules: [deviceModule, home-managerU, flatpaks, agenix, inline-hm-config]
   │
   ├─ mkServer(deviceModule, hmImports) → libS.nixosSystem { ... }
   │     │
   │     └─ modules: [deviceModule, disko, agenix, baseline.server, ssh, home-managerS, inline-hm-config]
   │
   └─ nixosConfigurations
        ├─ erebos     = mkWorkstation { deviceModule: devices/desktop/erebos/default.nix,     hmImports: [common, zsh, kde] }
        ├─ prometheus = mkWorkstation { deviceModule: devices/laptop/prometheus/default.nix,   hmImports: [common, zsh, niri] }
        ├─ null       = mkWorkstation { deviceModule: devices/desktop/null/default.nix,        hmImports: [common, zsh, kde] }
        ├─ steamos    = mkWorkstation { deviceModule: devices/desktop/dionysus/default.nix,    hmImports: [steam] }
        ├─ void       = mkServer      { deviceModule: devices/server/void/default.nix,         hmImports: [server, zsh] }
        ├─ v-gaia-main = mkServer     { deviceModule: devices/server/v-gaia-main/default.nix,  hmImports: [server, zsh] }
        └─ zeus       = mkServer      { deviceModule: devices/server/zeus/default.nix,         hmImports: [server, zsh] }


DEVICE MODULES (what mkWorkstation/mkServer receives as deviceModule)
──────────────────────────────────────────────────────────────────
devices/
├─ desktop/
│  ├─ erebos/default.nix     ← imports: [hw-config, baseline, flatpak, niri, kde, mount,
│  │                              packages, ssh, nixvim, yazi, virtualization, polkit]
│  │                           sets: hostname="erebos", workstation.{baseline,nixvim,kde,
│  │                              polkit,yazi,ssh,virtualization,flatpak}.enable=true
│  │                           mount.{media,games}.enable=true, NFS server, steam, coolercontrol
│  │
│  ├─ null/default.nix       ← (similar to erebos but different hostname and specific tweaks)
│  │
│  └─ dionysus/default.nix   ← SteamOS/Gamescope setup (experimental)
│
├─ laptop/
│  └─ prometheus/default.nix ← imports: [hw-config, baseline, flatpak, niri, nixvim,
│                               packages, yazi, kanata, polkit]
│                              sets: hostname="prometheus", workstation.{baseline,nixvim,
│                               niri,polkit,yazi,kanata}.enable=true
│                              flatpak apps, v4l-utils, podman, steam
│
└─ server/
   ├─ void/default.nix       ← imports: [hw-config, nixvim, tuwunel, firewall, backup]
   │                           sets: hostname="void", server.baseline.enable=true,
   │                           workstation.{ssh,nixvim}.enable=true, GRUB bootloader
   │
   ├─ v-gaia-main/default.nix
   └─ zeus/default.nix


SYSTEM MODULES (under modules/)
────────────────────────────────
modules/
├─ baseline.nix         ← options.workstation.baseline { enable, packages.{tools,dev,apps} }
│                          Enables: systemd-boot, NetworkManager, Bluetooth, PipeWire,
│                          Tailscale, fonts, locales, timezone, user 'sid', etc.
│
├─ baseline.server.nix  ← options.server.baseline.enable
│                          Server-specific: journald limits, Docker rootless, QEMU guest,
│                          server packages (no GUI stuff)
│
├─ packages.nix         ← options.workstation.baseline.packages.{tools,dev,apps}
│                          Adds packages conditionally to environment.systemPackages
│
├─ nixvim.nix           ← options.workstation.nixvim.enable
│                          imports nixvim's module, sets up neovim with Colemak keybinds
│
├─ niri.nix             ← options.workstation.niri.enable
│                          Enables Niri compositor, sets up display manager
│
├─ kde.nix              ← options.workstation.kde.enable
│                          Enables KDE Plasma desktop
│
├─ flatpak.nix          ← options.workstation.flatpak.{enable,onCalendar,packages}
│                          Declarative Flatpak management
│
├─ polkit.nix           ← options.workstation.polkit.enable
│                          Polkit + KDE polkit agent
│
├─ yazi.nix             ← options.workstation.yazi.enable
│                          Yazi terminal file manager
│
├─ kanata.nix           ← options.workstation.kanata.{enable,layout}
│                          Keyboard remapping daemon (Colemak)
│
├─ ssh.nix              ← options.workstation.ssh.enable
│                          SSH server config + authorized YubiKeys
│
├─ virtualization.nix   ← options.workstation.virtualization.enable
│                          QEMU/KVM/libvirt
│
├─ mount.nix            ← options.workstation.mount.{media,games}.enable (erebos only)
│
└─ surfshark.nix        ← options.workstation.surfshark.{enable,...}  [DISABLED]
                           WireGuard VPN tunnel


HOME-MANAGER MODULES (under home/)
───────────────────────────────────
home/
├─ common.nix   ← Sets username, home dir, stateVersion
│                 Enables: git, starship, btop, Qt theme, desktop entries,
│                 dconf settings, starship/eza/fuzzel/fastfetch config files
│
├─ zsh.nix      ← ZSH config: aliases (borg_* uses ${hostName}), oh-my-zsh,
│                 autosuggestions, syntax highlighting, starship init
│
├─ niri.nix     ← GTK/Qt theming (Tokyonight), cursor (RosePine), Niri keymap,
│                 Ghostty terminal config, conditional niri config (laptop vs desktop)
│
├─ kde.nix      ← GTK/Qt theming for KDE, Ghostty config for KDE
│
├─ server.nix   ← Minimal home-manager config for servers (git, starship, btop)
│
├─ steam.nix    ← Gamescope + Steam big picture mode (for dionysus)
│
├─ gnome.nix    ← (alternative DE module, not currently used)
├─ hypr.nix     ← (alternative DE module, not currently used)
├─ xfce.nix     ← (alternative DE module, not currently used)
└─ bash.nix     ← (alternative shell module, not currently used)


KEY DATA FLOW
────────────────
  flake.nix
    │
    ├── inputs (10 external flakes, all downloaded, locked in flake.lock)
    │
    ├── outputs function called with all inputs
    │     │
    │     ├── mkWorkstation({ deviceModule, hmImports })
    │     │     calls libU.nixosSystem({
    │     │       system: "x86_64-linux",
    │     │       specialArgs: { inputs },  ← makes inputs available in all modules
    │     │       modules: [
    │     │         deviceModule,           ← per-machine config
    │     │         home-managerU module,   ← registers home-manager NixOS options
    │     │         flatpaks module,        ← registers flatpak options
    │     │         agenix module,          ← registers age.secrets options
    │     │         inline-HM-config {      ← sets home-manager.users.sid
    │     │           extraSpecialArgs: { inputs },
    │     │           sharedModules: [ hostName bridge ],
    │     │           users.sid.imports = hmImports
    │     │         }
    │     │       ]
    │     │     })
    │     │
    │     └── nixosConfigurations.<name> = mkWorkstation/mkServer(...)
    │
    └── nixos-rebuild picks nixosConfigurations.prometheus
          │
          ├── device module imports chain: hw-config → baseline → flatpak →
          │   niri → nixvim → packages → yazi → kanata → polkit
          │
          ├── Options defined by: baseline.nix, packages.nix, nixvim.nix, etc.
          │   Options SET by: prometheus/default.nix
          │   Config TRIGGERED by: mkIf cfg.enable in each module
          │
          ├── Home-manager evaluates: common.nix → zsh.nix → niri.nix
          │   hostName injected via _module.args.hostName
          │
          └── Final output: /nix/store/<hash>-nixos-system-prometheus-...
              (a derivation that, when activated, becomes gen N)
```

---

## Summary: The Mental Model

Think of the flake as a **factory**:

1. **Inputs** are the raw materials (external flakes from GitHub).
2. **`mkWorkstation` and `mkServer`** are assembly lines — each takes a device blueprint and produces a complete system.
3. **Device configs** are the blueprints — they specify which modules to import and which options to enable.
4. **System modules** are reusable components — each declares options and provides default configurations when enabled.
5. **Home-manager modules** are the personalization layer — they configure YOUR user environment (shell, themes, aliases).

The whole thing is **declarative**: you don't tell Nix HOW to build the system, you tell it WHAT the system should look like. Nix figures out the build order, downloads, and activation.

To add a new laptop called "athena":
1. Create `devices/laptop/athena/default.nix` (copy from prometheus, change hostname and tweak settings)
2. Add `athena = mkWorkstation { deviceModule = ./devices/laptop/athena/default.nix; hmImports = [ ... ]; };` to `nixosConfigurations`
3. `nixos-rebuild switch --flake .#athena`

That's it. Everything else is already wired up by the factory functions.
