# Session Recovery (Greeter/Portal/Runtime)

## Use This For
1. Greeter fails to launch.
2. Portal/session warnings increase unexpectedly.
3. Post-switch desktop behavior regresses.

## Fast Triage
1. `systemctl --failed --no-pager`
2. `systemctl status greetd.service --no-pager`
3. `systemctl --user status xdg-desktop-portal.service --no-pager`
4. `./scripts/check-runtime-smoke.sh --allow-non-graphical`

## Recovery Approach
1. Revert to last known-good generation if login/session is broken.
2. Isolate a minimal fix slice.
3. Re-run structure + runtime smoke before reattempting full switch.
