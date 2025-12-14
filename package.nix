{
  lib,
  appimageTools,
  fetchurl,
}:

let
  urlver = "0.31.0.14";
  version = "0.32.0.1";
  pname = "browseros";

  src = fetchurl {
    url = "https://github.com/browseros-ai/BrowserOS/releases/download/v${urlver}/BrowserOS_v${version}_x64.AppImage";
    hash = "sha256-O2lN9VFmeK+rl+LMlPm+NKlNyBBrjtOSwhQeroSuTHw=";
  };

  appimageContents = appimageTools.extractType1 { inherit pname version src; };
in
appimageTools.wrapType2 rec {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/"${pname}.desktop" -t $out/share/applications

    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'

    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  meta = {
    description = "BrowserOS is an open-source chromium fork that runs AI agents natively.";
    homepage = "https://browseros.com/";
    downloadPage = "https://github.com/browseros-ai/BrowserOS/releases";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ onny ];
    platforms = [ "x86_64-linux" ];
  };
}
