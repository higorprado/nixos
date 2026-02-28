# Multi-Host Model

## Design
1. Hosts select; modules implement.
2. Profile option controls desktop stack variants.
3. Shared logic should remain host-agnostic.

## Implementation Pattern
1. Host file imports:
   - hardware files
   - `../../modules`
   - `../../home/<user>`
2. Host sets:
   - `networking.hostName`
   - `custom.desktop.profile`
   - feature flags

## Agent Rule
When change is needed for one host only, keep condition in host file.
When change should apply to future hosts, put it in shared module and gate by option/profile.
