{
  config,
  pkgs,
  lib,
  hostName,
  inputs,
  ...
}:
let
  niriConfigSrc =
    if hostName == "prometheus" then
      ../config/niri/config.laptop.kdl
    else
      ../config/niri/config.desktop.kdl;

  # Absolute path required: swayidle's systemd unit only puts bash on PATH,
  # so bare `noctalia` fails with "command not found" (see journal).
  noctaliaBin = lib.getExe inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  lockCmd = "${noctaliaBin} msg session lock";
in
{
  xdg.configFile = {
    "niri/config.kdl".source = niriConfigSrc;
    "niri/noctalia.kdl".source = ../config/niri/noctalia.kdl;
    "ghostty/config".source = ../config/ghostty/tokyo-night.ghostty;
    "niri/scripts/smart-auto-hide-bar.sh" = {
      source = ../config/niri/smart-auto-hide-bar.sh;
      executable = false;
    };
  };

  # swayidle: 3 min idle lock + before-sleep lock on lid/suspend (Restart=always)
  services.swayidle = {
    enable = true;
    events = [
      { event = "before-sleep"; command = lockCmd; }
    ];
    timeouts = [
      { timeout = 180; command = lockCmd; }
    ];
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  stylix = {
    autoEnable = false;
    targets = {
      gtk.enable = true;
      qt.enable = true;
    };
  };
}
