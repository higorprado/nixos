# Private Overrides

## Goal
Keep secrets, personal identity, private network details, and machine-local paths out of tracked files.

## Files
1. Host entrypoint (untracked): `hosts/predator/private.nix`
2. Home entrypoint (untracked): `home/<user>/private.nix`

## Structure Rule
1. Entrypoints must be import-only.
2. Split by domain under `private/`:
   - host: `networking.nix`, `services.nix`, `hardware-local.nix`
   - home: `env.nix`, `git.nix`, `paths.nix`, `ssh.nix`, `theme-paths.nix`
3. Keep values only in private modules. Avoid complex logic.

## Setup Workflow
1. Follow `workflows/103-private-overrides.md`.
2. Run `./scripts/check-repo-public-safety.sh` before publish.

## What Must Be Private
1. personal email/name identity
2. LAN IPs, local hostnames, private DNS
3. absolute personal filesystem paths
4. keys/tokens/secrets
