# Neovim Setup

## Ownership
1. Nix enables Neovim and related toolchain packages.
2. Source config lives in `config/apps/nvim/`.
3. Home activation syncs this folder into `~/.config/nvim` on switch.

## Important Behavior
1. `~/.config/nvim` is synchronized from repo source.
2. Changes to `config/apps/nvim/` require rebuild/sync to apply.
3. LSP/debug tooling is Nix-managed, not Mason-auto-managed.

## Safe Change Workflow
1. Edit files under `config/apps/nvim/`.
2. Rebuild (or run equivalent sync path if needed).
3. Run health/smoke checks used by repo workflow.

## Keep It Stable
1. Avoid unmanaged runtime drift in live nvim config.
2. Keep plugin/lsp decisions explicit in repo files.
