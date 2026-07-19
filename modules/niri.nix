{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.workstation.niri;
in
{
  options.workstation.niri.enable = lib.mkEnableOption "Niri-based workstation environment with Noctalia Shell";

  config = lib.mkIf cfg.enable {
    programs.niri.enable = true;

    qt = {
      enable = true;
    };

    # Stylix: system-wide base16 theming (GTK, Qt, terminals, etc.)
    stylix = {
      enable = true;
      autoEnable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
      cursor = {
        name = "BreezeX-RosePine-Linux";
        package = pkgs.rose-pine-cursor;
        size = 24;
      };
    };

    environment.systemPackages = with pkgs; [
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      xwayland-satellite
      swayimg
      nemo
      fuzzel
      gpu-screen-recorder
      wl-clipboard
      mpvpaper
      swayidle
    ];

    services.displayManager = {
      ly = {
        enable = true;
        settings = {
          animation = "matrix";
        };
      };
      defaultSession = "niri";
    };
  };
}
