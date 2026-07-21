{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.workstation.baseline.packages;
  future-cursors = pkgs.callPackage ../pkgs/future-cursor.nix { };
  toolsPackages = with pkgs; [
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.nixard.packages.${pkgs.system}.default
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    rsync
    spicetify-cli
    lazygit
    claude-code
    zip
    fzf
    jq
    _7zip-zstd
    unzip
    wget
    git
    htop
    curl
    tree
    eza
    ghostty
    fastfetch
    starship
    lazyssh
    nixfmt
    blueman
    ffmpeg
    whois
    parted
    usbutils
    smartmontools
    pciutils
    file
    dig
    oh-my-zsh
    autojump
    screen
    speedtest
    parallel
    future-cursors
    ani-cli
    yt-dlp
    pomodoro
    dysk
    haskellPackages.hledger
    llama-cpp
    cmatrix
    bat
    rclone
    gvfs
    jmtpfs
    libmtp
    lsof
    psmisc
    simple-mtpfs
    comma
    nh
    direnv
    snixembed
    youtube-tui
    appimage-run
    typer
    trashy
    gh
  ];

  devPackages = with pkgs; [
    rustup
    nodejs
    python3
    cargo
    gcc
    rustlings
    terraform
    distrobox
  ];

  appsPackages = with pkgs; [
    safeeyes
    feh
    drawy
    kdePackages.dolphin
    blanket
    ventoy
    vial
    via
    cbonsai
    genact
    pay-respects
    cool-retro-term
    ponysay
    cowsay
    systemctl-tui
    isd
    systemd-manager-tui
    gamescope
    lynx
    opencode
    upiano
  ];

in
{
  options.workstation.baseline.packages = {
    tools = lib.mkEnableOption "CLI tools and utilities";
    dev = lib.mkEnableOption "Development tools";
    apps = lib.mkEnableOption "Desktop applications";
  };

  config = {
    nixpkgs.config.permittedInsecurePackages = [ "ventoy-1.1.12" ];

    environment.systemPackages =
      (lib.optionals cfg.tools toolsPackages)
      ++ (lib.optionals cfg.dev devPackages)
      ++ (lib.optionals cfg.apps appsPackages);
  };
}
