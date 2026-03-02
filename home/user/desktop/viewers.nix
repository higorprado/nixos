# Desktop viewers and MIME defaults
# Loupe image viewer + default image associations
{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  desktopProfileEnabled = osConfig.custom.desktop.capabilities.desktopUserApps;

  loupeDesktop = "org.gnome.Loupe.desktop";
  papersDesktop = "org.gnome.Papers.desktop";

  imageMimeTypes = [
    "image/jpeg"
    "image/png"
    "image/gif"
    "image/webp"
    "image/avif"
    "image/bmp"
    "image/tiff"
    "image/svg+xml"
  ];

  pdfMimeTypes = [
    "application/pdf"
    "application/x-pdf"
  ];

  mkMimeMap =
    mimeTypes: desktopId:
    builtins.listToAttrs (
      map (mime: {
        name = mime;
        value = [ desktopId ];
      }) mimeTypes
    );
in
lib.mkIf desktopProfileEnabled {
  home.packages = with pkgs; [
    loupe
    papers
  ];

  xdg.mimeApps = {
    defaultApplications =
      (mkMimeMap imageMimeTypes loupeDesktop) // (mkMimeMap pdfMimeTypes papersDesktop);
    associations.added =
      (mkMimeMap imageMimeTypes loupeDesktop) // (mkMimeMap pdfMimeTypes papersDesktop);
  };
}
