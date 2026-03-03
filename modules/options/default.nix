# Custom option declarations
{ ... }:
{
  imports = [
    ./core-options.nix
    ./desktop-options.nix
    ./desktop-capabilities-options.nix
    ./option-migrations.nix
  ];
}
