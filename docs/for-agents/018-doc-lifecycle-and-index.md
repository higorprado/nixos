# Doc Lifecycle and Index

## Folder Model
1. `docs/for-agents/` root:
   - critical operating docs only.
2. `docs/for-agents/reference/`:
   - supporting contracts/guides used by agents.
3. `docs/for-agents/plans/`:
   - active plans.
4. `docs/for-agents/current-work/`:
   - in-flight execution logs/status notes.
5. `docs/for-agents/historical/`:
   - completed/superseded plans, audits, and execution notes.

## Document-Driven Workflow (Mandatory)
1. Work must be documented before and during execution for non-trivial changes.
2. If work spans multiple slices, multiple files, or structural moves:
   - create/update a plan in `docs/for-agents/plans/`,
   - create/update a matching execution log in `docs/for-agents/current-work/`.
3. Each completed slice must update the execution log with:
   - what changed,
   - validation commands run,
   - result summary.
4. When work is complete:
   - move plan and execution log to `docs/for-agents/historical/`,
   - update indexes in the same commit.

## Placement Decision System
1. `root`:
   - only durable, must-read operating policy.
2. `reference/`:
   - stable supporting contracts/guides.
3. `plans/`:
   - active roadmap docs (what will be done).
4. `current-work/`:
   - active execution logs (what is being done now).
5. `historical/`:
   - completed/superseded plans, logs, audits (context only).

## Transition Rules
1. `plans/` -> `historical/`:
   - move when objective is completed or superseded.
2. `current-work/` -> `historical/`:
   - move when no further execution is expected.
3. `reference/`:
   - stays reference unless superseded.
4. `root`:
   - only promote docs with long-lived, universal operational importance.

## Naming Rules
1. Use `NNN-name` in all agent-doc folders.
2. Keep stable numbering; do not renumber existing files unless required by a migration plan.
3. If adding a new doc, choose the next available number within the target folder context.

## Templates
1. Agent plan template: `docs/templates/for-agents-plan-template.md`
2. Agent current-work template: `docs/templates/for-agents-current-work-template.md`
3. Human workflow template: `docs/templates/for-humans-workflow-template.md`

## Root Critical Docs
1. `000-operating-rules.md`
2. `001-repo-map.md`
3. `006-validation-and-safety-gates.md`
4. `007-private-overrides-and-public-safety.md`
5. `009-private-ops-scripts.md`
6. `018-doc-lifecycle-and-index.md`
7. `999-lessons-learned.md`

## Canonical Active Indexes
1. Active plans are listed only in `docs/for-agents/plans/900-plans-index.md`.
2. Active execution notes are listed only in `docs/for-agents/current-work/900-current-work-index.md`.
3. Do not duplicate mutable active/recent lists in root docs.
4. Completed records live in `docs/for-agents/historical/`.

## Reference Index
1. `docs/for-agents/reference/002-change-decision-algorithm.md`
2. `docs/for-agents/reference/003-multi-host-model.md`
3. `docs/for-agents/reference/004-dev-environment-model.md`
4. `docs/for-agents/reference/005-nvim-ops-guide.md`
5. `docs/for-agents/reference/008-flake-and-structure-pattern.md`
6. `docs/for-agents/reference/010-profile-switch-and-greeter-safety.md`
7. `docs/for-agents/reference/011-module-ownership-boundaries.md`
8. `docs/for-agents/reference/012-extensibility-contracts.md`
9. `docs/for-agents/reference/013-option-migration-playbook.md`
10. `docs/for-agents/reference/014-user-resolution-contract.md`
11. `docs/for-agents/reference/015-profile-pack-schema.md`
12. `docs/for-agents/reference/016-ci-lane-policy.md`
13. `docs/for-agents/reference/017-config-test-pyramid.md`
14. `docs/for-agents/reference/019-runtime-warning-budget.md`
15. `docs/for-agents/reference/020-script-architecture-contract.md`
16. `docs/for-agents/reference/021-maintainer-change-map.md`
17. `docs/for-agents/reference/924-catppuccin-gtk-theme-policy.md`
18. `docs/for-agents/reference/926-mutable-config-registry.md`

## Historical Rule
1. Never delete historical docs to tidy root noise.
2. Move to `historical/` and keep links valid.
3. Historical docs are context only, not source-of-truth policy.
