{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation.retroshare;
in
{
  options.workstation.retroshare.enable =
    lib.mkEnableOption "Syncthing RetroArch share & Vault sync";

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = "sid";
      group = "users";
      dataDir = "/home/sid/sync";
      configDir = "/home/sid/.config/syncthing";
      overrideDevices = false;
      overrideFolders = false;
      openDefaultPorts = true;

      settings = {
        devices = {
          "prometheus" = {
            id = "MYRWYBM-CXQZM3X-3O3QQIW-WPEMPGD-PGRY27U-GPONXF6-WK4QGXK-W4674QM";
          };
          "karuppu" = {
            id = "GU6QLHB-KYUGFTA-DN3ATSO-DDOPEQW-RWUNQVY-F247KIJ-PWYIJCL-EHV2VAF";
          };
        };
        folders = {
          "vks-vault" = {
            id = "vks-vault";
            path = "/home/sid/Obsidian/VKS Vault";
            devices = [ "prometheus" "karuppu" ];
            type = "sendreceive";
          };
          "vimwiki" = {
            id = "vimwiki";
            path = "/home/sid/vimwiki";
            devices = [ "prometheus" "karuppu" ];
            type = "sendreceive";
          };
        };
      };
    };
  };
}
