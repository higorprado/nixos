{ lib, ... }:
let
  registry = import ./migration-registry.nix;
  renamedModules = map (entry: lib.mkRenamedOptionModule entry.from entry.to) registry.renamed;
  aliasModules = map (entry: lib.mkAliasOptionModule entry.from entry.to) registry.aliases;
  removedModules = map (entry: lib.mkRemovedOptionModule entry.path entry.message) registry.removed;
in
{
  imports = renamedModules ++ aliasModules ++ removedModules;
}
