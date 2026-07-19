{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.workstation.ssh;
in
{
  options.workstation.ssh.enable = lib.mkEnableOption "Default SSH configuration";
  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = [ "sid" ];
      };
    };
    users.users."sid".openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCDegudlss7m+Xuw8ejEjpvjkZ+Xo8lO6qWGS3sBTrY vks@tutamail.com"
    ];
    networking.firewall.allowedTCPPorts = [ 22 ];
  };
}
