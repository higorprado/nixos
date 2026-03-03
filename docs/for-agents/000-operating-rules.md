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
3. Read `012-extensibility-contracts.md` before adding/changing hosts, desktop profiles, or desktop packs.
4. Read `013-option-migration-playbook.md` before renaming/removing options in `modules/options/` or `home/user/options/`.
5. Read `014-user-resolution-contract.md` before changing host identity/user wiring, CI username references, or private override behavior.
6. Read `015-profile-pack-schema.md` before changing profile metadata or desktop pack registry structures.
7. Read `016-ci-lane-policy.md` before changing CI/workflow behavior or validation trigger conditions.
8. Read `017-config-test-pyramid.md` before changing validation layering, fixture coverage, or regression policy.
9. Read `018-doc-lifecycle-and-index.md` before reorganizing docs or changing source-of-truth references.
10. Read `019-runtime-warning-budget.md` before changing runtime-smoke warning thresholds or warning acceptance policy.
11. Read `020-script-architecture-contract.md` before changing script boundaries, shared helpers, or gate/orchestration split.
12. Read `021-maintainer-change-map.md` before scoping edits; use it to choose minimum validation for each change type.
