{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation.office;
in

{
  options.workstation.office = {
    enable = lib.mkEnableOption "Office suite for Nixos";

    obsidian = lib.mkEnableOption "Obsidian" // {
      default = true;
    };
    calculator = lib.mkEnableOption "Gnome Calculator" // {
      default = true;
    };
    # libreoffice = lib.mkEnableOption "libreoffice" // {default = false;};
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      lib.optionals cfg.calculator [ pkgs.gnome-calculator ]
      ++ lib.optionals cfg.obsidian [ pkgs.obsidian ];
    # ++ lib.optionals cfg.libreoffice [ pkgs.libreoffice ];
  };

}
