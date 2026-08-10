{
  config,
  pkgs,
  lib,
  hostName,
  ...
}:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # This handles the fast caching for Nix
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    autocd = true;
    shellAliases = {
      ls = "eza";
      tm = "tmux";
      nv = "nvim";
      whereami = "echo ${hostName}";
      battery-health = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
      lh = "lazyssh";
      ya = "yazi";
      # Android USB: mount MTP → yazi; bulk pull via ADB
      pm = "phone-mount";
      pu = "phone-umount";
      pp = "phone-pull";
      psphone = "phone-status";
      lg = "lazygit";
      nf = "nvim $(fzf --preview 'cat {}')";
      borg_backup = "systemctl restart borgbackup-job-${hostName}-home";
      borg_logs = "journalctl -u borgbackup-job-${hostName}-home";
      port_forward = "while true ; do date ; natpmpc -a 1 0 udp 60 -g 10.2.0.1 && natpmpc -a 1 0 tcp 60 -g 10.2.0.1 || { echo -e 'ERROR with natpmpc command \a' ; break ; } ; sleep 45 ; done";

      # rebuild the machine you're currently on
      nre = "nh os switch .#${hostName}";
      re = "sudo nixos-rebuild switch --flake .#${hostName}";

      # optional: still rebuild a *specific* other host by name
      re-prometheus = "sudo nixos-rebuild switch --flake .#prometheus";
      re-karuppu = "sudo nixos-rebuild switch --flake .#karuppu";
      re-mactheus = "sudo nixos-rebuild switch --flake .#mactheus";

      ke = "sudo nixos-rebuild switch --flake .#karuppu";
      ae = "sudo nixos-rebuild switch --flake .#mactheus";

      ytm = "yt-dlp -x";
      yt = "yt-dlp";

      ha = "hledger add";
      py = "python3";
      rm = "trash";

      # PDF → Markdown (loads Dev-Projects/pdftomd env via direnv; works from any cwd)
      pdfmd = "direnv exec $HOME/Dev-Projects/pdftomd pdfmd";

      serv = "systemctl --type=service";
      running = "systemctl --type=service --state=running";
      failed = "systemctl --failed";

      # Corne v4: USB freeze diagnostics (error -71 / disconnects)
      corne-watch = "journalctl -kf --no-hostname | rg -i --line-buffered 'usb 1-1|foostan|Corne|error -71|device descriptor|device not accept'";
      corne-log = "journalctl -b --no-pager --no-hostname | rg -i 'usb 1-1:.*(disconnect|reset|error|not respond)|foostan Corne'";

    };
    initContent = lib.mkMerge [
      (lib.mkOrder 100 ''
        if [ -z "$TMUX" ]; then
          ws=$(niri msg focused-window 2>/dev/null | grep "Workspace ID:" | awk '{print $NF}')
          [ -z "$ws" ] && ws="tty"
          exec tmux new-session -A -s "ws-$ws"
        fi                '')

      (lib.mkOrder 500 ''
        # fzf keybindings: Ctrl-T (files), Ctrl-R (history), Alt-C (cd)
        source "${pkgs.fzf}/share/fzf/key-bindings.zsh"

        # Ctrl-T: file/dir search with compact preview (right pane, 35% width)

        export FZF_CTRL_T_OPTS="--preview 'cat -n {} 2>/dev/null | head -500 || eza --tree --level=2 --color=always {} 2>/dev/null' --preview-window 'right,35%,wrap,border-left'"

        # Ctrl-R: history with preview (for multi-line commands)
        export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window 'down,3,hidden'"
      '')
      (lib.mkOrder 900 ''
        # Anthropic API key: decrypted by agenix at boot, never in this repo
        if [ -r /run/agenix/anthropic-key ]; then
          export ANTHROPIC_API_KEY="$(< /run/agenix/anthropic-key)"
        fi
        # DeepSeek key for howcopy: point at the agenix-decrypted file rather
        # than exporting the raw value, so it never sits in `env` output.
        if [ -r /run/agenix/deepseek-key ]; then
          export HOWCOPY_DEEPSEEK_API_KEY_FILE=/run/agenix/deepseek-key
        fi
      '')
      (lib.mkOrder 1000 ''
        export EZA_CONFIG_DIR="$HOME/.config/eza"
        export EZA_ICONS_AUTO=1

        # Corne v4 USB power / presence check
        corne-status() {
          echo "=== lsusb ==="
          lsusb | rg -i 'corne|4653' || echo "(not present)"
          echo "=== power ==="
          local found=0
          for d in /sys/bus/usb/devices/*; do
            [ -f "$d/idVendor" ] || continue
            [ "$(cat "$d/idVendor" 2>/dev/null)" = "4653" ] || continue
            found=1
            printf '%s product=%s control=%s autosuspend=%s runtime=%s\n' \
              "$d" \
              "$(cat "$d/product" 2>/dev/null)" \
              "$(cat "$d/power/control" 2>/dev/null)" \
              "$(cat "$d/power/autosuspend" 2>/dev/null)" \
              "$(cat "$d/power/runtime_status" 2>/dev/null)"
          done
          [ "$found" -eq 1 ] || echo "(no sysfs node for 4653)"
          echo "=== kanata ==="
          systemctl is-active kanata-main 2>/dev/null || true
        }
      '')
      (lib.mkOrder 1500 ''
        eval "$(${pkgs.starship}/bin/starship init zsh)"
      '')
    ];
    history.size = 10000;
    oh-my-zsh = {
      enable = true;
      package = pkgs.oh-my-zsh;
      plugins = [
        "autojump"
        "terraform"
      ];
    };
  };
}
