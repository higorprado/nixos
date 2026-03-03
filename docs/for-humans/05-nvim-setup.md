# Neovim Setup

## Ownership
1. Nix enables Neovim and related toolchain packages.
2. Source config lives in `config/apps/nvim/`.
3. Home activation syncs this folder into `~/.config/nvim` on switch.

## Important Behavior
1. `~/.config/nvim` is synchronized from repo source.
2. Changes to `config/apps/nvim/` require rebuild/sync to apply.
3. LSP/debug tooling is Nix-managed, not Mason-auto-managed.

## Change Workflow
1. Edit files under `config/apps/nvim/`.
2. Apply safely via: `workflows/102-switch-and-rollback.md`.
3. Validate before merge via: `workflows/104-validation-before-merge.md`.

## Keep It Stable
1. Avoid unmanaged runtime drift in live nvim config.
2. Keep plugin/lsp decisions explicit in repo files.
