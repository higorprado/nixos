# Change Decision Algorithm

## Algorithm
1. Identify scope:
   - host-specific -> `hosts/`
   - shared system -> `modules/`
   - user environment -> `home/<user>/`
2. Identify artifact:
   - package/service wiring -> Nix module
   - app payload -> `config/` only if needed
3. Decide delivery model:
   - immutable source/sync (default)
   - copy-once mutable (exception)
4. Apply smallest coherent slice.
5. Run five Nix gates.
6. Record what changed and why.

## Placement Heuristics
1. Editor-specific behavior -> `home/<user>/programs/editors/`.
2. Terminal-specific behavior -> `home/<user>/programs/terminals/`.
3. User service wiring -> `home/<user>/services/`.
4. Desktop profile behavior -> `modules/profiles/`.
