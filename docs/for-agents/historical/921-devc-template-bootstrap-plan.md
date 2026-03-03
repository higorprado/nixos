# Devc Template Bootstrap Plan

## Goal
Enable fast project scaffolding from `config/devenv-templates/*` using either native Nix commands or a thin `devc` helper command.

## Scope
1. Source templates live in `config/devenv-templates/<name>/`.
2. Support both target modes:
   - `devc <template> <new_dir>` (create new project directory)
   - `devc <template> .` (initialize current directory)
3. Make newly added template folders automatically available without extra per-template wiring.

## Existing Baseline
1. Template folders already exist (`go`, `javascript`, `lua`, `python`, `rust`).
2. `flake.nix` currently exports `nixosConfigurations` but not `templates`.
3. `devenv` is already installed in Home Manager.

## Design Decisions
1. Canonical mechanism: Nix flake templates (`outputs.templates`) and native commands:
   - `nix flake new <dir> -t <flake>#<template>`
   - `nix flake init -t <flake>#<template>`
2. Optional UX wrapper: `devc` shell command that calls the native commands.
3. Keep `devc` stateless and minimal:
   - No custom templating engine.
   - No mutation outside current working dir unless user requests a new target dir.

## Implementation Steps
1. Add `templates` output in `flake.nix`:
   - Read directories under `config/devenv-templates`.
   - Convert each directory to a template entry (`path`, `description`).
   - Set a stable default template (recommended: `python` when present).
2. Add `devc` command via Home Manager package:
   - Usage: `devc list`, `devc <template> [target]`.
   - Default target is `.`.
   - `list` should read templates from `nix flake show --json`.
3. Add robust CLI behavior:
   - `help` output.
   - Argument count validation.
   - Clear errors for unknown templates/invalid targets.
4. Wire install location:
   - Add command package to `home/user/dev/devenv.nix` so it is always available in user shell.
5. Keep docs minimal:
   - Small usage note in existing dev-environment docs only if needed.

## Validation Plan
1. Run repository validation gates after implementation:
   - `nix flake metadata`
   - `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
   - `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
   - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
   - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
2. Template-specific checks:
   - `nix flake show path:$PWD` lists `templates` entries.
   - Create temp project with `nix flake new` using one template and verify files copied.
   - Initialize temp current dir with `nix flake init` and verify files copied.
3. Wrapper checks:
   - `devc list` returns expected template names.
   - `devc python new_project` creates directory with template contents.
   - `devc python .` initializes current directory.

## Risks and Mitigations
1. Risk: `nix flake show`/build commands may fail in restricted environments.
   - Mitigation: run validation where Nix daemon socket is accessible.
2. Risk: non-directory files under template root pollute template list.
   - Mitigation: filter entries to directories only.
3. Risk: wrapper drifts from native Nix behavior.
   - Mitigation: keep wrapper as a thin pass-through to `nix flake new/init`.

## Rollout
1. Merge `templates` support first.
2. Merge `devc` wrapper second.
3. Optionally announce usage aliases/examples after successful validation.
