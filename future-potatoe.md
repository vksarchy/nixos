
Potato playbook (future reference)

1. How toggles work now

Every feature = module with workstation.<name>.enable. Profile (modules/profiles/workstation.nix) sets defaults via lib.mkDefault — meaning: profile suggests, device file always overrides. Two dials exist:

- workstation.profile.enable — common set (niri, kanata, nixvim, yazi, tmux, stt, emacs, hermes, flatpak...)
- workstation.profile.full — heavy set (gaming, virtualization, comms, media, creative, office, ai, browser, torrent, retroshare). full = true on prometheus/karuppu; mactheus already runs full = false.

2. New potato machine — recipe

# devices/potato/spudnik/default.nix
{ ... }:
{
  imports = [
    ./hardware-configuration.nix          # from nixos-generate-config on the machine
    ../../modules/profiles/workstation.nix
  ];

  config = {
    networking.hostName = "spudnik";

    workstation = {
      profile = {
        enable = true;
        full = false;                     # heavy set of
      };

      # Trim common set further — device file beats profile's mkDefault:
      niri.enable = false;                # no composito
      stt.enable = false;                 # whisper too heavy
      emacs.enable = false;

      # Cherry-pick one heavy thing back on despite full
      torrent.enable = true;
    };
  };
}

Then one block in flake.nix:

spudnik = mkWorkstation { deviceModule = ./devices/potatoe};

That's whole ceremony. Rule: profile = defaults, device  profile for one machine's need.

3. Adding a brand-new module

Pattern every module in modules/ already follows — copy

# modules/foo.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.workstation.foo;
in
{
  options.workstation.foo.enable = lib.mkEnableOption "Foo";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.foo ];
    # services, timers, whatever
  };
}

Then two lines in profile: add ../foo.nix to imports, adtrue; (or lib.mkDefault cfg.full if heavy). Done — allmachines get it, potatoes override with foo.enable = false. Import is free; only enable = true costs anything.
