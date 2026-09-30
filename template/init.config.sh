#!/usr/bin/env bash
# init.config.sh — Comandos específicos del proyecto. Editar al instalar.

PROJECT_NAME="{{PROJECT_NAME}}"

# Binarios del stack que deben existir en PATH. El harness detecta
# automáticamente node o python3 para validar feature_list.json.
REQUIRED_TOOLS=()

# Variables de entorno críticas, ej: ("DATABASE_URL" "JWT_SECRET")
REQUIRED_ENV_VARS=()

# Comandos del stack. Vacío = saltar con aviso. Rellenar cuando el proyecto
# tenga manifest. Ejemplo NestJS/pnpm:
#   REQUIRED_TOOLS=("node" "pnpm")
#   INSTALL_CMD="pnpm install"
#   BUILD_CMD="pnpm run build"
#   TEST_CMD="pnpm test -- --passWithNoTests"
#   LINT_CMD="pnpm run lint"
#   TYPECHECK_CMD="pnpm exec tsc --noEmit"
INSTALL_CMD=""
BUILD_CMD=""
TEST_CMD=""
LINT_CMD=""
TYPECHECK_CMD=""
