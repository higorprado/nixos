# Repo Philosophy

## Core Principles
1. Declarative first: system and user state should be reproducible from Nix.
2. Explicit ownership: each concern has one clear owner file/module.
3. Separation of logic and data:
   - Nix logic in `modules/`, `hosts/`, `home/`.
   - Config payloads in `config/` only when needed.
4. Practical mutability where required:
   - Use copy-once mutable files for tools that must write their own config.
5. Small reversible changes:
   - one slice at a time, always with validation gates.

## Ownership Boundaries
1. `hosts/<host>/`: machine-specific choices (hostname, profile selection, hardware imports).
2. `modules/`: shared NixOS policy and feature modules.
3. `home/<user>/`: user environment and app behavior.
4. `config/`: source files consumed by activation/sync logic.
5. `legacy/`: archived state for rollback/history, not active source of truth.

## Mutable vs Immutable Rule
1. Immutable (preferred): symlink/sync from repo when app is config-consumer only.
2. Mutable (exception): copy-once when app modifies config itself or user edits must persist.

If unsure, default to immutable and justify any mutable exception in the module comment.
