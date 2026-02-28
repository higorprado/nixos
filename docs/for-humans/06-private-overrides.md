# Private Overrides

## Goal
Keep secrets, personal identity, private network details, and machine-local paths out of tracked files.

## Files
- Host entrypoint (untracked): `hosts/predator/private.nix`
- Home entrypoint (untracked): `home/<user>/private.nix`

## Structure Rule
1. Entrypoints must be import-only.
2. Split by domain under `private/`:
   - host: `networking.nix`, `services.nix`, `hardware-local.nix`
   - home: `env.nix`, `git.nix`, `paths.nix`, `ssh.nix`, `theme-paths.nix`
3. Keep values only in private modules. Avoid complex logic.

## Setup
1. Copy each `*.example` to the same name without `.example`.
2. Fill your local values.
3. Never commit real private files.

## What Must Be Private
- personal email/name identity
- LAN IPs, local hostnames, private DNS
- absolute personal filesystem paths
- keys/tokens/secrets
