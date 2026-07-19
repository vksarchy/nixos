# Future NixOS improvements

Notes from Reddit sanity-check of toggle-module pattern (June 2026).

## Pattern verdict: correct

Using `options.workstation.<name>.enable` + `lib.mkIf cfg.enable` is the right
approach. It's how nixpkgs modules work, and multiple experienced users confirmed it.

The dissenting opinion ("skip options, just use imports") is valid for very simple
setups, but we already have the pattern built out across 20+ modules — no reason
to change.

## mkDefault vs mkForce

| Priority | Use when |
|----------|----------|
| `mkDefault` | You set a default that a host/other module SHOULD be able to override |
| `mkForce`   | You want to FORCE a value — nobody else can override it |
| bare assignment | Only safe when you're certain nothing else will set the same option |

Currently our `baseline.nix` uses bare assignments for everything. It works because
servers don't import `baseline.nix` (they import `baseline.server.nix` instead).
If we ever wanted servers to share `baseline.nix`, we'd need to wrap timezone,
kernel, GC settings, and tailscale in `lib.mkDefault`.

## mkForce for list merging

When multiple modules push to the same list (e.g., `sessionPackages`),
they get merged. `lib.mkForce` replaces the whole list instead.
Not currently an issue since we only enable one DE per host.

## Redundant systemPackages

`programs.<app>.enable = true` already adds the package to PATH.
Don't also add it to `environment.systemPackages`. We're not doing this — good.

## RAM cost of the options pattern

Importing all modules on every host increases eval memory. Boberoch saw 22G → 18G
reduction by switching to conditional imports — but that was with 20+ microVMs.
At our scale (6-7 machines), overhead is negligible. Not worth changing.

## Things to remember for the future

- **New shared module that sets global values?** Wrap in `lib.mkDefault` if any
  host might want to override.
- **Adding a new machine type that shares some but not all workstation config?**
  Consider whether `mkDefault` on baseline values would help avoid collisions.
- **DE modules merging sessionPackages?** Use `lib.mkForce` to reset the list
  on a per-host basis if unwanted entries appear.
- **Programs adding themselves to PATH?** `programs.git.enable = true` means
  git is already available — no need for manual `systemPackages` entry.
