{ lib
, stdenv
, fetchurl
, makeWrapper
, autoPatchelfHook
, dpkg
, gtk3
, libnotify
, nss
, nspr
, libdrm
, libxkbcommon
, alsa-lib
, cups
, dbus
, libglvnd
, pango
, atk
, cairo
, gdk-pixbuf
, freetype
, fontconfig
, libpulseaudio
, xorg
, mesa
}:

let
  version = "2.0.9";
  pname = "zennotes";

  src = fetchurl {
    url = "https://github.com/ZenNotes/zennotes/releases/download/v${version}/ZenNotes-${version}-linux-amd64.deb";
    hash = "sha256-h3TaVXizSNRwN3NaNh4dN9y5keoauSptEFABcMt6xow=";
  };

  runtimeLibs = [
    gtk3 libnotify nss nspr libdrm libxkbcommon
    alsa-lib cups dbus libglvnd pango atk cairo
    gdk-pixbuf freetype fontconfig libpulseaudio mesa
    xorg.libX11 xorg.libXcomposite xorg.libXdamage
    xorg.libXext xorg.libXfixes xorg.libXrandr
    xorg.libxcb xorg.libXi xorg.libXtst
    stdenv.cc.cc.lib
  ];
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [ dpkg makeWrapper autoPatchelfHook ];
  buildInputs = runtimeLibs;

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share

    cp -r opt/ZenNotes $out/share/zennotes
    chmod +x $out/share/zennotes/ZenNotes

    cp -r usr/share/applications $out/share/ 2>/dev/null || true
    cp -r usr/share/icons $out/share/ 2>/dev/null || true

    substituteInPlace $out/share/applications/ZenNotes.desktop \
      --replace-fail 'Exec=/opt/ZenNotes/ZenNotes' "Exec=$out/bin/zennotes" \
      --replace-fail 'Icon=ZenNotes' "Icon=ZenNotes"

    makeWrapper $out/share/zennotes/ZenNotes $out/bin/zennotes \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
  '';

  meta = with lib; {
    description = "Keyboard-first Markdown notes with Vim motions and MCP integration";
    homepage = "https://zennotes.org";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "zennotes";
  };
}
