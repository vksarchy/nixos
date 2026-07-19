# Note that baseline packages are now in ./packages.nix, and nested into the workstation.baseline module
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.workstation.baseline;
in
{
  options.workstation.baseline.enable = lib.mkEnableOption "Baseline workstation configuration";

  config = lib.mkIf cfg.enable {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    nixpkgs.config.allowUnfree = true;

    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      kernelPackages = pkgs.linuxPackages_latest;
      kernelModules = [ "uvcvideo" ];
    };

    hardware.enableAllFirmware = true;

    networking.networkmanager.enable = true;

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    time.timeZone = "Asia/Kolkata";

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
    };

    users.users.sid = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = [
        "wheel"
        "networkmanager"
        "input"
        "sound"
        "video"
        "audio"
        "libvirtd"
        "borg"
      ];
    };

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
          FastConnectable = false;
        };
        Policy = {
          AutoEnable = true;
        };
      };
    };

    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.sauce-code-pro
        nerd-fonts.geist-mono
        inter
        alegreya
      ];
      fontconfig = {
        enable = true;
        defaultFonts = {
          sansSerif = [
            "Inter"
            "Noto Sans"
          ];
          serif = [ "Noto Serif" ];
          monospace = [ "JetBrainsMono Nerd Font" ];
        };
      };
      fontDir.enable = true;
    };

    programs.dconf.enable = true;

    programs.zsh.enable = true;
    environment.pathsToLink = [ "/share/zsh" ];

    services = {
      tailscale.enable = true;
      pcscd.enable = true; # yubikey dep
      libinput.enable = true;
      upower.enable = true;
      power-profiles-daemon.enable = true;
      pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
      };
    };
    security.rtkit.enable = true;

    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    system.stateVersion = "25.05";
  };
}
