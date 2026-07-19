#!/usr/bin/env bash
# init.config.sh — Comandos específicos del proyecto. Editar al instalar.

PROJECT_NAME="{{PROJECT_NAME}}"

# Binarios que deben existir en PATH
REQUIRED_TOOLS=("node" "pnpm")

# Variables de entorno críticas, ej: ("DATABASE_URL" "JWT_SECRET")
REQUIRED_ENV_VARS=()

INSTALL_CMD="pnpm install --silent"
BUILD_CMD="pnpm run build"
TEST_CMD="pnpm test -- --passWithNoTests"
LINT_CMD=""    # vacío = saltar
