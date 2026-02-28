# Development toolchains (all machines)
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gcc
    nodejs
    sqlite
    tree-sitter
    binutils
  ];
}
