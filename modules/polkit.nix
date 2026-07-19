{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.workstation.polkit;
in
{
  options.workstation.polkit.enable = lib.mkEnableOption "Enable polkit";

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      polkit_gnome
    ];

    security.polkit.enable = true;

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "net.reactivated.fprint.device.enroll" &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });

      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") == "kanata-main.service" &&
            subject.user == "sid") {
          return polkit.Result.YES;
        }
      });

      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.policykit.exec" &&
            subject.user == "sid") {
          var cmd = action.lookup("command_line") || "";
          if (cmd.indexOf("kanata-switch") !== -1) {
            return polkit.Result.YES;
          }
        }
      });
    '';

    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
