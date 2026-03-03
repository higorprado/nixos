# Pack and App Replacement (Example: Nemo -> Nautilus)

## Use This For
1. Replacing one desktop app with another (file manager, viewer, media app).
2. Deciding exactly which files should change.

## Decision Map (Where To Edit)
1. Change app package/config implementation:
   - edit the owning pack module under `home/user/desktop/*.nix`.
   - file-manager case today: `home/user/desktop/files.nix`.
2. Change default opener behavior (MIME/desktop ID):
   - edit `home/user/desktop/default.nix` (`xdg.mimeApps`).
3. Change which profiles receive a pack:
   - edit `home/user/desktop/pack-registry.nix` (`packs` / `packSets`).
   - edit `modules/profiles/desktop/profile-metadata.nix` (`profiles.<name>.packSets`) only if profile membership changes.
4. Change portal backend policy:
   - edit `modules/profiles/desktop/capability-shared.nix` only when backend requirements change.
   - for Nemo -> Nautilus, this is usually not required.

## Nemo -> Nautilus Example
1. In `home/user/desktop/files.nix`:
   - replace `nemo-with-extensions` with `nautilus`.
   - remove Nemo-specific desktop override block (`xdg.dataFile."applications/nemo.desktop"`).
   - remove Nemo-specific terminal integration (`org/cinnamon/desktop/applications/terminal`) if no longer needed.
2. In `home/user/desktop/default.nix`:
   - set `inode/directory` and `application/x-gnome-saved-search` default to `org.gnome.Nautilus.desktop`.
3. Keep pack membership unchanged unless you want profile-specific behavior.

## Validation
1. `./scripts/check-changed-files-quality.sh [origin/main]`
2. `./scripts/run-validation-gates.sh structure`
3. `./scripts/run-validation-gates.sh all`
4. Optional runtime checks:
   - `./scripts/check-runtime-smoke.sh --allow-non-graphical`
   - validate MIME result in session: `xdg-mime query default inode/directory`

## Done When
1. Package and MIME defaults match target app.
2. Required validation passes.
3. Opening a directory launches the intended app.
