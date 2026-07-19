{
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/profiles/workstation.nix
  ];

  config = {
    networking.hostName = "mactheus";

    hardware.cpu.intel.updateMicrocode = true;

    workstation = {
      profile = {
        enable = true;
        full = false;
      };

      tmux = {
        accent = "#A3BE8C"; # Nord green
        accentSecondary = "#5E81AC"; # Nord blue
      };

      # Steam only — no lutris/bottles/etc on this machine
      gaming = {
        enable = true;
        lutris = false;
        bottles = false;
        pokerth = false;
        mangohud = false;
        gamemode = false;
      };
    };

    environment.systemPackages = with pkgs; [
      # v4l-utils
      pkgs.nix.doc
    ];
  };
}
