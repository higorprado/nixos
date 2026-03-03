# GitHub Public Readiness Audit (Execution Runbook)

## Objective
Verify this NixOS repo is safe to publish publicly, free of accidental sensitive data, and cleaned of stale/outdated operational artifacts.

## Execution Policy
1. Execute steps in order without skipping.
2. Persist all evidence under a timestamped `reports/repo-readiness-<timestamp>/` directory.
3. Update this checklist during execution.
4. For scripts, classify each as `keep`, `repair`, `archive`, or `move-private`.

## Step Checklist
- [x] Step 1: Initialize audit workspace and baseline snapshots.
- [x] Step 2: Run public-safety checks (existing + expanded scans).
- [x] Step 3: Validate private override boundaries.
- [x] Step 4: Run mandatory 5 Nix validation gates.
- [x] Step 5: Run outdated/portability pattern scan.
- [x] Step 6: Build scripts inventory (size, references, metadata).
- [x] Step 7: Run script static quality checks (`bash -n`, `shellcheck`, pattern flags).
- [x] Step 8: Build script dependency/call graph.
- [x] Step 9: Classify each script (`keep|repair|archive|move-private`) with reasons.
- [x] Step 10: Run safe runtime checks for non-destructive scripts only.
- [x] Step 11: Produce final readiness report with blockers and action plan.
- [x] Step 12: Evaluate publish gate (`GO`/`NO-GO`).

## Deliverables
1. `reports/repo-readiness-<timestamp>/summary.md`
2. `reports/repo-readiness-<timestamp>/scripts/classification.md`
3. Raw artifacts under `reports/repo-readiness-<timestamp>/raw/` and `.../scripts/`

## Publish Gate (must all pass)
1. No unallowlisted high-confidence secret findings.
2. Private overrides tracked only as `*.example`.
3. Mandatory Nix gates pass.
4. Every script has an explicit disposition and owner action.
5. Outdated script/path assumptions are repaired, moved, or archived.
