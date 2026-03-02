# Legacy shim: use modules/options/default.nix
{ ... }:
{
  imports = [ ./options/default.nix ];
}
