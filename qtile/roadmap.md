
 ─  ⚕ Hermes  ──────────────────────────────────────────────────────────────────────

     Now I can see both patterns clearly. Here's what's happening vs what you
     need to write yourself:

     The exact pattern has TWO layers — a system module (NixOS options) AND a
     home module (home-manager config). Sometimes the home module is just dumped
     directly (no toggle), like home/hypr.nix. Other times both layers have
     toggles. Your setup's key insight:

     The flow: flake.nix → mkWorkstation/mkServer → deviceModule (imports system
     module) + extraHmImports (imports home module) → enable toggle turns on
     system module → home module runs as hm user config.

     Here's the roadmap. I'll use qtile as your example.
     Roadmap: Write qtile from scratch
     File 1: System module — modules/qtile.nix

     This is the NixOS-level toggle. It installs the package, sets up
     greetd/session, any system-wide deps.

     nix
     { config, lib, pkgs, inputs, ... }:
     let
       cfg = config.workstation.qtile;
     in
     {
       options.workstation.qtile.enable = lib.mkEnableOption "Qtile window
     manager";

       config = lib.mkIf cfg.enable {
         # 1. System-level: install qtile and its session
         services.xserver = {
           enable = true;
           windowManager.qtile.enable = true;
         };

         # Or if you want Wayland qtile:
         # environment.systemPackages = [ pkgs.qtile ];

         # 2. Greetd (login manager) — same pattern as niri/hypr
         services.greetd = {
           enable = true;
           settings = {
             default_session = {
               command = "${pkgs.tuigreet}/bin/tuigreet --cmd qtile";
               user = "greeter";
             };
             initial_session = {
               command = "qtile start";
               user = "sid";
             };
           };
         };

         # 3. Required system packages
         environment.systemPackages = with pkgs; [
           # whatever qtile needs at system level
           picom
           feh
           xclip
         ];
       };
     }

     Key rules:
     - Parameter list: { config, lib, pkgs, inputs, ... } if you need inputs
     (external flakes), otherwise drop it
     - let cfg = config.workstation.qtile; — qtile matches the option path
     - options.workstation.qtile = { enable = lib.mkEnableOption "..."; } — the
     enable switch
     - config = lib.mkIf cfg.enable { ... } — ALL config guarded by the toggle
     - For server modules, use options.qtile (no workstation. prefix) and the
     parameter list drops inputs unless needed
     File 2: Home module — home/qtile.nix

     This is the home-manager config for the user sid. Gets imported as
     extraHmImports in flake.nix.

     nix
     { config, pkgs, lib, ... }:

     {
     Qtile is configured via Python, so most config goes in xdg.configFile
       xdg.configFile."qtile" = {
         source = ../config/qtile;   # your qtile config.py dir
         recursive = true;
       };
     Home packages qtile needs
       home.packages = with pkgs; [
         rofi          # launcher
         dunst         # notifications
         picom         # compositor
         feh           # wallpaper
         xclip         # clipboard
       ];
     Home services
       services = {
         picom.enable = true;
         dunst.enable = true;
       };
     Theming
       gtk = {
         enable = true;
         theme = {
           name = "Tokyonight-Dark";
           package = pkgs.tokyonight-gtk-theme;
         };
       };

       home.sessionVariables = {
         # anything qtile needs in the environment
       };
     }

     Home modules do NOT need a toggle (they only load when the host imports
     them). If you want a toggle for home-module stuff too, use the same pattern
     but with osConfig:

     nix
     { config, pkgs, lib, osConfig, ... }:
     let
       cfg = osConfig.workstation.qtile;   # reach into NixOS config
     in
     {
       config = lib.mkIf cfg.enable {
         # home config here
       };
     }

     File 3: Wire it into a host — devices/desktop/erebos/default.nix

     Two changes:

     nix
     In the imports block:
     imports = [
       ../../../modules/qtile.nix     # ← ADD: load the system module
     ...
     ];
     In the workstation block:
     workstation = {
       qtile.enable = true;           # ← ADD: turn it on
     ...
     };

     File 4: Wire the home module — flake.nix

     nix
     erebos = mkWorkstation {
       deviceModule = ./devices/desktop/erebos/default.nix;
       extraHmImports = [ ./home/qtile.nix ];   # ← ADD: load home config
     };

     The full mental model

     flake.nix
       └─ mkWorkstation
            ├─ deviceModule (e.g., devices/desktop/erebos/default.nix)
            │    ├─ imports → [ modules/qtile.nix, modules/baseline.nix, ... ]
            │    └─ workstation.qtile.enable = true  ← fires the guard
            │
            └─ extraHmImports → [ home/qtile.nix, home/kde.nix, ... ]
                 └─ (runs as home-manager module for user sid)

     System module (modules/qtile.nix) = NixOS options. Does
     programs.xyz.enable, services.xyz, environment.systemPackages. Gated by
     workstation.qtile.enable.

     Home module (home/qtile.nix) = home-manager config. Does home.packages,
     xdg.configFile, programs.rofi, services.dunst. Loaded unconditionally when
     the host imports it (or gated via osConfig.workstation.qtile.enable).

     Device config links both: imports the system module, sets enable = true.

     flake.nix links the home module: extraHmImports.

     To practice, delete the references and rewrite modules/qtile.nix,
     home/qtile.nix, the imports block, and the flake line — all from memory.
     Don't look at the existing files. Then dry-build with nix build --no-link
     '.#nixosConfigurations.erebos.config.system.build.nixos-rebuild' to see if
     it evaluates.

     Want me to set up a practice checklist, or you good?

