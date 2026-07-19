# Writing NixOS Modules from Scratch

How to write a toggle module (system + home-manager) for a new service/app/wm
and wire it into the flake setup at `~/nixos/`.

## The Core Mental Model

NixOS modules declare **options** (the contract) and react with **config** only when those options are enabled.  
Home Manager modules are selected per-machine in `flake.nix` (via `hmImports`), not usually gated by options inside the home module itself.

This separation keeps layers loosely coupled and makes decisions visible in one place.

## The pattern (by heart)

```
flake.nix
  └─ mkWorkstation / mkServer
       ├─ deviceModule (devices/<type>/<name>/default.nix)
       │ ├─ imports → [ modules/<name>.nix, ... ]
       │ └─ workstation.<name>.enable = true (or <name>.enable for servers)
       │
       └─ hmImports → [ home/<name>.nix, ... ]
            └─ runs as home-manager module for user sid
```

**Key insight from this repo**: Most home modules (niri.nix, kde.nix, etc.) have **no internal enable toggle**. They are simply included in the `hmImports` list only for machines that chose that desktop environment or feature. The system module handles the toggle.

## System module boilerplate (`modules/<name>.nix`)

```nix
{ config, pkgs, lib, inputs, ... }: # drop 'inputs' if not using external flakes
let
  cfg = config.workstation.<name>; # for servers: config.<name>
in
{
  options.workstation.<name>.enable = lib.mkEnableOption "<description>";

  config = lib.mkIf cfg.enable {
    # NixOS options here: programs.<x>.enable, services.<x>, environment.systemPackages, etc.
  };
}
```

For **servers**, use `options.<name>.enable` (no `workstation.` prefix) to match `baseline.server.nix` conventions.

## Home module boilerplate (`home/<name>.nix`) — Repo-aligned pattern

**Preferred (simple, what the repo actually does)**:

```nix
{ config, pkgs, lib, hostName, ... }:
{
  # No mkIf enable guard here.
  # This module is only imported for machines that want this feature/WM/DE.
  # Use the injected hostName for machine-specific branching if needed.

  gtk.theme = { name = "Tokyonight-Dark"; package = pkgs.tokyonight-gtk-theme; };
  programs.ghostty.settings = { ... };
  # home.packages, xdg.configFile, services.<x>, etc.
}
```

**When you actually need reactivity** (rare):

Only reach for `osConfig` when a home setting must change based on a system option being toggled at runtime. Even then, prefer a narrow bridge via `_module.args` in `sharedModules` rather than pulling the entire `osConfig`.

## Why the repo uses `hmImports` selection instead of home-module toggles

**Data flow**:
```
flake.nix
  └─ prometheus = mkWorkstation { hmImports = [ ./home/common.nix ./home/zsh.nix ./home/niri.nix ]; }
       └─ home-manager NixOS module
            └─ sharedModules injects hostName = "prometheus" into every HM module
            └─ users.sid.imports = hmImports list
                 └─ home/niri.nix runs unconditionally for this machine
```

**Why this is better**:
- Avoids "option does not exist" errors when the system module isn't imported.
- Makes the decision ("this machine uses Niri") explicit and visible in `flake.nix`.
- Keeps home modules pure and reusable across machines.
- Matches how KDE vs Niri vs Hyprland vs server home configs are already handled.

## Namespace Rule (non-negotiable in this repo)

- Workstation features → `workstation.<feature>`
- Server features → `<feature>` (no prefix)
- Mounts / shared infra → `mount.*`, `remoteBackup.*`, etc.

Never put random things under `myconfig.*` or top-level. Separate namespaces make it obvious which layer an option belongs to and prevent collisions.

## Wiring checklist

1. Create `modules/<name>.nix` (system toggle + config)
2. Create `home/<name>.nix` (home config — usually no internal toggle)
3. In device config (`devices/<type>/<host>/default.nix`):
   - Add `../../../modules/<name>.nix` to `imports`
   - Add `workstation.<name>.enable = true;` (or `<name>.enable = true` for servers)
4. In `flake.nix`:
   - Add `./home/<name>.nix` to `hmImports` for that host (this is the selection point)

## Research toolkit

### 1. NixOS Options Search
https://search.nixos.org/options  
Set channel to match your nixpkgs (unstable or 26.05).

### 2. Nixpkgs Package Search
https://search.nixos.org/packages

### 3. Home Manager Option Search
https://nix-community.github.io/home-manager/options.xhtml  
Match your home-manager release.

### 4. grep your own config (fastest)
```bash
grep -A5 "mkEnableOption" ~/nixos/modules/*.nix
grep -A3 "mkIf cfg" ~/nixos/modules/*.nix
head -8 ~/nixos/modules/niri.nix
```

### 5. Dry-build before telling yourself to rebuild
```bash
nix build --no-link --print-out-paths '.#nixosConfigurations."<host>".config.system.build.nixos-rebuild'
```

## mkDefault / mkForce / merge behavior

| Priority     | Meaning                                      | When to use |
|--------------|----------------------------------------------|-------------|
| bare assignment | Default. Lists concatenated, scalars collide | Most cases |
| `lib.mkDefault` | Low priority — "here's a default"            | In shared/baseline modules |
| `lib.mkForce`   | High priority — "use THIS, ignore others"    | On host to override baseline |

## Key conventions in this repo

- Username: `sid`, home: `/home/sid`
- `stateVersion`: "26.05" (set once, never change)
- Workstation hosts: erebos (KDE), prometheus (Niri), null (KDE), dionysus/steamos (experimental)
- Server hosts: void, v-gaia-main, zeus
- External flake packages: add input → reference via `inputs.<name>.packages.${pkgs.system}.default`
- `programs.<app>.enable = true` already puts the binary in PATH — do not duplicate in `environment.systemPackages`

---

**This version teaches the architecture the repo actually uses**, not a generic "toggle everything" pattern. It reduces coupling and makes the mental model clearer: system modules are toggled; home modules are selected at the flake layer.

Copy this into your personal notes / `docs/` and iterate from here. Ready for the next point (namespace enforcement examples, or advanced patterns like conditional home config via narrow bridges)? Just say the number.