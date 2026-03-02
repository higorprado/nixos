# Lessons Learned

## Rules
0. Write important lessons you learned in document `999-lessons-learned.md`.
1. Keep lessons short and direct. Avoid verbose writing.
2. Never modify private override files unless explicitly asked.
3. Never force high-impact options (for example `custom.desktop.profile`) without explicit request.
4. Keep risky changes in small, reversible slices.
5. Validate runtime behavior, not only successful builds/evals.
6. Confirm rollback path before applying login/session/display-manager changes.
7. Treat user scope constraints literally (for example branch vs new repo).
8. If a change affects system access/login, prioritize recovery first, then feature work.
9. When adopting an upstream flake app, verify the flake package actually builds; HEAD can be temporarily broken.
10. Number `docs/for-agents` by importance: lower numbers for durable/critical rules, higher numbers for plans, audits, and execution logs (`999` remains lessons learned).
11. For this repo/user, prioritize performance and compatibility over ideology/licensing preferences when choosing technical paths.
12. For local matrix/validation scripts, prefer `builtins.getFlake "path:$PWD"` over git URL refs when you need live working-tree behavior; git/index snapshots can hide unstaged fixes.
13. Even when role-gating desktop behavior, keep option-provider modules imported (or split declarations) if shared modules reference those options; otherwise server eval can fail on unknown options.
14. In Nix modules, use `mkIf` (not eager `optionalAttrs`) for conditions that depend on `config`, otherwise fixed-point evaluation can recurse.
