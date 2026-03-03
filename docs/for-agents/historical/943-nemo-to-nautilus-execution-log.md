# Nemo to Nautilus Execution Log

## Scope
Execute `docs/for-agents/historical/942-nemo-to-nautilus-migration-plan.md`.

## Progress
1. Plan created and indexed in plans/current-work indexes.
2. Replaced `nemo-with-extensions` with `nautilus` in `home/user/desktop/files.nix`.
3. Removed Nemo-specific leftovers from `home/user/desktop/files.nix`:
   - `xdg.dataFile."applications/nemo.desktop"` override
   - `org/cinnamon/desktop/applications/terminal` dconf block
4. Updated MIME defaults in `home/user/desktop/default.nix`:
   - `inode/directory` -> `org.gnome.Nautilus.desktop`
   - `application/x-gnome-saved-search` -> `org.gnome.Nautilus.desktop`
5. Added docs-gap remediations:
   - `docs/for-agents/018-doc-lifecycle-and-index.md` now points to canonical index files only (no mutable active-plan duplication).
   - `docs/for-humans/workflows/106-pack-and-app-replacement.md` now includes a required leftover-search check.

## Validation Evidence
1. `./scripts/check-changed-files-quality.sh origin/main` -> pass
2. `./scripts/run-validation-gates.sh structure` -> pass
3. `./scripts/check-repo-public-safety.sh` -> pass
4. `./scripts/run-validation-gates.sh all` -> pass
5. Source-app leftover scan:
   - `rg -n "nemo|Nemo|org\\.nemo|cinnamon" home/user/desktop -S` -> no matches

## Docs-Gap Analysis
1. Gap found: root lifecycle doc had mutable active-plan listing that can drift from canonical indexes.
2. Gap found: human app-replacement workflow did not explicitly require searching for source-app leftovers.
3. Both gaps were patched in this slice.
