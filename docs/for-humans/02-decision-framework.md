# Decision Framework

Use this flow when adding any package/config.

## Step 1: Decide Scope
1. Host-only? Put in `hosts/<host>/`.
2. Shared system policy? Put in `modules/`.
3. User app/tool behavior? Put in `home/<user>/`.

## Step 2: Decide Type
1. Package enable/install.
2. Service wiring.
3. App config payload.
4. Theme integration.

## Step 3: Place the Change
1. System package/tooling: `modules/packages/*`.
2. User package/tooling: `home/<user>/core|dev|programs/*`.
3. User service: `home/<user>/services/*`.
4. Desktop/profile behavior: `modules/profiles/*` + `home/<user>/desktop/*`.
5. Editor/terminal specifics: `home/<user>/programs/editors|terminals/*`.

## Step 4: Decide Config Delivery
1. App needs writable config at runtime: copy-once activation.
2. App only reads config: declarative source/sync.

## Step 5: Validate
Run all gates after each slice:
1. `nix flake metadata`
2. `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
3. `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
4. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
5. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
