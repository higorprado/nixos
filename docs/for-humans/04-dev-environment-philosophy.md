# Dev Environment Philosophy

## Layers
1. Base machine layer (stable daily tools via Nix/Home Manager).
2. Project layer (language/runtime specifics via `devenv` + `direnv`).

## Rules
1. Keep global environment lean and predictable.
2. Put project-specific compilers/SDKs in project `devenv`, not global profile.
3. Prefer reproducible project env activation (`direnv` + `nix-direnv`).
4. Use global tools only when broadly useful across projects.

## Repo Conventions
1. Global dev tooling is organized under `home/<user>/dev/`.
2. `devenv` integration is centralized in `home/<user>/dev/devenv.nix`.
3. AI/dev assistant tooling is isolated from core system modules.

## Related Workflows
1. Safe switch/rollback after env changes: `workflows/102-switch-and-rollback.md`
2. Validation before merge: `workflows/104-validation-before-merge.md`
