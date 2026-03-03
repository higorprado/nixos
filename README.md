# NixOS Configuration Repository

This repository contains the declarative NixOS + Home Manager setup for `predator`.

## What This Repo Is

This is the source of truth for:
1. System configuration (`hosts/`, `modules/`, `flake.nix`)
2. User environment (`home/`)
3. Configuration payload files consumed by modules (`config/`)
4. Custom packages (`pkgs/`)
5. Operational scripts (`scripts/`)

The goal is reproducible, explicit, and maintainable configuration with clear ownership boundaries.

## Repository Structure

1. `flake.nix`: entrypoint and wiring
2. `hosts/`: host-specific configuration
3. `modules/`: shared NixOS modules
4. `home/`: Home Manager user configuration
5. `config/`: app/config payload files
6. `pkgs/`: custom derivations
7. `scripts/`: helper and verification scripts
8. `docs/`: active documentation

## Host Role Model

1. `custom.host.role = "desktop" | "server"` controls desktop stack activation.
2. Desktop profile selection is done with `custom.desktop.profile`.
3. `hosts/server-example/` is a minimal server-role reference host.

## Documentation

1. Human workflows and explanations:
   - start: `docs/for-humans/00-start-here.md`
   - workflows: `docs/for-humans/workflows/100-workflows-index.md`
2. Agent operations and contracts:
   - start: `docs/for-agents/000-operating-rules.md`
   - lifecycle/index: `docs/for-agents/018-doc-lifecycle-and-index.md`

## Validation Commands

1. Fast feedback:
   - `./scripts/check-changed-files-quality.sh [origin/main]`
   - `./scripts/run-validation-gates.sh structure`
2. Full required validation before merge:
   - `./scripts/run-validation-gates.sh all`
3. Desktop runtime smoke (when relevant):
   - `./scripts/check-runtime-smoke.sh --allow-non-graphical`

## CI

1. CI workflow: `.github/workflows/validate.yml`
2. Default push/PR lane: `lint-structure`
3. Docs-only lane: `docs-drift-only`
4. Heavy eval/build lanes are manual-dispatch + schedule controlled.
