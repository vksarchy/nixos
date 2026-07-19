{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation.torrent;
in
{
  options.workstation.torrent = {
    enable = lib.mkEnableOption "Torrent client (qBittorrent)";

    qbittorrent = lib.mkEnableOption "qBittorrent" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = lib.optionals cfg.qbittorrent [
      pkgs.qbittorrent
    ];

    # Optional: firewall rules (common for torrents)
    # networking.firewall.allowedTCPPorts = [ 6881 ];
    # networking.firewall.allowedUDPPorts = [ 6881 ];
  };
}
