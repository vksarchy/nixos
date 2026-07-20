{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/profiles/workstation.nix
  ];

  config = {
    networking.hostName = "karuppu";

    hardware.cpu.amd.updateMicrocode = true;

    # AMD GPU + Vulkan support
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vulkan-tools
        rocmPackages.clr
      ];
    };

    workstation = {
      profile.enable = true;

      surfshark = {
        enable = true;
        privateKeyFile = config.age.secrets.surfshark-key.path;
        endpoint = "sg-sng.prod.surfshark.com:51820";
        serverPublicKey = "MGfgkhJsMVMTO33h1wr76+z6gQr/93VcGdClfbaPsnU=";
        address = [ "10.14.0.2/16" ];
        dns = [
          "162.252.172.57"
          "149.154.159.92"
        ];
      };
    };

    # ── Age secrets ──
    age.secrets.surfshark-key.file = ../../../secrets/surfshark-key.age;
    age.secrets.anthropic-key = {
      file = ../../../secrets/anthropic-key.age;
      owner = "sid";
      mode = "0400";
    };

    # ── Extra system packages ──
    environment.systemPackages = with pkgs; [
      nix.doc
    ];
  };
}
