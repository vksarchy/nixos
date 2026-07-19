{ config, lib, pkgs, ... }:

let
  cfg = config.workstation.zennotes;
in
{
  options.workstation.zennotes.enable =
    lib.mkEnableOption "ZenNotes";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.callPackage ../pkgs/zennotes/default.nix { })
    ];
  };
}
