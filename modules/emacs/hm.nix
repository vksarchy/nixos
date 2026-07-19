{ config, lib, pkgs, osConfig, ... }:
let
  cfg = osConfig.workstation.emacs;

  doomSrc = pkgs.fetchgit {
    url = "https://github.com/doomemacs/doomemacs";
    rev = "bcfc0db7e71f99bfcebf05cab1cf2934bb5a334c";
    sha256 = "sha256-NsjmyVAQPwYXqtBM3vw+XnW9DMoCWOhGI5ALXeEF7aA=";
    fetchSubmodules = true;
  };

  # Base emacs with tree-sitter grammars
  emacsPkg = pkgs.emacs-pgtk.pkgs.withPackages (epkgs: [
    epkgs.treesit-grammars.with-all-grammars
  ]);

  # Wrapped emacs so straight.el builds (vterm, etc.) can find glib headers.
  # On NixOS, home.packages installs into the user profile, but that doesn't
  # automatically add .dev headers to the cc wrapper's search path.  Setting
  # NIX_CFLAGS_COMPILE and PKG_CONFIG_PATH on the wrapped binary means any
  # compiler spawned by emacs (via cmake + cc) will find glib.h.
  # glibconfig.h lives in the main glib output (not .dev) on NixOS.
  glibconfigInc = "${pkgs.glib.out}/lib/glib-2.0/include";

  emacsWrapped = pkgs.symlinkJoin {
    name = "emacs-wrapped";
    paths = [ emacsPkg ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/emacs \
        --set NIX_CFLAGS_COMPILE_x86_64_unknown_linux_gnu "-I${pkgs.glib.dev}/include/glib-2.0 -I${glibconfigInc}" \
        --set PKG_CONFIG_PATH "${pkgs.glib.dev}/lib/pkgconfig"
    '';
  };
in
lib.mkIf cfg.enable {
  home.packages = with pkgs; [
    emacsWrapped
    ripgrep
    fd
    git
    libvterm
    cmake
    gnumake
    glib.dev
    libtool
    nerd-fonts.sauce-code-pro
    nerd-fonts.geist-mono
    alegreya
    languagetool
    (aspellWithDicts (d: with d; [ en ]))
    shellcheck
    sqlite
    graphviz
    nil
  ];

  # Run emacs as a daemon: frames open instantly via emacsclient instead
  # of paying the full ~2.5s Doom startup on every launch.
  services.emacs = {
    enable = true;
    package = emacsWrapped;
    client.enable = true;
    startWithUserSession = "graphical";
  };

  home.activation.copyDoomEmacs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    DOOM_DIR="$HOME/.config/emacs"
    if [ ! -f "$DOOM_DIR/bin/doom" ]; then
      echo "Installing Doom Emacs framework to $DOOM_DIR ..."
      mkdir -p "$DOOM_DIR"
      cp -r ${doomSrc}/. "$DOOM_DIR/"
      chmod -R u+w "$DOOM_DIR"
      echo "Doom Emacs framework installed."
      echo "Run: $DOOM_DIR/bin/doom sync"
    fi
  '';

  home.file.".config/doom".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/dotfiles/doom";
}
