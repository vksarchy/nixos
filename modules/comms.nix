{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation.comms;
in
{
  options.workstation.comms = {
    enable = lib.mkEnableOption "Comms package";

    discord = lib.mkEnableOption "Discord App" // {
      default = true;
    };
    element = lib.mkEnableOption "Element App" // {
      default = true;
    };
    telegram = lib.mkEnableOption "Telegram App" // {
      default = true;
    };
    kotatogram = lib.mkEnableOption "Kotatogram App" // {
      default = false;
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      lib.optionals cfg.discord [ pkgs.discord ]
      ++ lib.optionals cfg.telegram [ pkgs.telegram-desktop ]
      ++ lib.optionals cfg.kotatogram [ pkgs.kotatogram-desktop ]
      ++ lib.optionals cfg.element [ pkgs.element-desktop ];
  };
}
