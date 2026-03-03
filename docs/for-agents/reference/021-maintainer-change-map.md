# Maintainer Change Map

## Objective
Provide a fast, deterministic map from common change types to the files/modules to touch and the minimum validation required.

## Change Types

### 1) Add Or Update Validation Script Logic
1. Primary files:
   - `scripts/check-*.sh`
   - `scripts/lib/*.sh`
   - `scripts/run-validation-gates.sh` (if orchestration changes)
2. Minimum validation:
   - `./scripts/check-changed-files-quality.sh [origin/main]`
   - `./scripts/run-validation-gates.sh structure`
   - `./scripts/check-script-fixture-tests.sh`
3. Additional validation:
   - if orchestration or eval/build semantics changed:
     - `./scripts/run-validation-gates.sh predator`
     - `./scripts/run-validation-gates.sh server-example`

### 2) Add Or Modify Host Descriptor/Host Wiring
1. Primary files:
   - `hosts/host-descriptors.nix`
   - `hosts/<host>/default.nix`
   - `flake.nix` (if assembly changes)
2. Minimum validation:
   - `./scripts/run-validation-gates.sh structure`
   - `./scripts/run-validation-gates.sh predator`
   - `./scripts/run-validation-gates.sh server-example`
   - `./scripts/check-repo-public-safety.sh`

### 3) Add Or Modify Desktop Profile/Pack Contracts
1. Primary files:
   - `modules/profiles/desktop/profile-*.nix`
   - `modules/profiles/desktop/profile-registry.nix`
   - `modules/profiles/desktop/profile-metadata.nix`
   - `home/user/desktop/pack-registry.nix`
2. Minimum validation:
   - `./scripts/run-validation-gates.sh structure`
   - `./scripts/run-validation-gates.sh predator`
   - `./scripts/run-validation-gates.sh server-example`

### 4) Option Rename/Removal/Migration
1. Primary files:
   - `modules/options/migration-registry.nix`
   - `modules/options/option-migrations.nix`
   - impacted option declaration files under `modules/options/` or `home/user/options/`
2. Minimum validation:
   - `./scripts/run-validation-gates.sh structure`
   - `./scripts/run-validation-gates.sh predator`
   - `./scripts/check-repo-public-safety.sh`

### 5) Runtime Smoke Or Warning Budget Changes
1. Primary files:
   - `scripts/check-runtime-smoke.sh`
   - `config/validation/runtime-warning-budget.json`
   - `scripts/capture-runtime-warning-report.sh`
2. Minimum validation:
   - `./scripts/run-validation-gates.sh structure`
   - `./scripts/check-runtime-smoke.sh --allow-non-graphical`
   - `./scripts/check-repo-public-safety.sh`

### 6) Docs Canonical Contract Changes
1. Primary files:
   - `docs/for-agents/0*.md` canonical files
   - `docs/for-humans/*.md` if behavior/workflow changed
2. Minimum validation:
   - `./scripts/check-docs-drift.sh`
   - `./scripts/run-validation-gates.sh structure`

## Fast Decision Rule
1. If you touched `scripts/run-validation-gates.sh` or CI validation routing, run full `predator` and `server-example` gates before commit.
2. If you touched only docs, run docs drift + structure.
3. If you touched any host/profile/option wiring, treat as high-impact and run full eval/build gates.
