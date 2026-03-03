#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

usage() {
  cat <<'EOF'
Usage: scripts/new-host-skeleton.sh <host-name> [desktop|server] [desktop-profile]

Examples:
  scripts/new-host-skeleton.sh zeus desktop dms
  scripts/new-host-skeleton.sh ci-runner server dms
EOF
}

host_name="${1:-}"
host_role="${2:-desktop}"
desktop_profile="${3:-dms}"

if [[ "$host_name" == "-h" || "$host_name" == "--help" || "$host_name" == "help" ]]; then
  usage
  exit 0
fi

if [[ -z "$host_name" ]]; then
  usage >&2
  exit 1
fi

if [[ ! "$host_name" =~ ^[a-z0-9-]+$ ]]; then
  log_fail "new-host-skeleton" "host-name must match ^[a-z0-9-]+$"
  exit 1
fi

if [[ "$host_role" != "desktop" && "$host_role" != "server" ]]; then
  log_fail "new-host-skeleton" "role must be 'desktop' or 'server'"
  exit 1
fi

host_dir="hosts/${host_name}"
host_file="${host_dir}/default.nix"

if [[ -e "$host_dir" || -e "$host_file" ]]; then
  log_fail "new-host-skeleton" "host path already exists: ${host_dir}"
  exit 1
fi

mkdir -p "$host_dir"

if [[ "$host_role" == "desktop" ]]; then
  cat >"$host_file" <<EOF
{ lib, ... }:
{
  imports = [
    ../../modules
    ../../home/user
  ]
  ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  networking.hostName = "${host_name}";
  custom.host.role = "desktop";
  custom.user.name = lib.mkDefault "ops";
  custom.desktop.profile = "${desktop_profile}";
}
EOF
else
  cat >"$host_file" <<EOF
{ lib, ... }:
{
  imports = [
    ../../modules
  ]
  ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  networking.hostName = "${host_name}";
  custom.host.role = "server";
  custom.user.name = "ops";
  custom.desktop.profile = "${desktop_profile}";

  # Eval/build-focused skeleton defaults.
  boot.isContainer = true;
  networking.useHostResolvConf = lib.mkForce false;
  nixpkgs.config.allowUnfree = true;
}
EOF
fi

cat <<EOF
[new-host-skeleton] created ${host_file}

Add this descriptor entry to hosts/host-descriptors.nix:

  ${host_name} = {
    role = "${host_role}";
    desktopProfile = "${desktop_profile}";
    integrations = {
      # toggle host integrations as needed
      # disko = true;
      # niri = true;
      # hyprland = true;
      # dms = true;
      # homeManager = true;
      # keyrs = true;
    };
  };
EOF
