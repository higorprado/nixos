# Agent Operating Rules

## Primary Objective
Ship correct, minimal, reversible changes with explicit validation evidence.

## Non-Negotiables
1. Verify ownership before editing.
2. Work in small slices.
3. Run required validation after each meaningful slice.
4. Keep public-safe boundaries intact.
5. Never commit real private override files.

## Mandatory First Reads
1. `docs/for-agents/001-repo-map.md`
2. `docs/for-agents/007-private-overrides-and-public-safety.md`
3. `docs/for-agents/009-private-ops-scripts.md`
4. `docs/for-agents/018-doc-lifecycle-and-index.md`
5. `docs/for-agents/999-lessons-learned.md`

## Required Validation Baseline
1. `./scripts/check-changed-files-quality.sh [origin/main]`
2. `./scripts/run-validation-gates.sh structure`
3. If change is high-impact, run `./scripts/run-validation-gates.sh all`.
4. Before publish, run `./scripts/check-repo-public-safety.sh`.

## Decision Rule
1. If uncertain about destructive/structural impact, stop and ask.
2. Prefer local fix over broad rewrite unless plan explicitly requires reorganization.
