# Doc Lifecycle and Canonical Index

## Lifecycle States
1. `canonical`
   - Stable source-of-truth for behavior, contracts, and operating rules.
   - Kept in `docs/for-agents/` root.
2. `active-plan`
   - Current execution roadmap for an in-flight program.
   - Keep only the active plan in root.
3. `historical`
   - Completed/superseded plans, audits, and execution logs.
   - Stored under `docs/for-agents/historical/`.

## Canonical Topic Index (Single Source of Truth)
1. Operating rules: `000-operating-rules.md`
2. Repo topology: `001-repo-map.md`
3. Decision algorithm: `002-change-decision-algorithm.md`
4. Multi-host model: `003-multi-host-model.md`
5. Dev environment model: `004-dev-environment-model.md`
6. Nvim ops: `005-nvim-ops-guide.md`
7. Validation and safety: `006-validation-and-safety-gates.md`
8. Private overrides/public safety: `007-private-overrides-and-public-safety.md`
9. Flake structure pattern: `008-flake-and-structure-pattern.md`
10. Private ops scripts boundary: `009-private-ops-scripts.md`
11. Greeter/profile switch safety: `010-profile-switch-and-greeter-safety.md`
12. Module ownership boundaries: `011-module-ownership-boundaries.md`
13. Extensibility contracts: `012-extensibility-contracts.md`
14. Option migration playbook: `013-option-migration-playbook.md`
15. User-resolution contract: `014-user-resolution-contract.md`
16. Profile/pack schema contract: `015-profile-pack-schema.md`
17. CI lane policy: `016-ci-lane-policy.md`
18. Config test pyramid: `017-config-test-pyramid.md`
19. Lessons learned: `999-lessons-learned.md`

## Active Plan
1. `930-definitive-maintainability-extensibility-plan.md`

## Historical Plan Rule
1. When a plan is complete or superseded, move it to `docs/for-agents/historical/`.
2. Keep references from canonical docs pointing to canonical docs whenever possible.
3. Use historical docs for context, not as authoritative policy.
