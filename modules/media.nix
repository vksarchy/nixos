{ config, lib, pkgs, ... }:
let
  cfg = config.workstation.media;
in
{
  options.workstation.media = {
    enable = lib.mkEnableOption "Media consumption & management tools";

    jellyfin = lib.mkEnableOption "Jellyfin desktop client" // { default = true; };
    feishin = lib.mkEnableOption "Feishin (Subsonic client)" // { default = true; };
    picard = lib.mkEnableOption "MusicBrainz Picard" // { default = true; };
    termusic = lib.mkEnableOption "Termusic (terminal music player)" // { default = true; };
    vlc = lib.mkEnableOption "VLC media player" // { default = true; };
    mpv = lib.mkEnableOption "MPV media player" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      lib.optionals cfg.jellyfin [ pkgs.jellyfin-desktop ]
      ++ lib.optionals cfg.feishin [ pkgs.feishin ]
      ++ lib.optionals cfg.picard [ pkgs.picard ]
      ++ lib.optionals cfg.termusic [ pkgs.termusic ]
      ++ lib.optionals cfg.vlc [ pkgs.vlc ]
      ++ lib.optionals cfg.mpv [ pkgs.mpv ];
  };
}
