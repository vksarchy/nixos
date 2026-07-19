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
      lg = "lazygit";
      nf = "nvim $(fzf --preview 'cat {}')";
      borg_backup = "systemctl restart borgbackup-job-${hostName}-home";
      borg_logs = "journalctl -u borgbackup-job-${hostName}-home";
      port_forward = "while true ; do date ; natpmpc -a 1 0 udp 60 -g 10.2.0.1 && natpmpc -a 1 0 tcp 60 -g 10.2.0.1 || { echo -e 'ERROR with natpmpc command \a' ; break ; } ; sleep 45 ; done";

      nre = "nh os switch .#prometheus";
      re = "sudo nixos-rebuild switch --flake .#prometheus";
      ke = "sudo nixos-rebuild switch --flake .#karuppu";
      ae = "sudo nixos-rebuild switch --flake .#mactheus";

      ytm = "yt-dlp -x";
      yt = "yt-dlp";

      ha = "hledger add";
      py = "python3";
      rm = "trash";

      serv = "systemctl --type=service";
      running = "systemctl --type=service --state=running";
      failed = "systemctl --failed";

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
      (lib.mkOrder 1000 ''
        export EZA_CONFIG_DIR="$HOME/.config/eza"
        export EZA_ICONS_AUTO=1
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
