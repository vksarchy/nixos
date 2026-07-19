{ lib, ... }:
{
  options.workstation.emacs.enable = lib.mkEnableOption "emacs";
}
