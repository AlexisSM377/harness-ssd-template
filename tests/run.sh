#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for test_file in "$SCRIPT_DIR"/*-test.sh "$SCRIPT_DIR"/*-consistency.sh; do
  [ -e "$test_file" ] || continue
  printf '==> %s\n' "$(basename "$test_file")"
  bash "$test_file"
done

printf '\nTodas las pruebas pasaron.\n'
