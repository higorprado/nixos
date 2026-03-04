{
  pkgs,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages = [
    inputs.zed-editor.packages.${system}.zed-editor-bin
  ];

}
