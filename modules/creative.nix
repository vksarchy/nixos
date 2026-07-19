{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation.creative;
in
{
  options.workstation.creative = {
    enable = lib.mkEnableOption "Creative apps suite";

    gimp = lib.mkEnableOption "Gimp" // {
      default = true;
    };
    audacity = lib.mkEnableOption "audacity" // {
      default = true;
    };
    obs = lib.mkEnableOption "OBS" // {
      default = true;
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      lib.optionals cfg.gimp [ pkgs.gimp ]
      ++ lib.optionals cfg.audacity [ pkgs.audacity ]
      ++ lib.optionals cfg.obs [ pkgs.obs-studio ];
  };
}
