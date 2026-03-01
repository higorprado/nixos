{
  pkgs,
  inputs,
  ...
}:

{
  home.packages = [
    inputs.zed-editor.packages.${pkgs.stdenv.hostPlatform.system}.zed-editor-bin
  ];

}
