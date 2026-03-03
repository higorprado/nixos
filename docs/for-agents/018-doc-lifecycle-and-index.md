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

## Placement Decision Tree
1. Is it a durable operating rule every agent must read first?
   - Put in root.
2. Is it a supporting contract or technical guide?
   - Put in `reference/`.
3. Is it an active roadmap or implementation plan?
   - Put in `plans/`.
4. Is it an active execution log/status tracker?
   - Put in `current-work/`.
5. Is it completed/superseded/context-only?
   - Put in `historical/`.

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

## Active Plan Index
1. `docs/for-agents/plans/905-system-up-to-date-audit-plan.md`

## Recently Completed
1. `docs/for-agents/historical/934-docs-tidy-and-workflow-plan.md`

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
