# Config Test Pyramid

## Objective
Define a stable 3-layer regression model for configuration changes with explicit ownership, runtime budgets, and fixture-backed coverage.

## Source of Truth
1. `tests/pyramid/config-test-pyramid.json`
2. `scripts/check-test-pyramid-contracts.sh`

## Layers
1. Layer A (`static-structure`)
   - Owner: `repo-maintainers`
   - Runtime budget: `<= 120s`
   - Scope: structure/policy/contract checks
2. Layer B (`eval-matrix`)
   - Owner: `repo-maintainers`
   - Runtime budget: `<= 900s`
   - Scope: eval-based cross-profile/host contract checks
3. Layer C (`build-runtime-smoke`)
   - Owner: `repo-maintainers`
   - Runtime budget: `<= 1500s`
   - Scope: build-level and runtime smoke confidence checks

## High-Risk Category Coverage
1. `host_addition`
2. `profile_addition`
3. `pack_addition`
4. `option_migration_lifecycle`

Each category must map to at least one layer and one executable check, with at least one synthetic fixture.

## Synthetic Fixtures
1. `tests/fixtures/host-addition/host-descriptor.json`
2. `tests/fixtures/profile-addition/profile-metadata.json`
3. `tests/fixtures/pack-addition/pack-registry.json`
4. `tests/fixtures/pack-addition/synthetic-pack.nix`
5. `tests/fixtures/option-migration-lifecycle/migration-registry.json`

## Validation Rule
1. `scripts/check-test-pyramid-contracts.sh` runs as part of `./scripts/run-validation-gates.sh structure`.
2. Changes that alter categories/layers/fixtures must update both:
   - `tests/pyramid/config-test-pyramid.json`
   - this document.
