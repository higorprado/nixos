# Legacy shim: use modules/profiles/desktop/default.nix
{ ... }:
{
  imports = [ ./desktop/default.nix ];
}
