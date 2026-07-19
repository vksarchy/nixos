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
      ];
      description = "Borg exclude patterns";
    };

    startAt = lib.mkOption {
      type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
      default = "daily";
      description = "systemd calendar expression; [ ] means manual only";
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
      environment.BORG_RSH = "ssh -i ${cfg.sshKey} -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30 -o ServerAliveCountMax=6";
      repo = cfg.repo;
      compression = "auto,zstd";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 3;
      };
      startAt = cfg.startAt;
    };

    age.secrets."borg-pass" = {
      file = cfg.passFile;
      owner = "sid";
      group = "users";
      mode = "0400";
    };
  };
}
