#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "[full-validation] structure gates"
./scripts/check-desktop-capability-usage.sh
./scripts/check-option-declaration-boundary.sh

echo "[full-validation] predator gates"
./scripts/check-profile-matrix.sh
HM_USER="$(nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.user.name)"
nix flake metadata
nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion
nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.${HM_USER}.home.stateVersion
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.${HM_USER}.home.path
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel

echo "[full-validation] server-example gates"
nix eval path:$PWD#nixosConfigurations.server-example.config.custom.host.role
nix eval --json path:$PWD#nixosConfigurations.server-example.config.custom.desktop.capabilities
nix build --no-link path:$PWD#nixosConfigurations.server-example.config.system.build.toplevel

echo "[full-validation] ok"
