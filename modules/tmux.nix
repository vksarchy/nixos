{ config, pkgs, lib, ... }:
let
  cfg = config.workstation.tmux;
in
{
  options.workstation.tmux = {
    enable = lib.mkEnableOption "tmux with your exact Arch Linux configuration";
    accent = lib.mkOption {
      type = lib.types.str;
      default = "#9CA3AF";
      description = "Primary accent color for tmux status bar (hex)";
    };
    accentSecondary = lib.mkOption {
      type = lib.types.str;
      default = "#6B7280";
      description = "Secondary accent color for tmux status bar (hex)";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      keyMode = "vi";
      historyLimit = 1000000;
      escapeTime = 0;
      baseIndex = 1;

      plugins = with pkgs.tmuxPlugins; [
        vim-tmux-navigator
        resurrect
        continuum
        cpu
      ];

      extraConfig = ''
        # === Plugins config ===
        set -g @resurrect-capture-pane-contents 'on'
        set -g @continuum-save-interval '15'

        # === Your exact config from Arch ===
        set -g default-terminal "tmux-256color"
        set -g mouse on
        setw -g aggressive-resize on

        # Prefix: Alt+s
        unbind C-b
        set -g prefix M-s
        bind M-s send-prefix

        set -ga terminal-overrides ",*256col*:Tc"

        set -g set-clipboard on
        set -g detach-on-destroy off
        set -g status-interval 2
        set -g allow-passthrough on
        set -g status-position top

        # Keybindings
        unbind r
        bind r command-prompt -I "#W" "rename-window -- '%%'"

        unbind %
        bind \\ split-window -h -c "#{pane_current_path}"

        unbind \"
        bind - split-window -v -c "#{pane_current_path}"

        # bind u new-window -c "#{pane_current_path}"

        # Pane navigation (prefix + n/e/m/o)
        bind n select-pane -L
        bind e select-pane -R
        bind m select-pane -U
        bind i select-pane -D

        # Next/Previous window (prefix + l/y)
        bind y next-window
        bind u previous-window

        # Vim-style resize
        bind -r j resize-pane -D 5
        bind -r k resize-pane -U 5
        bind -r h resize-pane -L 5
        bind -r l resize-pane -R 5

        # Copy mode
        bind-key -T copy-mode-vi 'v' send -X begin-selection
        bind -T copy-mode-vi 'y' send-keys -X copy-pipe-and-cancel "wl-copy"
        bind p paste-buffer
        unbind -T copy-mode-vi MouseDragEnd1Pane

        set -g renumber-windows on
        set -g pane-base-index 1

# === Styling (Neutral Theme — lemon green wallpaper / noctalium ) ===
    set -g status-style "fg=#E2E8F0,bg=#0F172A"

    set -g status-left "#[fg=#9CA3AF,bold] #S #[fg=#6B7280] "
    set -g status-right "#[fg=#6B7280]#[fg=#0F172A,bg=#6B7280,bold]  #{cpu_percentage}  #{ram_percentage} #[fg=#6B7280,bg=default] #[fg=#E2E8F0]%H:%M "

    set -g window-status-format " #[fg=#475569]#I:#W "
    set -g window-status-current-format "#[fg=#0F172A,bg=#9CA3AF,bold] #I:#W #[fg=#9CA3AF,bg=default]"
    set -g window-status-separator ""

    set -g pane-border-style "fg=#1E293B"
    set -g pane-active-border-style "fg=#9CA3AF"
    set -g pane-border-lines "single"

    set -g message-style "fg=#0F172A,bg=#9CA3AF,bold"
    set -g mode-style "fg=#0F172A,bg=#6B7280,bold"
      '';
    };
  };
}
