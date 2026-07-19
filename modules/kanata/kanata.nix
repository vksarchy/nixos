# modules/kanata/kanata.nix
# Kanata keyboard remapper with on-the-fly layout switching
#
# Layout files live at /etc/kanata/*.kbd (immutable, from nix store).
# /var/lib/kanata/current.kbd is a symlink to the active layout.
# The kanata-main service reads from that symlink.
# kanata-switch script updates the symlink + restarts the service.
# Default layout is "colemak" (set via workstation.kanata.layout option).

{ config, lib, pkgs, ... }:

let
  cfg = config.workstation.kanata;

  # Available layouts — add new .kbd files here and to the enum below
  layoutNames = [ "cheapino" "colemak" "corne" "qwerty" ];

  switchScript = pkgs.writeShellScriptBin "kanata-switch" ''
    set -euo pipefail

    LAYOUT="''${1:-}"
    LAYOUT_DIR="/etc/kanata"
    CURRENT_LINK="/var/lib/kanata/current.kbd"

    list_layouts() {
      echo "Available layouts:"
      for f in "$LAYOUT_DIR"/*.kbd; do
        [ -f "$f" ] && printf '  %s\n' "$(basename "$f" .kbd)"
      done
    }

    case "$LAYOUT" in
      ${lib.concatStringsSep "|" layoutNames})
        ;;
      "")
        list_layouts
        exit 0
        ;;
      *)
        echo "Error: unknown layout '$LAYOUT'" >&2
        list_layouts >&2
        exit 1
        ;;
    esac

    if [ ! -f "$LAYOUT_DIR/$LAYOUT.kbd" ]; then
      echo "Error: layout file not found: $LAYOUT_DIR/$LAYOUT.kbd" >&2
      exit 1
    fi

    ln -sfn "$LAYOUT_DIR/$LAYOUT.kbd" "$CURRENT_LINK" || {
      echo "Error: failed to update symlink (try running with sudo)" >&2
      exit 1
    }

    if command -v systemctl >/dev/null 2>&1; then
      systemctl restart kanata-main || {
        echo "Error: failed to restart kanata-main service (try running with sudo)" >&2
        exit 1
      }
    fi

    echo "Kanata layout switched to: $LAYOUT"
  '';

in {
  options.workstation.kanata = {
    enable = lib.mkEnableOption "Kanata keyboard remapper";

    layout = lib.mkOption {
      type = lib.types.enum layoutNames;
      default = "colemak";
      description = ''
        Default keyboard layout used on first boot (before any runtime switch).
        After the first boot, the last-selected layout persists via
        /var/lib/kanata/current.kbd and survives rebuilds.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Add kanata and the switch script to PATH
    environment.systemPackages = with pkgs; [ kanata switchScript ];

    # Place layout files in /etc/kanata/ (read-only, from nix store)
    environment.etc."kanata/cheapino.kbd".source = ./cheapino.kbd;
    environment.etc."kanata/colemak.kbd".source = ./colemak.kbd;
    environment.etc."kanata/corne.kbd".source = ./corne.kbd;
    environment.etc."kanata/qwerty.kbd".source = ./qwerty.kbd;

    # Kanata systemd service — reads from mutable symlink
    systemd.services.kanata-main = {
      description = "Kanata keyboard remapper";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        # Create the state directory and initial symlink on first boot.
        # On subsequent boots, the symlink from the last runtime switch persists.
        ExecStartPre = "${pkgs.bash}/bin/bash -c '"
          + "mkdir -p /var/lib/kanata && "
          + "[ -L /var/lib/kanata/current.kbd ] || "
          + "ln -sf /etc/kanata/${cfg.layout}.kbd /var/lib/kanata/current.kbd"
          + "'";

        ExecStart = "${pkgs.kanata}/bin/kanata "
          + "--cfg /var/lib/kanata/current.kbd "
          + "--no-wait";

        Restart = "always";

        # Groups for input device access
        SupplementaryGroups = [
          config.users.groups.input.name or "input"
          config.users.groups.uinput.name or "uinput"
        ];

        # Hardening (adapted from nixpkgs kanata module)
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [
          "/dev/uinput rw"
          "char-input r"
        ];
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateNetwork = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = [ "native" ];
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@resources"
        ];
        UMask = "0077";
      };
    };

    # Allow passwordless sudo for kanata-switch so keybindings work
    security.sudo.extraRules = [
      {
        users = [ "sid" ];
        commands = [
          {
            command = "${switchScript}/bin/kanata-switch";
            options = [ "NOPASSWD" "SETENV" ];
          }
        ];
      }
    ];

    # Required for kanata to create virtual input devices
    hardware.uinput.enable = true;

    # Add user to groups needed for input device access
    users.users.sid.extraGroups = [
      "input"
      "uinput"
    ];
  };
}
