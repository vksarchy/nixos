# My NixOS configurations

Personal flake-based NixOS + Home Manager setup. Workstations only for now — modular, hostname-scoped builds, Niri + Noctalia by default.

> **Use with caution.** Review files before applying. Hostnames, usernames, mounts, secrets, and hardware paths are specific to my machines. Modules exist so you can turn pieces off or fork more easily.

## Table of contents

- [Repo structure](#repo-structure)
- [Hosts](#hosts)
- [Important notes](#important-notes)
- [Build commands](#build-commands)
- [Cloning / adapting](#cloning--adapting)
- [Sponsor NixOS](#sponsor-nixos)

## Repo structure

| Path | Purpose |
|------|---------|
| `/config` | App configs (ghostty, niri, noctalia, fuzzel, starship, etc.). Mostly wired through Home Manager into `~/.config`. |
| `/devices` | Per-machine entry points under `/desktop` and `/laptop`. Imports modules, sets host options, holds `hardware-configuration.nix`. **Replace hardware configs if you fork this.** |
| `/home` | Home Manager: baseline (`common.nix`), shell (`zsh.nix`), WM (`niri.nix`), extras (`steam.nix`). |
| `/modules` | Feature modules (`baseline`, `niri`, `gaming`, `backup`, …) plus `profiles/workstation.nix` which pulls the common set together. |
| `/pkgs` | Local package definitions. |
| `/scripts` | Small helper scripts. |
| `/secrets` | agenix secrets (encrypted). |
| `/dotfiles` | Extra dotfiles (e.g. Doom Emacs) not always fully Nix-managed. |

## Hosts

Flake outputs are **hostname-only** (no `hostname-profile` combos like `prometheus-hypr`):

| Flake attr | Device | Notes |
|------------|--------|--------|
| `prometheus` | Laptop | Primary daily driver |
| `mactheus` | Laptop | Lighter profile (`workstation.profile.full = false`) |
| `karuppu` | Desktop | Full workstation |

Build shape:

```text
.#prometheus
.#mactheus
.#karuppu
```

Each host is assembled via `mkWorkstation` in `flake.nix` (device module + shared Home Manager imports + optional extras).

## Important notes

- **Channel / kernel / unfree:** workstations track **nixpkgs unstable**, **latest kernel**, and **allow unfree**. Automatic GC keeps generations **≤ 7 days**.
- **Baseline:** `/modules/baseline.nix` — boot, networking, users, locale, core services. Enable with `workstation.baseline.enable = true` (on by default via the workstation profile).
- **Packages:** `/modules/packages.nix` — shared packages under `workstation.baseline.packages` with toggles for `tools`, `dev`, and `apps`.
- **Profile:** `/modules/profiles/workstation.nix` imports the common module set. Toggle heavy extras with `workstation.profile.full`.
- **Shell:** **zsh** by default (`home/zsh.nix` in `baseHmImports` in `flake.nix`).
- **Desktop:** **Niri** + **Noctalia Shell** + **Stylix** (Tokyo Night). Display manager is **ly**, default session `niri`.
  - Skip Noctalia: drop the `noctalia` input in `flake.nix`, remove its package from `modules/niri.nix`, and clean startup/spawn lines in `/config/niri`.
- **User:** `sid` — change usernames, home paths, and HM `users.*` if you reuse this.
- **Secrets:** [agenix](https://github.com/ryantm/agenix). You need matching age keys; encrypted files in `/secrets` will not work as-is on another machine.
- **Kanata:** keyboard remapping module with layout files under `/modules/kanata`.
- Older experiments (multi-profile flake attrs, large server tree, wallpaper blobs) are not part of this tree. Repo is small on purpose.

## Build commands

From the repo root:

```bash
# Laptop (primary)
sudo nixos-rebuild switch --flake .#prometheus

# Laptop (lighter)
sudo nixos-rebuild switch --flake .#mactheus

# Desktop
sudo nixos-rebuild switch --flake .#karuppu

# Next-boot only (safer when testing)
sudo nixos-rebuild boot --flake .#prometheus
```

Dry-run / build without activating:

```bash
nixos-rebuild build --flake .#prometheus
nix build .#nixosConfigurations.prometheus.config.system.build.toplevel
```

## Cloning / adapting

1. Clone the repo and enter it.
2. Replace `devices/<type>/<host>/hardware-configuration.nix` with your own (`nixos-generate-config`).
3. Rename host attrs in `flake.nix` and `networking.hostName` in the device module.
4. Change `users.users.sid` / Home Manager `users.sid` if needed.
5. Disable modules you do not want via the device file (`workstation.<module>.enable = false` or `profile.full = false`).
6. Set up agenix (or strip secret references) before rebuild.
7. Rebuild with `sudo nixos-rebuild switch --flake .#<your-host>`.

Most knobs live under the `workstation` option namespace so device files stay short.

## Module map (high level)

| Area | Modules |
|------|---------|
| Core | `baseline`, `packages`, `polkit`, `ssh`, `backup` |
| Desktop | `niri`, `kanata` |
| Editors / tools | `nixvim`, `emacs`, `yazi`, `tmux`, `zennotes`, `stt` |
| Apps | `browser`, `comms`, `media`, `office`, `creative`, `books`, `localsend` |
| Heavy | `gaming`, `virtualization`, `torrent`, `ai`, `hermes`, `surfshark`, `flatpak` |

Enable/disable from the device `default.nix` rather than editing every module.

## Sponsor NixOS

If this ecosystem is useful to you, consider sponsoring NixOS:  
https://github.com/sponsors/NixOS
