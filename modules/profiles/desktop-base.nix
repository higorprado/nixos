# Legacy shim: use modules/profiles/desktop/base.nix
{ ... }:
{
  imports = [ ./desktop/base.nix ];
}
