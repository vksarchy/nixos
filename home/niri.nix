{
  config,
  pkgs,
  lib,
  hostName,
  ...
}:
let
  niriConfigSrc = if hostName == "prometheus" 
    then ../config/niri/config.laptop.kdl 
    else ../config/niri/config.desktop.kdl;
  
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

  # swayidle: idle timeout lock + before-sleep lock (auto-restarted by systemd)
  services.swayidle = {
    enable = true;
    events = {
      "before-sleep" = "noctalia msg session lock";
    };
    timeouts = [
      { timeout = 180; command = "noctalia msg session lock"; }
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
