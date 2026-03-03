# Docs Tidy And Workflow Plan

## Objective
Reorganize documentation so it is easier to use and maintain:
1. Human docs focus on clear explanation plus practical workflows for common tasks.
2. Agent docs are split by intent (`core`, `reference`, `plans`, `current-work`, `historical`) with root containing only critical operating docs.
3. Core docs are rewritten for clarity and consistency, not only moved.
4. New agents get explicit rules for where new docs belong and how to name them.

## Non-Negotiable Constraints
1. Keep existing safety rules and validation requirements intact.
2. Do not delete historical knowledge; move and relink instead.
3. Every move/rename must preserve discoverability (indexes + backlinks updated in same slice).
4. Use numbered filenames (`NNN-name`) for all agent docs, including subfolders.

## Success Criteria
1. `docs/for-agents/` root has only super-important docs.
2. `docs/for-agents/plans/` contains active execution plans.
3. `docs/for-agents/current-work/` exists and tracks in-flight execution/status notes.
4. Human docs include a workflow-oriented section for key operations.
5. A new agent can determine doc placement rules without guessing.
6. Docs validation gates pass with zero drift errors.

## Target Information Architecture

### Agent Docs
- Keep in `docs/for-agents/` root (critical only):
  - `000-operating-rules.md`
  - `001-repo-map.md`
  - `006-validation-and-safety-gates.md`
  - `007-private-overrides-and-public-safety.md`
  - `009-private-ops-scripts.md`
  - `018-doc-lifecycle-and-index.md`
  - `999-lessons-learned.md`
- New folders:
  - `docs/for-agents/reference/` for supporting contracts/guides
  - `docs/for-agents/plans/` for active plan docs
  - `docs/for-agents/current-work/` for active execution journals/status docs
  - `docs/for-agents/historical/` for completed/superseded docs (already exists)

### Human Docs
- Keep `docs/for-humans/00-start-here.md` as onboarding entrypoint.
- Add `docs/for-humans/workflows/` for practical runbooks.
- Keep concept/reference docs concise; move long operational procedures into workflows.

## Phase 0: Baseline Mapping

### Tasks
1. Build inventory of all docs in `docs/for-agents` and `docs/for-humans` with owner intent tags:
   - `core`, `workflow`, `plan`, `current-work`, `historical`, `reference`.
2. Extract major cross-links/backlinks to avoid breaking navigation after moves.
3. Produce migration table (`from -> to -> reason -> owner`).

### Exit Criteria
1. Every doc has a target location and intent tag.
2. No ambiguous placement remains.

### Validation
1. `./scripts/check-docs-drift.sh`
2. `./scripts/check-changed-files-quality.sh origin/main`

## Phase 1: Governance Rules For New Docs

### Tasks
1. Rewrite `docs/for-agents/018-doc-lifecycle-and-index.md` with explicit placement decision tree:
   - Is it critical operating guidance? -> root
   - Is it an active execution plan? -> `plans/`
   - Is it active progress/status? -> `current-work/`
   - Is it completed/superseded? -> `historical/`
2. Update `AGENTS.md` doc-creation section so new agents follow folder policy.
3. Add naming/index rules per folder, including numbering strategy and collision handling.

### Exit Criteria
1. New agent can place any new doc deterministically.
2. Root no longer acts as generic drop-zone.

### Validation
1. `./scripts/check-docs-drift.sh`
2. `./scripts/run-validation-gates.sh structure`

## Phase 2: Agent Docs Reorganization

### Tasks
1. Create folders:
   - `docs/for-agents/reference/`
   - `docs/for-agents/plans/`
   - `docs/for-agents/current-work/`
2. Move non-critical plan docs from root into `plans/`.
3. Move active status/execution-tracking docs into `current-work/`.
4. Keep only critical docs in root; update all internal links and indexes.

### Exit Criteria
1. Root contains only critical docs.
2. `plans/` and `current-work/` are populated and indexed.
3. No broken links in docs-drift checks.

### Validation
1. `./scripts/check-docs-drift.sh`
2. `./scripts/check-changed-files-quality.sh origin/main`
3. `./scripts/run-validation-gates.sh structure`

## Phase 3: Rewrite Agent Core Docs

### Tasks
1. Rewrite core docs for brevity and consistency of structure (purpose, rules, examples, validation):
   - `000`, `001`, `006`, `007`, `009`, `018`, `999`
2. Remove duplicated policy text; point to a single source of truth per topic.
3. Ensure each core doc states:
   - when to use it,
   - what to run,
   - where related docs live.

### Exit Criteria
1. Core docs are concise and non-overlapping.
2. Repeated policy statements are reduced and centralized.

### Validation
1. `./scripts/check-docs-drift.sh`
2. `./scripts/run-validation-gates.sh structure`

## Phase 4: Rewrite Human Docs Around Workflows

### Tasks
1. Rewrite `00-start-here.md` to be task-first:
   - choose host/profile,
   - apply safely,
   - rollback,
   - validate,
   - recover from common failure modes.
2. Create `docs/for-humans/workflows/` with high-value runbooks:
   - host/profile change
   - desktop profile switch
   - private override setup/update
   - validation before commit/publish
   - rollback and recovery
3. Trim conceptual docs (`01..08`) to explain "why" and link to workflow runbooks for "how".

### Exit Criteria
1. Common operations are documented as step-by-step workflows.
2. Human docs are readable without deep repo context.

### Validation
1. `./scripts/check-docs-drift.sh`
2. `./scripts/run-validation-gates.sh structure`

## Phase 5: Indexes, Templates, And Quality Gates

### Tasks
1. Add/refresh doc indexes for:
   - agent root core docs
   - active plans
   - current work
   - historical
   - human workflows
2. Add minimal templates for new docs (plan/workflow/current-work note).
3. Ensure docs-drift checks include new folders and index references.

### Exit Criteria
1. Navigation is obvious from indexes.
2. New docs follow a predictable template and destination.

### Validation
1. `./scripts/check-docs-drift.sh`
2. `./scripts/run-validation-gates.sh structure`
3. `./scripts/check-repo-public-safety.sh`

## Execution Protocol
1. Work in small, reversible slices (move + relink + validate).
2. After each slice, run at least:
   - `./scripts/check-docs-drift.sh`
   - `./scripts/run-validation-gates.sh structure`
3. After major folder moves or lifecycle-policy rewrites, also run:
   - `./scripts/check-changed-files-quality.sh origin/main`
   - `./scripts/check-repo-public-safety.sh`
4. Before declaring complete, run:
   - `./scripts/run-validation-gates.sh all`

## Deliverables
1. Reorganized docs tree with `plans/` and `current-work/` active.
2. Rewritten agent core docs.
3. Rewritten human docs with workflow runbooks.
4. Updated governance in `AGENTS.md` + `018-doc-lifecycle-and-index.md`.
5. Final completion note in `docs/for-agents/current-work/` summarizing moves and rationale.
