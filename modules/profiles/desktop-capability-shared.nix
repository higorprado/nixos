# Legacy shim: use modules/profiles/desktop/capability-shared.nix
{ ... }:
{
  imports = [ ./desktop/capability-shared.nix ];
}
