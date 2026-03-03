# Catppuccin Coverage Plan (Agent Execution, Centralized Registry)

## Goal
Migrate Catppuccin enablement to one centralized file, then enable Catppuccin for every supported app in this repo without changing non-theme behavior.

## Locked Decisions (From User)
1. Do not migrate Neovim to `catppuccin.nvim` (keep current local Neovim theme flow).
2. Browser support must be validated from local upstream `nix-cat` sources, not assumptions.
3. Keep centralized Catppuccin toggles model.

## Hard Rule: No Guessing
1. Always derive support from the local upstream source at `$NIX_CAT_REPO` (default: `$HOME/git/nix-cat`).
2. Use current option data files from `nix-cat/docs/data/`, not memory.
3. For special cases, read upstream module source directly (for example browser modules).
4. If mapping is ambiguous, document and ask instead of guessing.

## Target Architecture (Centralized)
1. Keep flavor/accent base in `home/user/desktop/catppuccin.nix`.
2. Create one centralized registry file for app toggles, for example:
   - `home/user/desktop/catppuccin-targets.nix`
3. Put all `catppuccin.<app>.*` toggles in that single registry file.
4. Keep app behavior in app modules (starship format, tmux config, terminal options, browser launch flags).
5. Do not duplicate Catppuccin toggles across app files once centralized.
6. `desktop/default.nix` remains the composition/root module for desktop concerns; it may import Catppuccin files but should not carry scattered per-app Catppuccin toggles.

## Scope
1. Home Manager Catppuccin modules.
2. NixOS Catppuccin modules relevant to enabled system components.
3. Browser theming, including Chromium-family and Firefox-family handling.
4. Manual theme blocks currently in repo that can be replaced by official Catppuccin modules.

## Inputs To Use
1. Repo under change: `$REPO_ROOT` (default: current repo directory)
2. Upstream reference: `$NIX_CAT_REPO` (default: `$HOME/git/nix-cat`)
3. Option catalogs:
   - `$NIX_CAT_REPO/docs/data/main-home-options.json`
   - `$NIX_CAT_REPO/docs/data/main-nixos-options.json`
4. Upstream module sources for special behavior:
   - `$NIX_CAT_REPO/modules/home-manager/chrome.nix`
   - `$NIX_CAT_REPO/modules/home-manager/firefox.nix`
5. Local safety docs:
   - `docs/for-agents/000-operating-rules.md`
   - `docs/for-agents/006-validation-and-safety-gates.md`
   - `docs/for-agents/007-private-overrides-and-public-safety.md`

## Phase 1: Build Evidence-Based Coverage Matrix
1. Extract supported HM modules from `main-home-options.json`:
   - keys matching `catppuccin.<name>.enable`
2. Extract supported NixOS modules from `main-nixos-options.json`:
   - keys matching `catppuccin.<name>.enable`
3. Extract used apps in this repo from:
   - `programs.<name>.enable = true`
   - `services.<name>.enable = true`
   - `home.packages` entries (important for browser/package-only apps)
4. Build matrix columns:
   - `app`
   - `used_in_repo`
   - `supported_by_catppuccin` (`hm`/`nixos`/`none`)
   - `enabled_now`
   - `centralized_target` (option path in registry)
   - `action` (`migrate-enable`, `already-enabled`, `manual-review`, `exception`)
   - `notes`

## Phase 2: Create Central Registry File
1. Add `home/user/desktop/catppuccin-targets.nix` (or user-approved equivalent).
2. Import it from `home/user/desktop/default.nix`.
3. Move existing app-level Catppuccin toggles into this registry.
4. Keep only Catppuccin option declarations in the registry (no app behavior).

## Phase 3: Enable Missing Supported Targets
1. For each `migrate-enable` row in matrix, add `catppuccin.<app>.enable = true;` to the registry.
2. For special schemas, follow upstream option shape exactly (for example VSCode profiles, Firefox profiles).
3. Remove duplicate Catppuccin declarations from app modules after migration.
4. Do not change non-theme settings while moving toggles.

