# Dev Environment Model

## Layers
1. Global user dev tooling (`home/<user>/dev/*`).
2. Project-local env (`devenv` + `direnv`).

## Agent Rules
1. Prefer project-local for language/runtime specifics.
2. Add global tools only when cross-project utility is proven.
3. Keep `direnv` integration stable; avoid per-project hacks in global config.
4. Preserve reproducibility over convenience.
