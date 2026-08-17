{
  config,
  pkgs,
  lib,
  ...
}:
{
  home = {
    username = "sid";
    homeDirectory = "/home/sid";
    stateVersion = "25.05";
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      core.editor = "nvim";
      user.name = "vksarchy";
      user.email = "vks@tutamail.com";
      url."git@github.com:".insteadOf = "https://github.com/";
    };
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "tokyo-night";
      theme_background = true;
      truecolor = true;
    };
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "op" = {
        hostname = "192.168.1.9";
        port = 8022;
        user = "u0_a511";
        identityFile = "~/.ssh/id_ed25519";
      };
      "gp" = {
        hostname = "192.168.1.34";
        port = 8022;
        user = "u0_a231";
        identityFile = "~/.ssh/id_ed25519";
      };
      "prometheus" = {
        hostname = "192.168.1.23";
        user = "sid";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  xdg.configFile = {
    "starship.toml".source = ../config/starship/starship.main.toml;
    "eza/theme.yml".source = ../config/eza/eza.main.yml;
    "fuzzel/fuzzel.ini".source = ../config/fuzzel/tokyonight.fuzzel.ini;
    "fastfetch/config.jsonc".source = ../config/fastfetch/main.fastfetch;
    "fastfetch/violet.png".source = ../config/icons/violet.png;
    "mpv/input.conf".source = ../config/mpv/input.conf;
    # Marshall Woburn II: only register A2DP Source (send audio). Both roles
    # cause reverse AVDTP and "a2dp-sink … Device or resource busy".
    "wireplumber/wireplumber.conf.d/51-woburn-a2dp.conf".source =
      ../config/wireplumber/51-woburn-a2dp.conf;
  };

  # home/common.nix or home/niri.nix
  xdg.desktopEntries = {
    whatsapp = {
      name = "WhatsApp";
      exec = "/home/sid/.local/bin/webapp whatsapp https://web.whatsapp.com";
      icon = "whatsapp";
      terminal = false;
      categories = [
        "Network"
        "InstantMessaging"
      ];
    };

    youtube = {
      name = "YouTube";
      exec = "/home/sid/.local/bin/webapp youtube https://youtube.com";
      terminal = false;
      categories = [ "AudioVideo" ];
    };
  };

  home.file.".local/bin/webapp" = {
    source = ../scripts/webapp;
    executable = true;
  };

  home.file.".local/bin/toggle-audio-sink" = {
    source = ../scripts/toggle-audio-sink;
    executable = true;
  };

  home.file.".local/bin/connect-woburn" = {
    source = ../scripts/connect-woburn;
    executable = true;
  };

  home.file.".local/bin/disconnect-woburn" = {
    source = ../scripts/disconnect-woburn;
    executable = true;
  };

  home.file.".local/bin/toggle-monitor-tv" = {
    source = ../scripts/toggle-monitor-tv;
    executable = true;
  };

  # Android USB file transfer helpers (see modules/android-transfer.nix)
  home.file.".local/bin/phone-mount" = {
    source = ../scripts/phone-mount;
    executable = true;
  };
  home.file.".local/bin/phone-umount" = {
    source = ../scripts/phone-umount;
    executable = true;
  };
  home.file.".local/bin/phone-pull" = {
    source = ../scripts/phone-pull;
    executable = true;
  };
  home.file.".local/bin/phone-status" = {
    source = ../scripts/phone-status;
    executable = true;
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  # Colemak page-turn keys in the Calibre viewer: n = down, e = up
  # (same mapping as yazi). Merged into viewer-webengine.json so we
  # don't clobber window geometry / recently-opened state.
  home.activation.calibreViewerColemakKeys =
    let
      script = pkgs.writeText "calibre-viewer-colemak-keys.py" ''
import json
from pathlib import Path

path = Path.home() / ".config/calibre/viewer-webengine.json"
path.parent.mkdir(parents=True, exist_ok=True)
data = json.loads(path.read_text()) if path.exists() else {}
sd = data.setdefault("session_data", {})
ks = sd.setdefault("keyboard_shortcuts", {})

def key(k):
    return {
        "key": k,
        "altKey": False,
        "ctrlKey": False,
        "metaKey": False,
        "shiftKey": False,
    }

wanted = {
    "up": [key("ArrowUp"), key("e")],
    "down": [key("ArrowDown"), key("n")],
}
if any(ks.get(name) != binding for name, binding in wanted.items()):
    ks.update(wanted)
    path.write_text(json.dumps(data, indent=2) + "\n")
      '';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.python3}/bin/python3 ${script}
    '';
}
