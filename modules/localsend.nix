{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation.localsend;
in
{
  options.workstation.localsend.enable = lib.mkEnableOption "LocalSend file sharing";
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.localsend ];
    networking.firewall.allowedTCPPorts = [ 53317 ];
    networking.firewall.allowedUDPPorts = [ 53317 ];
  };
}
