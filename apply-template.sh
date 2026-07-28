#!/usr/bin/env bash
# apply-template.sh — instala el harness SDD en un proyecto existente
# Uso: ./apply-template.sh <dir-proyecto-destino> <nombre-proyecto> [stack]
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/template"

usage() {
  echo "Uso: $0 <dir-proyecto-destino> <nombre-proyecto> [stack]"
  echo ""
  echo "  <dir-proyecto-destino>  Debe existir ya (este script no lo crea)."
  echo "  <nombre-proyecto>       Sustituye {{PROJECT_NAME}} en los archivos copiados."
  echo "  [stack]                 Sustituye {{STACK}}. Por defecto: \"por definir\"."
  exit 1
}

[ $# -ge 2 ] || usage

DEST_DIR="$1"
PROJECT_NAME="$2"
STACK="${3:-por definir}"

[ -d "$DEST_DIR" ] || { echo "Error: el directorio destino '$DEST_DIR' no existe. Créalo primero." >&2; usage; }
[ -d "$TEMPLATE_DIR" ] || { echo "Error: no se encontró template/ junto a este script." >&2; exit 1; }

echo "Instalando harness SDD en: $DEST_DIR"
echo "  Proyecto: $PROJECT_NAME"
echo "  Stack:    $STACK"
echo ""

COPIED_FILES=()

while IFS= read -r -d '' src; do
  rel="${src#"$TEMPLATE_DIR"/}"
  dest="$DEST_DIR/$rel"
  if [ -e "$dest" ]; then
    echo "SKIP: $rel ya existe"
    continue
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  COPIED_FILES+=("$dest")
  echo "OK: $rel copiado"
done < <(find "$TEMPLATE_DIR" -type f -print0)

if [ "${#COPIED_FILES[@]}" -gt 0 ]; then
  echo ""
  echo "Sustituyendo placeholders..."
  # Escapar caracteres especiales de sed en el valor de reemplazo
  PROJECT_NAME_ESC=$(printf '%s' "$PROJECT_NAME" | sed -e 's/[\/&]/\\&/g')
  STACK_ESC=$(printf '%s' "$STACK" | sed -e 's/[\/&]/\\&/g')
  for f in "${COPIED_FILES[@]}"; do
    sed -i "s/{{PROJECT_NAME}}/${PROJECT_NAME_ESC}/g; s/{{STACK}}/${STACK_ESC}/g" "$f"
  done
else
  echo ""
  echo "Nada que sustituir (todos los archivos ya existían en destino)."
fi

if [ -f "$DEST_DIR/init.sh" ]; then
  chmod +x "$DEST_DIR/init.sh"
fi

echo ""
echo "Listo. Próximos pasos:"
echo "  1) Edita $DEST_DIR/init.config.sh con las herramientas y comandos reales del proyecto"
echo "  2) Rellena $DEST_DIR/docs/conventions.md"
echo "  3) Ejecuta ./init.sh dentro de $DEST_DIR"
echo "  4) Añade features a $DEST_DIR/feature_list.json"
echo "  5) Revisa .gitignore (ya incluye .obsidian/) y añade lo especifico de tu stack"
