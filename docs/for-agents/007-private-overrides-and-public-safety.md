# Private Overrides and Public Safety

## Goal
Keep the tracked repo public-safe while preserving local/private behavior via untracked overrides.

## Untracked Entrypoints
1. `hosts/*/private.nix`
2. `home/*/private.nix`

## Rules
1. Never commit real private override files.
2. Keep private modules value-focused.
3. Keep shared logic in tracked shared modules, not private trees.
4. Track `*.example` as structure source-of-truth.

## Public Safety Gate
Run before publish:
```bash
./scripts/check-repo-public-safety.sh
```

## Gate Coverage
1. local file flake URLs
2. hardcoded personal absolute home paths
3. RFC1918 private IPs
4. personal email leakage
5. high-confidence secret/token patterns
