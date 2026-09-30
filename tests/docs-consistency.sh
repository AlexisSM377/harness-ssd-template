#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"

  grep -Fq "$expected" "$file" ||
    fail "$file no contiene la referencia esperada: $expected"
}

checkpoint_max="$(
  awk '
    /^## C[0-9]+ / {
      checkpoint = $2
      sub(/^C/, "", checkpoint)
      if (checkpoint > max) max = checkpoint
    }
    END {
      if (max > 0) print max
    }
  ' template/CHECKPOINTS.md
)"

[ -n "$checkpoint_max" ] ||
  fail "no se encontraron checkpoints en template/CHECKPOINTS.md"

assert_contains README.md "C1..C${checkpoint_max}"
assert_contains template/AGENTS.md "C1..C${checkpoint_max}"
assert_contains template/docs/specs.md "C1–C${checkpoint_max}"
assert_contains template/.claude/agents/leader.md "C2..C${checkpoint_max}"
assert_contains template/CHECKPOINTS.md "C1–C${checkpoint_max}"

printf 'PASS: referencias de checkpoints sincronizadas (C1–C%s)\n' "$checkpoint_max"
