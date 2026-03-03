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
2. Desktop profile selection is still done with `custom.desktop.profile`.
3. `hosts/server-example/` is a minimal server-role reference host.

## Documentation

Documentation is split by audience:

1. `docs/for-humans/`
   - Conceptual docs and decision guidance.
   - Start at: `docs/for-humans/00-start-here.md`

2. `docs/for-agents/`
   - Operational docs optimized for AI/code agents.
   - Start at: `docs/for-agents/000-operating-rules.md`

3. `docs/README.md`
   - Documentation index and entrypoints.

Historical/previous docs are not part of the active docs set.

## Validation Commands

Run this after meaningful changes:

1. `./scripts/run-full-validation.sh`

The script runs structure checks, Predator mandatory gates, and `server-example` eval/build checks.

## CI

1. CI workflow: `.github/workflows/validate.yml`
2. Enforced jobs:
   - `lint-structure`
   - `predator-eval-build`
   - `server-example-eval-build`

## Troubleshooting

1. Known warning: `catppuccin.firefox` warning in `niri-only` profile when Firefox HM module is intentionally disabled.
2. Known warning: `xorg.libxcb` deprecation rename warning during eval/build.
