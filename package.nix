{
  lib,
  appimageTools,
  fetchurl,
}:

let
  version = "0.35.0";
  # urlver = "0.31.0.14"; # For when URL and version don't match
  pname = "browseros";

  src = fetchurl {
    url = "https://github.com/browseros-ai/BrowserOS/releases/download/v${version}/BrowserOS_v${version}_x64.AppImage";
    # url = "https://github.com/browseros-ai/BrowserOS/releases/download/v${urlver}/BrowserOS_v${version}_x64.AppImage"; # For when URL and version don't match
    hash = "sha256-p3sw+nagG0pqgVAkvXRC2Hr2clC8Ery+Wq5b+aHZOWk=";
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
