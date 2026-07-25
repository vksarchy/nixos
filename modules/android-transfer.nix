# Android ↔ NixOS USB file transfer (MTP + ADB).
# Mount with `phone-mount`, browse with yazi, unmount with `phone-umount`.
# For bulk/high-speed: enable USB debugging once, then `phone-pull` / `adb pull`.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation.androidTransfer;
in
{
  options.workstation.androidTransfer.enable =
    lib.mkEnableOption "Android USB file transfer (MTP mounts + ADB)";

  config = lib.mkIf cfg.enable {
    # MTP backend for desktop integration + libmtp udev rules + udisks2 + fuse
    services.gvfs.enable = true;

    # Allow non-owner access to FUSE mounts (yazi in another process, etc.)
    programs.fuse.userAllowOther = true;

    environment.systemPackages = with pkgs; [
      # FUSE MTP mounts (try in this order via phone-mount)
      jmtpfs
      simple-mtpfs
      go-mtpfs
      # CLI detection / low-level MTP tools
      libmtp
      # Reliable GUI + aft-mtp-mount CLI fallback
      android-file-transfer
      # ADB: usually more reliable and faster for bulk transfers than FUSE MTP
      android-tools
    ];

    # Ensure mount point exists for the primary user
    systemd.tmpfiles.rules = [
      "d /home/sid/mnt/phone 0755 sid users -"
      "d /home/sid/mnt 0755 sid users -"
    ];
  };
}
