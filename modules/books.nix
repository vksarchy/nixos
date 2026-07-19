{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation.books;
in
{
  options.workstation.books = {
    enable = lib.mkEnableOption "Books Apps on my nix";

    komga = lib.mkEnableOption "Komga server" // {
      default = true;
    };
    calibre = lib.mkEnableOption "Calibre App" // {
      default = true;
    };
    foliate = lib.mkEnableOption "Foliate App" // {
      default = true;
    };
    zathura = lib.mkEnableOption "Zathura App" // {
      default = true;
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      lib.optionals cfg.komga [ pkgs.komga ]
      ++ lib.optionals cfg.calibre [ pkgs.calibre ]
      ++ lib.optionals cfg.foliate [ pkgs.foliate ]
      ++ lib.optionals cfg.zathura [ pkgs.zathura ];
  };
}
