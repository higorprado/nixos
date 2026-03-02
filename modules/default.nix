# Modules entry point
# Import order: core → services → hardware → packages → profiles → options
{ ... }:
{
  imports = [
    ./core
    ./services
    ./hardware
    ./packages
    ./profiles
    ./options
  ];
}
