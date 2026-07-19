{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation.yazi;
  toml = pkgs.formats.toml { };
in
{
  options.workstation.yazi.enable = lib.mkEnableOption "Yazi configuration";
  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      settings = {
        yazi = {
          ratio = [
            1
            4
            3
          ];
          sort-by = "natural";
          sort-sensitive = true;
          sort-reverse = false;
          sort-dir-first = true;
          linemode = "none";
          show-hidden = true;
          show-symlink = true;
        };

        # Colemak (n e i h) navigation — settings.keymap renders to
        # keymap.toml, the same way settings.yazi renders to yazi.toml
        # (this is the NixOS programs.yazi module, not home-manager's).
        keymap = {
          mgr.prepend_keymap = [
            {
              on = "n";
              run = "arrow next";
              desc = "Next file (colemak j)";
            }
            {
              on = "e";
              run = "arrow prev";
              desc = "Previous file (colemak k)";
            }
            {
              on = "i";
              run = "enter";
              desc = "Enter directory (colemak l)";
            }
            {
              on = "h";
              run = "leave";
              desc = "Parent directory (colemak h)";
            }
            {
              on = "j";
              run = "noop";
              desc = "Disabled (j)";
            }
            {
              on = "k";
              run = "noop";
              desc = "Disabled (k)";
            }
            {
              on = "l";
              run = "noop";
              desc = "Disabled (l)";
            }
            {
              on = "o";
              run = "noop";
              desc = "Disabled (o)";
            }
          ];
        };
      };
    };

    # Override yazi.toml to include [opener]
    # (programs.yazi.settings rejects unknown keys like "opener")
    home-manager.users.sid.xdg.configFile."yazi/yazi.toml" = lib.mkForce {
      source = toml.generate "yazi-toml" {
        yazi = {
          ratio = [
            1
            4
            3
          ];
          sort-by = "natural";
          sort-sensitive = true;
          sort-reverse = false;
          sort-dir-first = true;
          linemode = "none";
          show-hidden = true;
          show-symlink = true;
        };
        opener = {
          edit = [
            {
              run = ''nvim "$@"'';
              block = true;
              desc = "Edit in nvim";
            }
          ];
        };
      };
    };
  };
}
