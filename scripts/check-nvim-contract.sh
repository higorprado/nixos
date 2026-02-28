#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM_PLUGINS_DIR="$ROOT_DIR/config/apps/nvim/lua/plugins"

fail=0
warn=0

ok() { printf '[ok] %s\n' "$1"; }
ng() { printf '[error] %s\n' "$1"; fail=1; }
wa() { printf '[warn] %s\n' "$1"; warn=1; }

need_bin() {
  local bin="$1"
  if command -v "$bin" >/dev/null 2>&1; then
    ok "binary present: $bin"
  else
    ng "binary missing: $bin"
  fi
}

need_any_bin() {
  local desc="$1"
  shift
  local b
  for b in "$@"; do
    if command -v "$b" >/dev/null 2>&1; then
      ok "binary present: $b ($desc)"
      return 0
    fi
  done
  ng "binary missing: $desc (expected one of: $*)"
}

need_text() {
  local pattern="$1"
  local desc="$2"
  if rg -rn --fixed-strings "$pattern" "$NVIM_PLUGINS_DIR" >/dev/null 2>&1; then
    ok "$desc"
  else
    ng "$desc (pattern not found: $pattern)"
  fi
}

printf '== Neovim contract check ==\n'
printf 'Config dir: %s\n' "$NVIM_PLUGINS_DIR"

if [ ! -d "$NVIM_PLUGINS_DIR" ]; then
  ng "plugins directory not found: $NVIM_PLUGINS_DIR"
  exit 1
fi

printf '\n-- Toolchain binaries --\n'
need_bin nvim
need_bin pyright
need_bin ruff
need_bin lua-language-server
need_bin vtsls
need_bin node
need_any_bin "JS debugger adapter" js-debug js-debug-adapter
need_bin rust-analyzer
need_bin lldb-dap

printf '\n-- Config invariants (Nix-owned, no Mason auto-installs) --\n'
need_text '"mason-org/mason-lspconfig.nvim"' 'mason-lspconfig plugin entry exists'
need_text 'enabled = false' 'at least one plugin hard-disabled (mason auto installer guard)'
need_text '"WhoIsSethDaniel/mason-tool-installer.nvim"' 'mason-tool-installer plugin entry exists'
need_text 'opts.servers.ts_ls.enabled = false' 'ts_ls disabled'
need_text 'opts.servers.vtsls.enabled = true' 'vtsls enabled'
need_text 'server_opts.mason = false' 'LSP mason=false default enforced'

printf '\n-- DAP invariants --\n'
need_text 'name = "Python: current file"' 'Python DAP launch config exists'
need_text 'name = "Node: current file"' 'JS/TS DAP launch config exists'
need_text 'name = "Lua: current file"' 'Lua DAP launch config exists'
need_text 'type = "lua-local"' 'Lua adapter type is lua-local'
need_text 'command = "node"' 'Lua adapter runs through node'

printf '\n-- Runtime sanity --\n'
embed_count="$(ps -eo args= | rg -c '^.*/nvim --embed( |$)' || true)"
if [ "${embed_count:-0}" -gt 0 ]; then
  wa "found ${embed_count} nvim --embed process(es); investigate if they persist after closing clients"
else
  ok 'no nvim --embed processes detected'
fi

if [ "$fail" -ne 0 ]; then
  printf '\nContract check failed.\n'
  exit 1
fi

if [ "$warn" -ne 0 ]; then
  printf '\nContract check passed with warnings.\n'
  exit 0
fi

printf '\nContract check passed.\n'
