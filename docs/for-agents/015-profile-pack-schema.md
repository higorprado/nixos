# Profile/Pack Schema Contract

## Objective
Make profile and desktop pack integration explicit, versioned, and machine-checkable.

## Profile Metadata Schema (`modules/profiles/desktop/profile-metadata.nix`)
1. Top-level required fields:
   - `schemaVersion` (integer)
   - `profiles` (attrset)
2. Current schema version: `1`.
3. Each `profiles.<name>` entry must include:
   - `capabilities` (attrset)
   - `requiredIntegrations` (list)
   - `optionalIntegrations` (list)
   - `packSets` (non-empty list)
4. `capabilities` must include keys:
   - `desktopFiles`
   - `desktopUserApps`
   - `niri`
   - `hyprland`
   - `dms`
   - `noctalia`
   - `caelestiaHyprland`

## Pack Registry Schema (`home/user/desktop/pack-registry.nix`)
1. Top-level required fields:
   - `schemaVersion` (integer)
   - `packs` (attrset)
   - `packSets` (attrset)
2. Current schema version: `1`.
3. Every `packs.<name>.module` path must exist.
4. Every `packSets.<name>` entry must reference declared `packs`.

## Consumer Rule
1. Consumers should read schema-based metadata with compatibility fallback:
   - `metadataRoot = import .../profile-metadata.nix;`
   - `metadata = metadataRoot.profiles or metadataRoot;`
2. This keeps a safe bridge during schema transitions.

## Migration Policy
1. Additive fields: keep `schemaVersion` unchanged.
2. Breaking shape changes: increment `schemaVersion`.
3. On schema bump:
   - update all consumers and checks in the same change slice,
   - add migration notes in `013-option-migration-playbook.md` (if options are impacted),
   - update this contract doc with new required fields/version.
