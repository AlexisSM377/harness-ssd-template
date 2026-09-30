#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/harness-sdd-test.XXXXXX")"
DEST_DIR="$TMP_DIR/project"
OUTPUT_FILE="$TMP_DIR/output.log"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  if [ -f "$OUTPUT_FILE" ]; then
    printf '%s\n' '--- salida del instalador ---' >&2
    cat "$OUTPUT_FILE" >&2
  fi
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "no se creó el archivo $1"
}

assert_contains() {
  local file="$1"
  local expected="$2"

  grep -Fq "$expected" "$file" ||
    fail "$file no contiene el texto esperado: $expected"
}

mkdir "$DEST_DIR"

project_name='Proyecto / I+D & Operaciones'
stack='Node.js / PostgreSQL & Redis'

bash "$ROOT_DIR/apply-template.sh" \
  "$DEST_DIR" \
  "$project_name" \
  "$stack" >"$OUTPUT_FILE" 2>&1

assert_file "$DEST_DIR/AGENTS.md"
assert_file "$DEST_DIR/.gitignore"
assert_file "$DEST_DIR/.claude/settings.json"
assert_file "$DEST_DIR/specs/_template/requirements.md"
assert_file "$DEST_DIR/scripts/feature-list-query"
assert_file "$DEST_DIR/scripts/validate-feature-gates"
assert_contains "$DEST_DIR/AGENTS.md" "Proyecto: **${project_name}**"
assert_contains "$DEST_DIR/AGENTS.md" "stack: \`${stack}\`"

if grep -R -Fq \
  -e '{{PROJECT_NAME}}' \
  -e '{{STACK}}' \
  "$DEST_DIR"; then
  fail "quedaron placeholders sin sustituir en el proyecto generado"
fi

[ -x "$DEST_DIR/init.sh" ] ||
  fail "init.sh no quedó marcado como ejecutable"

if command -v node >/dev/null 2>&1; then
  (
    cd "$DEST_DIR"
    HARNESS_JSON_RUNTIME=node bash ./init.sh
  ) >"$OUTPUT_FILE" 2>&1 ||
    fail "init.sh falló usando node como runtime JSON"
fi

if command -v python3 >/dev/null 2>&1; then
  (
    cd "$DEST_DIR"
    HARNESS_JSON_RUNTIME=python3 bash ./init.sh
  ) >"$OUTPUT_FILE" 2>&1 ||
    fail "init.sh falló usando python3 como runtime JSON"
fi

json_runtime=""
if command -v node >/dev/null 2>&1; then
  json_runtime="node"
elif command -v python3 >/dev/null 2>&1; then
  json_runtime="python3"
fi

if [ -n "$json_runtime" ]; then
  mkdir -p "$DEST_DIR/specs/feature-bloqueada"
  cp \
    "$DEST_DIR/specs/_template/requirements.md" \
    "$DEST_DIR/specs/feature-bloqueada/requirements.md"
  cat >"$DEST_DIR/feature_list.json" <<'JSON'
[
  {
    "id": 1,
    "name": "feature-bloqueada",
    "status": "spec_ready"
  }
]
JSON

  if (
    cd "$DEST_DIR"
    HARNESS_JSON_RUNTIME="$json_runtime" bash ./init.sh
  ) >"$OUTPUT_FILE" 2>&1; then
    fail "init.sh aceptó una feature spec_ready sin aprobación"
  fi
  assert_contains "$OUTPUT_FILE" 'no supera los gates'

  cat >"$DEST_DIR/feature_list.json" <<'JSON'
[
  {
    "id": 2,
    "name": "feature-pendiente",
    "status": "pending"
  }
]
JSON

  if (
    cd "$DEST_DIR"
    HARNESS_JSON_RUNTIME="$json_runtime" bash ./init.sh
  ) >"$OUTPUT_FILE" 2>&1; then
    fail "init.sh aceptó STATUS.md desincronizado"
  fi
  assert_contains "$OUTPUT_FILE" 'STATUS.md desactualizado'

  sed 's/Features completadas\*\*: 0\/0/Features completadas**: 0\/1/' \
    "$DEST_DIR/STATUS.md" >"$DEST_DIR/STATUS.tmp"
  mv "$DEST_DIR/STATUS.tmp" "$DEST_DIR/STATUS.md"
  (
    cd "$DEST_DIR"
    HARNESS_JSON_RUNTIME="$json_runtime" bash ./init.sh
  ) >"$OUTPUT_FILE" 2>&1 ||
    fail "init.sh rechazó una feature pending con STATUS.md sincronizado"

  sed '/Features completadas/d' \
    "$DEST_DIR/STATUS.md" >"$DEST_DIR/STATUS.tmp"
  mv "$DEST_DIR/STATUS.tmp" "$DEST_DIR/STATUS.md"
  if (
    cd "$DEST_DIR"
    HARNESS_JSON_RUNTIME="$json_runtime" bash ./init.sh
  ) >"$OUTPUT_FILE" 2>&1; then
    fail "init.sh aceptó STATUS.md sin conteo de features"
  fi
  assert_contains "$OUTPUT_FILE" 'no tiene la línea'
  printf '\n**Features completadas**: 0/1 (`feature_list.json`)\n' \
    >>"$DEST_DIR/STATUS.md"

  printf '[]\n' >"$DEST_DIR/feature_list.json"
  sed 's/Features completadas\*\*: 0\/1/Features completadas**: 0\/0/' \
    "$DEST_DIR/STATUS.md" >"$DEST_DIR/STATUS.tmp"
  mv "$DEST_DIR/STATUS.tmp" "$DEST_DIR/STATUS.md"
fi

printf '\nMARCADOR_LOCAL_NO_SOBRESCRIBIR\n' >>"$DEST_DIR/AGENTS.md"

bash "$ROOT_DIR/apply-template.sh" \
  "$DEST_DIR" \
  'Nombre diferente' \
  'Stack diferente' >"$OUTPUT_FILE" 2>&1

assert_contains "$DEST_DIR/AGENTS.md" 'MARCADOR_LOCAL_NO_SOBRESCRIBIR'
assert_contains "$DEST_DIR/AGENTS.md" "Proyecto: **${project_name}**"
assert_contains "$OUTPUT_FILE" 'SKIP: AGENTS.md ya existe'
assert_contains "$OUTPUT_FILE" 'Nada que sustituir'

missing_dest="$TMP_DIR/no-existe"
if bash "$ROOT_DIR/apply-template.sh" \
  "$missing_dest" \
  'Proyecto inválido' >"$OUTPUT_FILE" 2>&1; then
  fail "el instalador aceptó un directorio destino inexistente"
fi
assert_contains "$OUTPUT_FILE" 'no existe'

if bash "$ROOT_DIR/apply-template.sh" >"$OUTPUT_FILE" 2>&1; then
  fail "el instalador aceptó una invocación sin argumentos"
fi
assert_contains "$OUTPUT_FILE" 'Uso:'

printf 'PASS: instalación, placeholders, idempotencia y errores verificados\n'