## Phase 4: Browser Rules (Mandatory)
1. Chromium-family support must be derived from upstream `chrome.nix`.
2. Current upstream support includes `chromium`, `brave`, and `vivaldi`.
3. `google-chrome` is not supported by Catppuccin browser module in upstream `chrome.nix`; document as exception.
4. Firefox-family support uses profile options (from upstream `firefox.nix`):
   - `catppuccin.firefox.profiles.<name>.enable`
   - `catppuccin.librewolf.profiles.<name>.enable`
   - `catppuccin.floorp.profiles.<name>.enable`
5. If a browser is installed only through `home.packages`, do not assume migration path:
   - document exact options to migrate
   - mark `manual-review` if migration changes runtime flags or behavior
6. For Chromium migration candidates, preserve functional behavior by mapping existing launch flags to the managed browser configuration and validate launch/sessions after switch.

## Phase 4.1: Firefox Simple Migration Track
1. Detect if Firefox is currently package-only (`home.packages`) or HM-managed (`programs.firefox`).
2. If package-only, prepare migration patch to:
   - enable `programs.firefox`
   - declare explicit `programs.firefox.profiles.<name>`
   - enable `catppuccin.firefox.profiles.<name>.enable` in centralized registry
3. Keep MIME/default-browser associations unchanged.
4. Validate that Firefox opens with expected profile and Catppuccin extension/theme state.

## Phase 5: Replace Manual Theme Blocks
1. Where official Catppuccin modules exist, replace manual Catppuccin theme sources with centralized official toggles.
2. Keep custom non-theme overrides (for example prompt format, app behavior overrides).
3. If removal may change visuals beyond Catppuccin baseline, mark `manual-review` and document.

## Phase 6: Validation Gates
Run after each batch:
1. `nix flake metadata`
2. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.activationPackage`
3. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
4. Confirm generated configs include Catppuccin artifacts for changed apps.
5. Confirm no duplicate Catppuccin declarations remain outside central registry.

## Phase 7: Reporting
1. Write execution report in `docs/for-agents/` with:
   - final matrix
   - changed files
   - exceptions with upstream evidence path
   - unresolved manual-review items
2. Add human summary in `docs/for-humans/` only if operational workflow changed.

## Command Checklist (Agent)
```bash
REPO_ROOT="${REPO_ROOT:-$PWD}"
NIX_CAT_REPO="${NIX_CAT_REPO:-$HOME/git/nix-cat}"

# 1) Supported options (no guessing)
jq -r 'keys[] | select(test("^catppuccin\\.[^.]+\\.enable$"))' "$NIX_CAT_REPO/docs/data/main-home-options.json" | sed 's/^catppuccin\\.//; s/\\.enable$//' | sort -u > /tmp/cat-home-supported.txt
jq -r 'keys[] | select(test("^catppuccin\\.[^.]+\\.enable$"))' "$NIX_CAT_REPO/docs/data/main-nixos-options.json" | sed 's/^catppuccin\\.//; s/\\.enable$//' | sort -u > /tmp/cat-nixos-supported.txt

# 2) Used app inventory
cd "$REPO_ROOT"
rg -n 'programs\\.[a-zA-Z0-9._-]+\\.enable\\s*=\\s*true' home modules hosts > /tmp/repo-programs-enabled.txt
rg -n 'services\\.[a-zA-Z0-9._-]+\\.enable\\s*=\\s*true' home modules hosts > /tmp/repo-services-enabled.txt
rg -n 'home\\.packages\\s*=|home\\.packages\\s*\\+\\+|\\bfirefox\\b|\\bchromium\\b|\\bgoogle-chrome\\b|\\bbrave\\b|\\bvivaldi\\b|\\blibrewolf\\b|\\bfloorp\\b' home modules hosts > /tmp/repo-packages-browser-scan.txt
rg -n 'catppuccin\\.[a-zA-Z0-9._-]+' home modules hosts > /tmp/repo-catppuccin-current.txt

# 3) Browser upstream evidence (required)
nl -ba "$NIX_CAT_REPO/modules/home-manager/chrome.nix" | sed -n '1,220p' > /tmp/cat-browser-upstream-chrome.txt
nl -ba "$NIX_CAT_REPO/modules/home-manager/firefox.nix" | sed -n '1,320p' > /tmp/cat-browser-upstream-firefox.txt
```

## Completion Criteria
1. All Catppuccin app toggles are centralized in one registry file.
2. Every used, upstream-supported target is either enabled or documented as exception.
3. Browser decisions are backed by upstream module evidence from local `nix-cat`.
4. HM and system builds pass.
