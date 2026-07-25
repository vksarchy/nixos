{
  config,
  lib,
  ...
}:
let
  cfg = config.workstation.backup;
  jobName = "${config.networking.hostName}-home";
in
{
  options.workstation.backup = {
    enable = lib.mkEnableOption "Borg backup of /home/sid";

    repo = lib.mkOption {
      type = lib.types.str;
      description = "Borg repository URL, e.g. ssh://user@host:port/path";
    };

    paths = lib.mkOption {
      type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
      default = "/home/sid";
      description = "What to back up";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/home/sid/.cache"
        "/home/sid/.nix-defexpr"
        "/home/sid/.nix-profile"
        "/home/sid/.mozilla"
        "/home/sid/.pki"
        "/home/sid/.steam"
        "/home/sid/.terraform.d"
        "/home/sid/.var"
        # Large regenerable / game / package caches
        "/home/sid/.local"
        "/home/sid/.npm"
        "/home/sid/.paradoxinteractive"
        "/home/sid/.paradoxlauncher"
        "/home/sid/Videos"
        "/home/sid/Games"
        # Note: do not exclude all of Downloads here — hosts often list
        # /home/sid/Downloads/Epubs as an explicit path (excludes win over paths).
      ];
      description = "Borg exclude patterns";
    };

    startAt = lib.mkOption {
      type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
      # Midday: laptop more likely online than midnight
      default = "*-*-* 12:00:00";
      description = "systemd calendar expression; [ ] means manual only";
    };

    persistent = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "If true, catch up a missed timer after boot (important for laptops)";
    };

    passFile = lib.mkOption {
      type = lib.types.path;
      description = "agenix-encrypted borg passphrase for this host";
    };

    sshKey = lib.mkOption {
      type = lib.types.str;
      default = "/home/sid/.ssh/borg";
      description = "SSH key used to reach the borg repo";
    };
  };

  config = lib.mkIf cfg.enable {
    services.borgbackup.jobs.${jobName} = {
      paths = cfg.paths;
      exclude = cfg.exclude;
      encryption.mode = "repokey";
      encryption.passCommand = "cat ${config.age.secrets."borg-pass".path}";
      # -F /dev/null: ignore broken world-writable HM ssh config
      # IdentitiesOnly: only the borg key (no agent spam)
      environment.BORG_RSH = "ssh -i ${cfg.sshKey} -F /dev/null -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30 -o ServerAliveCountMax=6";
      repo = cfg.repo;
      compression = "auto,zstd";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 3;
      };
      startAt = cfg.startAt;
    };

    # Catch up if the machine was off when the calendar fired.
    # nixpkgs borgbackup defaults Persistent=false — force override.
    systemd.timers."borgbackup-job-${jobName}" = lib.mkIf cfg.persistent {
      timerConfig.Persistent = lib.mkForce true;
    };

    age.secrets."borg-pass" = {
      file = cfg.passFile;
      owner = "sid";
      group = "users";
      mode = "0400";
    };
  };
}
