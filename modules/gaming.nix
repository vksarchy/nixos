{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation.gaming;
in
{
  options.workstation.gaming = {
    enable = lib.mkEnableOption "Gaming suite (Steam + tools)";

    steam = lib.mkEnableOption "Steam client" // {
      default = true;
    };
    remotePlay = lib.mkEnableOption "Steam Remote Play" // {
      default = true;
    };
    dedicatedServer = lib.mkEnableOption "Steam Dedicated Server" // {
      default = true;
    };

    lutris = lib.mkEnableOption "Lutris" // {
      default = true;
    };
    gamemode = lib.mkEnableOption "GameMode" // {
      default = true;
    };
    mangohud = lib.mkEnableOption "MangoHud" // {
      default = true;
    };
    bottles = lib.mkEnableOption "Bottles" // {
      default = true;
    };
    vulkan = lib.mkEnableOption "Vulkan tools" // {
      default = true;
    };
    pokerth = lib.mkEnableOption "PokerTH" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = cfg.steam;
      remotePlay.openFirewall = cfg.remotePlay;
      dedicatedServer.openFirewall = cfg.dedicatedServer;
    };

    programs.gamemode.enable = cfg.gamemode;

    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    environment.systemPackages =
      lib.optionals cfg.lutris [ pkgs.lutris ]
      ++ lib.optionals cfg.mangohud [ pkgs.mangohud ]
      ++ lib.optionals cfg.bottles [ pkgs.bottles ]
      ++ lib.optionals cfg.vulkan [ pkgs.vulkan-tools ]
      ++ lib.optionals cfg.pokerth [ pkgs.pokerth ];
  };
}
