#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 OUTPUT_PARENT MEMO_Z3_CACHE" >&2
  exit 2
fi

readonly OUTPUT_PARENT="$1"
readonly Z3_CACHE="$2"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SAIL_SRC_REPO="${SAIL_SRC_REPO:-https://github.com/axiom-crypto/sail-riscv.git}"
readonly PIN_FILE="${SAIL_SRC_COMMIT_FILE:-$SCRIPT_DIR/SAIL_SRC_COMMIT}"
readonly SAIL_SRC_COMMIT="$(tr -d '\r\n' < "$PIN_FILE")"

if [[ ! "$SAIL_SRC_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
  echo "SAIL_SRC_COMMIT must contain one full lowercase commit SHA" >&2
  exit 1
fi

# Accept only commits reachable from a branch or tag of the Sail source
# repository. GitHub serves any commit in a repository's fork network by SHA, so
# an unreachable SHA could name a fork's commit, whose generator would then run.
require_reachable() {
  local source_dir="$1"
  if ! git -C "$source_dir" rev-list --branches --remotes --tags | grep -Fx "$SAIL_SRC_COMMIT" > /dev/null; then
    echo "SAIL_SRC_COMMIT is not reachable from any branch or tag of the Sail source" >&2
    exit 1
  fi
}

generate_from_source() {
  local source_dir="$1"
  if [[ "$(git -C "$source_dir" rev-parse HEAD)" != "$SAIL_SRC_COMMIT" ]]; then
    echo "Sail source does not match SAIL_SRC_COMMIT" >&2
    exit 1
  fi
  require_reachable "$source_dir"
  bash "$source_dir/model/openvm/generate-lean.sh" "$OUTPUT_PARENT" "$Z3_CACHE"
}

if [[ -n "${SAIL_SOURCE_DIR:-}" ]]; then
  generate_from_source "$SAIL_SOURCE_DIR"
  exit 0
fi

readonly WORK="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK"
}
trap cleanup EXIT

git clone --quiet --filter=blob:none --no-checkout "$SAIL_SRC_REPO" "$WORK/sail-riscv"
require_reachable "$WORK/sail-riscv"
git -C "$WORK/sail-riscv" checkout --quiet --detach "$SAIL_SRC_COMMIT"
if [[ "$(git -C "$WORK/sail-riscv" rev-parse HEAD)" != "$SAIL_SRC_COMMIT" ]]; then
  echo "checked-out Sail source does not match SAIL_SRC_COMMIT" >&2
  exit 1
fi

echo "generating from $SAIL_SRC_REPO@$SAIL_SRC_COMMIT"
generate_from_source "$WORK/sail-riscv"
