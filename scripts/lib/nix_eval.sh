#!/usr/bin/env bash

nix_eval_json_expr() {
  local expr="$1"
  nix eval --json --impure --expr "$expr"
}
