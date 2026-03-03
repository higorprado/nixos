# Neovim Ops Guide

## Ownership Model
1. Nix module: `home/<user>/programs/editors/nvim.nix`.
2. Source payload: `config/apps/nvim/`.
3. Deployment: activation rsync to `~/.config/nvim`.

## Change Protocol
1. Modify `config/apps/nvim/*`.
2. Rebuild/sync.
3. Run Neovim-focused health checks used by repo workflow.
4. Confirm no unmanaged drift in live config.

## Constraints
1. Keep language servers/debuggers Nix-managed.
2. Avoid introducing external auto-install side channels.
