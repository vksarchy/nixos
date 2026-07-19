# Live Dotfiles — the mkOutOfStoreSymlink pattern

Apps in this directory are symlinked into `~/.config/` via
`config.lib.file.mkOutOfStoreSymlink` in home-manager. They live at a real,
mutable path — NOT in `/nix/store/`. This means you can edit them on the fly
without a `home-manager switch`.

## Currently using this pattern

| App | Dotfiles path | Symlink target | Config nix module |
|---|---|---|---|
| Doom Emacs | `dotfiles/doom/` | `~/.config/doom` | `modules/emacs/default.nix` |

## Workflow

```
edit ~/nixos/dotfiles/doom/init.el    # changes saved immediately
doom sync                              # ~5 seconds
# restart Emacs or M-x doom/reload
```

No `home-manager switch` needed. Rebuild only when:
- Changing the Emacs binary (emacs → emacs-pgtk)
- Adding system-level dependencies (new `home.packages` entry in the nix module)

## Adding another app

Example: moving kitty config to live dotfiles.

**1.** Move the config out of the nix module:
```
mv ~/nixos/modules/somewhere/kitty/ ~/nixos/dotfiles/kitty/
```

**2.** In the nix module, replace:
```nix
# BEFORE (nix store — rebuild on every change)
home.file.".config/kitty".source = ./kitty;
```
with:
```nix
# AFTER (live — edit freely)
home.file.".config/kitty".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/dotfiles/kitty";
```

**3.** Rebuild once. From then on, edit files in `~/nixos/dotfiles/kitty/` directly.

## How it works

`mkOutOfStoreSymlink` creates a symlink that points to a real, writable
filesystem path instead of the immutable nix store. The symlink itself IS
managed by home-manager (so it survives rebuilds), but the target directory
is your normal git-tracked folder.

    ~/.config/doom → ~/nixos/dotfiles/doom/   (real dir, live edits)
    ~/.config/kitty → /nix/store/abc123.../    (read-only, must rebuild)

## Good candidates for this pattern

- **Doom/Emacs config** — frequent edits, own sync tool (`doom sync`)
- **Neovim config** — frequent edits, Lazy/packer manage packages
- **Kitty, WezTerm, Ghostty** — terminal configs you tweak often
- **Waybar, wofi, fuzzel** — appearance tweaks
- **Hyprland/niri/sway** — WM config you iterate on
- **starship, fastfetch, btop** — cosmetic configs
- **mpv, yt-dlp** — media tool configs

## Bad candidates (keep in nix store)

- **Secrets / keys** — use agenix
- **Configs that never change** — not worth the indirection
- **GTK/Qt theming** — handled by stylix/home-manager modules

## Note

The actual Doom framework itself lives at `~/.config/emacs/` (copied once by
home-manager activation, then managed by `doom upgrade`). Only the *user
config* (`~/.config/doom/`) uses this pattern — that's where your init.el,
packages.el, config.el, themes, and snippets live.
