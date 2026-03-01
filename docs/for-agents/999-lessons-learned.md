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
