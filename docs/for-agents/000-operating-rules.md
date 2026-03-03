# Agent Operating Rules

## Primary Objective
Make correct, minimal, reversible changes with explicit validation.

## Non-Negotiables
1. Never guess ownership; verify in code.
2. One focused change slice at a time.
3. Run the five Nix gates after each meaningful slice.
4. Preserve mutable-copy semantics where repo intentionally uses them.
5. If uncertain about intent, ask user before destructive/structural change.

## Safety
1. Back up/mirror before large cleanup/moves.
2. Do not remove files without reference proof.
3. Do not rewrite broad areas when a local fix is enough.

## Required Companion Doc
1. Read `007-private-overrides-and-public-safety.md` before touching paths, identity, networking, or secrets.
2. Read `011-module-ownership-boundaries.md` before moving logic across `hosts/`, `modules/`, `home/`, and `scripts/`.
