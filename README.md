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

Run these after meaningful changes:

1. `nix flake metadata`
2. `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
3. `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
4. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
5. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
