──────────────────────────────
● yes pls, make sure i write all of this my myself, where to look for help , where to
look for what to type in? nixpkgs, nix options, stuff like that...
────────────────────────────────────────

 ─  ⚕ Hermes  ──────────────────────────────────────────────────────────────────────

     The real skill isn't memorizing options — it's knowing how to find them.
     Here's your research toolkit:
     1. NixOS Options Search (the bible)

     https://search.nixos.org/options

     Type what you want and it finds the option path. Examples:
     - qtile → services.xserver.windowManager.qtile.enable
     - greetd → services.greetd.settings
     - tmux → programs.tmux.enable

     This tells you:
     - The full option path to use in your module
     - The type (boolean, string, list, etc.)
     - Default value
     - Which module provides it

     Critical: The search has a channel picker (top-right). Match it to your
     nixpkgs branch — you're on nixos-26.05, so pick 26.05. Unstable has options
     that don't exist in stable.
     2. Nixpkgs Package Search

     https://search.nixos.org/packages

     Type a program name to find its Nix attribute. Examples:
     - rofi → pkgs.rofi
     - waybar → pkgs.waybar
     - picom → pkgs.picom

     This is how you know what to put in environment.systemPackages or
     home.packages.
     3. Home Manager Option Search

     https://nix-community.github.io/home-manager/options.xhtml

     Separate from NixOS options — this is where home-manager-specific options
     live. Examples:
     - gtk → gtk.theme, gtk.enable
     - waybar → programs.waybar.enable
     - dunst → services.dunst.enable

     You're on release-26.05 for home-manager.
     4. The manual (conceptual)

     https://nixos.org/manual/nixos/stable/ — NixOS manual
     https://nix-community.github.io/home-manager/ — Home Manager manual

     These explain module syntax, lib.mkEnableOption, lib.mkIf, etc.
     5. grep your own config

     When stuck on syntax, grep your existing modules:

     bash
     How did I write a toggle before?
     grep -A5 "mkEnableOption" ~/nixos/modules/.nix
     How did I use mkIf?
     grep -A3 "mkIf cfg" ~/nixos/modules/.nix
     What parameters does a system module take?
     head -8 ~/nixos/modules/niri.nix

     6. nix eval (quick lookup without browser)

     bash
     Does this option exist?
     nix eval
     nixpkgs#nixosConfigurations.erebos.options.services.xserver.windowManager.q
     tile.enable --raw 2>/dev/null && echo "yes" || echo "no"
     Find all options under a path
     nix eval nixpkgs#nixosConfigurations.erebos.options.programs --apply 'x:
     builtins.attrNames x' 2>/dev/null | head -20
     Available packages matching a name
     nix eval nixpkgs#legacyPackages.x86_64-linux --apply 'x: builtins.filter
     (n: builtins.match ".qtile." n != null) (builtins.attrNames x)'

     7. Source code (when options search fails)

     Sometimes you need to see what an option actually does:
     bash
     Find which file defines an option
     nix eval
     nixpkgs#nixosConfigurations.erebos.options.services.xserver.windowManager.q
     tile.enable.declarations
     gives you the file path → read it

     Your practice flow for qtile

     1. Go to https://search.nixos.org/options — search qtile
     2. Find services.xserver.windowManager.qtile.enable — note the full path
     3. Go to https://search.nixos.org/packages — search qtile
     4. Find the package attribute (probably pkgs.qtile)
     5. Go to https://nix-community.github.io/home-manager/options.xhtml —
     search picom, rofi, dunst for home-manager options
     6. Write modules/qtile.nix using the toggle pattern from memory
     7. Write home/qtile.nix using the home-manager pattern from memory
     8. Edit your device config to import + enable
     9. Edit flake.nix to add extraHmImports
     10. Dry-build: nix build --no-link
     '.#nixosConfigurations.erebos.config.system.build.nixos-rebuild'

     Want me to build a search-index bookmark skill so you have these URLs
     always accessible, or are you good?
