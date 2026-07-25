# Shared workstation profile: every workstation imports this and gets the
# common set. Heavy desktop extras are gated by workstation.profile.full.
# Everything is mkDefault so device files can override per-machine.
{
  config,
  lib,
  ...
}:
let
  cfg = config.workstation.profile;
in
{
  imports = [
    # Core
    ../baseline.nix
    ../packages.nix
    ../polkit.nix
    ../ssh.nix
    ../backup.nix
    # Desktop
    ../niri.nix
    ../kanata/kanata.nix
    # Tools & Productivity
    ../nixvim.nix
    ../yazi.nix
    ../tmux.nix
    ../zennotes.nix
    ../emacs/system.nix
    ../localsend.nix
    ../android-transfer.nix
    ../stt.nix
    # Gaming & Graphics
    ../gaming.nix
    ../virtualization.nix
    # Communication & Media
    ../comms.nix
    ../media.nix
    ../office.nix
    ../creative.nix
    ../books.nix
    # AI & Development
    ../ai.nix
    ../browser.nix
    ../torrent.nix
    # Networking & Extras
    ../surfshark.nix
    ../hermes.nix
    ../retroshare.nix
    # Flatpak
    ../flatpak.nix
  ];

  options.workstation.profile = {
    enable = lib.mkEnableOption "Shared workstation profile";

    full = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Heavy desktop set: gaming, virtualization, comms, media, creative, office, AI, browser, torrent, retroshare";
    };
  };

  config = lib.mkIf cfg.enable {
    workstation = {
      # ── Common set (every machine) ──
      baseline = {
        enable = lib.mkDefault true;
        packages = {
          tools = lib.mkDefault true;
          dev = lib.mkDefault true;
          apps = lib.mkDefault true;
        };
      };

      niri.enable = lib.mkDefault true;
      kanata = {
        enable = lib.mkDefault true;
        layout = lib.mkDefault "colemak";
      };

      nixvim.enable = lib.mkDefault true;
      yazi.enable = lib.mkDefault true;
      tmux.enable = lib.mkDefault true;
      zennotes.enable = lib.mkDefault true;
      emacs.enable = lib.mkDefault true;
      localsend.enable = lib.mkDefault true;
      androidTransfer.enable = lib.mkDefault true;
      stt.enable = lib.mkDefault true;
      polkit.enable = lib.mkDefault true;
      ssh.enable = lib.mkDefault true;
      hermes.enable = lib.mkDefault true;

      flatpak = {
        enable = lib.mkDefault true;
        onCalendar = lib.mkDefault "weekly";
        packages = lib.mkDefault [
          "flathub:app/app.zen_browser.zen//stable"
          "flathub:app/com.github.tchx84.Flatseal//stable"
          "flathub:app/org.onlyoffice.desktopeditors//stable"
        ];
      };

      # ── Full set (desktop-class machines; mactheus opts out) ──
      gaming.enable = lib.mkDefault cfg.full;
      virtualization.enable = lib.mkDefault cfg.full;
      comms = {
        enable = lib.mkDefault cfg.full;
        element = lib.mkDefault false;
      };
      media = {
        enable = lib.mkDefault cfg.full;
        feishin = lib.mkDefault false;
        jellyfin = lib.mkDefault false;
      };
      creative.enable = lib.mkDefault cfg.full;
      office.enable = lib.mkDefault cfg.full;
      ai.enable = lib.mkDefault cfg.full;
      browser.enable = lib.mkDefault cfg.full;
      torrent.enable = lib.mkDefault cfg.full;
      retroshare.enable = lib.mkDefault cfg.full;
    };
  };
}
