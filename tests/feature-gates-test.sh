#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE_SCRIPT="$ROOT_DIR/template/scripts/validate-feature-gates"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/harness-feature-gates-test.XXXXXX")"
FEATURE_DIR="$TMP_DIR/specs/example"
OUTPUT_FILE="$TMP_DIR/output.log"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  if [ -f "$OUTPUT_FILE" ]; then
    cat "$OUTPUT_FILE" >&2
  fi
  exit 1
}

write_approved_requirements() {
  cat >"$FEATURE_DIR/requirements.md" <<'MARKDOWN'
---
feature: "example"
status: approved
---

# Requisitos

- **R1**: WHEN ocurre algo THE SYSTEM SHALL responder
- **R2**: IF hay un error THEN THE SYSTEM SHALL rechazarlo

## Aprobación

- [x] Aprobado por humano (fecha: 2026-07-28)
MARKDOWN
}

write_complete_traceability() {
  cat >"$FEATURE_DIR/traceability.md" <<'MARKDOWN'
| Requisito | Test (archivo::nombre) | Commit (hash + mensaje) |
|---|---|---|
| R1 | tests/example.test::R1 | abc123 feat(example): responder (R1) |
| R2 | tests/example.test::R2 | def456 feat(example): rechazar (R2) |
MARKDOWN
}

run_gate() {
  (
    cd "$TMP_DIR"
    bash "$GATE_SCRIPT" example "$1"
  ) >"$OUTPUT_FILE" 2>&1
}

expect_rejection() {
  local status="$1"
  local expected="$2"

  if run_gate "$status"; then
    fail "el gate aceptó un fixture inválido para $status"
  fi
  grep -Fq "$expected" "$OUTPUT_FILE" ||
    fail "el gate no explicó el rechazo; se esperaba: $expected"
}

mkdir -p "$FEATURE_DIR"

write_approved_requirements
run_gate spec_ready ||
  fail "una feature spec_ready aprobada fue rechazada"

run_gate in_progress ||
  fail "una feature in_progress aprobada fue rechazada"

write_complete_traceability
run_gate "done" ||
  fail "una feature done con trazabilidad completa fue rechazada"

sed 's/status: approved/status: draft/' \
  "$FEATURE_DIR/requirements.md" >"$FEATURE_DIR/requirements.tmp"
mv "$FEATURE_DIR/requirements.tmp" "$FEATURE_DIR/requirements.md"
expect_rejection spec_ready 'status: approved'
expect_rejection in_progress 'status: approved'

write_approved_requirements
sed 's/- \[x\]/- [ ]/' \
  "$FEATURE_DIR/requirements.md" >"$FEATURE_DIR/requirements.tmp"
mv "$FEATURE_DIR/requirements.tmp" "$FEATURE_DIR/requirements.md"
expect_rejection in_progress 'aprobación humana'

write_approved_requirements
sed 's/2026-07-28/____-__-__/' \
  "$FEATURE_DIR/requirements.md" >"$FEATURE_DIR/requirements.tmp"
mv "$FEATURE_DIR/requirements.tmp" "$FEATURE_DIR/requirements.md"
expect_rejection in_progress 'fecha YYYY-MM-DD'

write_approved_requirements
write_complete_traceability
sed 's/tests\/example.test::R2/pendiente/' \
  "$FEATURE_DIR/traceability.md" >"$FEATURE_DIR/traceability.tmp"
mv "$FEATURE_DIR/traceability.tmp" "$FEATURE_DIR/traceability.md"
expect_rejection "done" 'filas incompletas'

write_complete_traceability
sed '/| R2 |/d' \
  "$FEATURE_DIR/traceability.md" >"$FEATURE_DIR/traceability.tmp"
mv "$FEATURE_DIR/traceability.tmp" "$FEATURE_DIR/traceability.md"
expect_rejection "done" 'exactamente una fila'

printf 'PASS: gates de aprobación humana y trazabilidad verificados\n'
