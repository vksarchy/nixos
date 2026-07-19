{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.workstation.flatpak;
in
{
  options.workstation.flatpak = {
    enable = lib.mkEnableOption "Flatpak configuration";

    remotes = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        flathub = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      };
      description = "Flatpak remotes";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Flatpak(s) to install";
      example = [
        "flathub:app/org.kde.index//stable"
        "flathub-beta:app/org.kde.kdenlive/x86_64/stable"
      ];
    };

    overrides = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.attrsOf (
          lib.types.attrsOf (
            lib.types.either
              (lib.types.listOf (
                lib.types.oneOf [
                  lib.types.str
                  lib.types.number
                  lib.types.path
                  lib.types.attrs
                ]
              ))
              (
                lib.types.oneOf [
                  lib.types.str
                  lib.types.number
                  lib.types.path
                  lib.types.attrs
                ]
              )
          )
        )
      );
      default = { };
      description = "Flatpak overrides";
    };

    veryVerbose = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enables verbose logging";
    };

    flatpakDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Custom flatpak data directory - default is /var/lib/flatpak.";
    };

    forceRunOnActivation = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run sync on every system activation (updates flatpaks)";
    };

    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = "Periodic flatpak sync (updates)";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.flatpak-repo.enable = lib.mkForce false;

    services.flatpak = {
      enable = true;
      remotes = cfg.remotes;
      packages = cfg.packages;
      overrides = cfg.overrides;
      veryVerbose = cfg.veryVerbose;
      flatpakDir = cfg.flatpakDir;
      forceRunOnActivation = cfg.forceRunOnActivation;
      onCalendar = cfg.onCalendar;

      # optional hooks
      preRemotesCommand = "";
      preInstallCommand = "";
      preSwitchCommand = "";
      UNCHECKEDfinalizeCommand = "";
    };
  };
}
