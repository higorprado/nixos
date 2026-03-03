# Profile Switch and Greeter Safety (Postmortem Rules)

## Why this exists
A previous mangowc attempt caused a login failure path and forced TTY recovery.  
This file defines non-negotiable safeguards for profile/compositor changes.

## Root mistakes to avoid
1. Overriding `custom.desktop.profile` in private overrides without explicit request and safe rollback checkpoints.
2. Applying risky display-manager/greeter changes before proving session discovery works.
3. Making multiple high-risk changes in one slice instead of reversible checkpoints.
4. Treating fallback/recovery as optional instead of mandatory.

## Hard rules
1. Never edit `hosts/*/private*.nix` or `home/*/private*.nix` unless the user explicitly asks.
2. Never use `lib.mkForce` on `custom.desktop.profile` unless explicitly requested.
3. For profile/compositor testing, keep default host profile stable and use opt-in local overrides only when user asks.
4. Before any `nixos-rebuild switch`, prove the target build contains valid greeter/session wiring.
5. If a user asks for a new branch, create a branch only; do not create a separate repo unless explicitly requested.

## Mandatory pre-switch checks (profile/compositor work)
1. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
2. Confirm generated greetd command/compositor in built output.
3. Confirm at least one valid session entry is discoverable by greeter path logic.
4. Confirm rollback command is prepared and shared with user before switching.

## Execution model
1. Use small slices:
   - slice A: compile/eval only
   - slice B: build output validation
   - slice C: optional switch
2. After each slice, report current risk and exact rollback command.
3. Do not proceed to next slice if session/greeter validation is uncertain.

## Recovery-first policy
1. At first sign of login regression, stop feature work.
2. Restore stable branch/profile first.
3. Only after login path is confirmed healthy, resume experimentation.

## Operator communication standard
1. State clearly when a change touches login path (`greetd`, greeter, sessions, profile selection).
2. Ask for confirmation before any action that can affect login availability.
3. Keep instructions copy/paste ready for TTY rollback.
