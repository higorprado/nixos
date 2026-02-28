# Private Overrides and Public Safety

## Goal
Keep tracked repo files public-safe and portable while preserving local behavior through untracked overrides.

## Private Entrypoints (Untracked)
1. `hosts/predator/private.nix`
2. `home/<user>/private.nix`

Entrypoints are import-only and must stay small.

## Domain Split (Untracked)
Host:
1. `hosts/predator/private/networking.nix`
2. `hosts/predator/private/services.nix`
3. `hosts/predator/private/hardware-local.nix`

Home:
1. `home/<user>/private/env.nix`
2. `home/<user>/private/git.nix`
3. `home/<user>/private/paths.nix`
4. `home/<user>/private/ssh.nix`
5. `home/<user>/private/theme-paths.nix`

## Rules
1. Never commit real private files.
2. Keep private modules values-focused.
3. Do not move shared logic into private modules.
4. Use tracked `*.example` files as source of truth for structure.

## Public Safety Gate
Run:
```bash
./scripts/check-repo-public-safety.sh
```

The gate fails on:
1. local file flake URLs (`file://...`)
2. hardcoded `/home/<user>` absolute paths
3. RFC1918 private IPs
4. personal Gmail addresses
5. high-confidence credential/token patterns

Use `scripts/public-safety-allowlist.txt` only for intentional, reviewed exceptions.
