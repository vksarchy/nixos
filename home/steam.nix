{ config, pkgs, lib, ... }:

{

  home.username = "sid";
  home.homeDirectory = "/home/sid";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  programs.bash.initExtra = ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      export XDG_SESSION_TYPE=wayland
      export XDG_CURRENT_DESKTOP=gamescope
      export GAMESCOPE_DEBUG=1
      export GAMESCOPE_DRM_DEVICE=/dev/dri/card0
      export SEATD_SOCK_PATH=/run/seatd.sock

      exec ${pkgs.gamescope}/bin/gamescope \
        --backend drm \
        -W 1920 -H 1080 -f -- \
        ${pkgs.steam}/bin/steam -tenfoot -gamepadui
    fi
  '';
}
