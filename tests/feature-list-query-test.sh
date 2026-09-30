#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUERY_SCRIPT="$ROOT_DIR/template/scripts/feature-list-query"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/harness-feature-list-test.XXXXXX")"
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

write_valid_fixture() {
  cat >"$TMP_DIR/feature_list.json" <<'JSON'
[
  {
    "id": 1,
    "name": "primera-feature",
    "status": "done",
    "priority": "P1"
  },
  {
    "id": 2,
    "name": "segunda-feature",
    "status": "pending"
  },
  {
    "id": 3,
    "name": "tercera-feature",
    "status": "spec_ready"
  }
]
JSON
}

run_query() {
  local runtime="$1"
  shift
  (
    cd "$TMP_DIR"
    HARNESS_JSON_RUNTIME="$runtime" bash "$QUERY_SCRIPT" "$@"
  )
}

runtimes=()
command -v node >/dev/null 2>&1 && runtimes+=("node")
command -v python3 >/dev/null 2>&1 && runtimes+=("python3")

if [ "${#runtimes[@]}" -eq 0 ]; then
  printf 'SKIP: node y python3 no están disponibles\n'
  exit 0
fi

for runtime in "${runtimes[@]}"; do
  write_valid_fixture
  run_query "$runtime" validate >"$OUTPUT_FILE" 2>&1 ||
    fail "el fixture válido fue rechazado por $runtime"

  [ "$(run_query "$runtime" count all)" = "3" ] ||
    fail "$runtime devolvió un total incorrecto"
  [ "$(run_query "$runtime" count pending)" = "1" ] ||
    fail "$runtime devolvió un conteo pending incorrecto"
  [ "$(run_query "$runtime" first pending name)" = "segunda-feature" ] ||
    fail "$runtime devolvió una próxima feature incorrecta"
  active_output="$(run_query "$runtime" active | tr -d '\r')"
  [ "$active_output" = $'primera-feature|done\ntercera-feature|spec_ready' ] ||
    fail "$runtime no incluyó spec_ready entre las features con gate"

  cat >"$TMP_DIR/feature_list.json" <<'JSON'
[
  {"id": 1, "name": "primera", "status": "pending"},
  {"id": 1, "name": "segunda", "status": "estado-inventado"}
]
JSON

  if run_query "$runtime" validate >"$OUTPUT_FILE" 2>&1; then
    fail "$runtime aceptó un feature_list.json inválido"
  fi
  grep -Eq 'id duplicado|status no es válido' "$OUTPUT_FILE" ||
    fail "$runtime no explicó el error de schema"
done

printf 'PASS: consultas y schema de feature_list.json verificados con %s\n' \
  "${runtimes[*]}"
