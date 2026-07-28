# Plan 005: Add a TYPECHECK_CMD slot to init.config.sh / init.sh

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 9056fc3..HEAD -- template/init.config.sh template/init.sh`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: dx
- **Planned at**: commit `9056fc3`, 2026-07-28

## Why this matters

This finding comes from auditing a real project (`odc`, an unrelated repo)
built with this template. Its frontend (TanStack Start + Vite + TypeScript)
has no typecheck script in `package.json` at all — only `build`, `test`,
`lint`, etc. `vite build` transpiles per-file; it does not run a full
program-wide `tsc` type check, so a type error that's still structurally
valid per-file JS (a mismatched prop type, for instance) can pass both
`BUILD_CMD` and `LINT_CMD` clean and only ever surface in an editor or at
runtime.

This isn't a mistake specific to that project — it's a gap in what this
template asks a project to configure. `template/init.config.sh` gives a
project four command slots: `INSTALL_CMD`, `BUILD_CMD`, `TEST_CMD`,
`LINT_CMD`. There is no `TYPECHECK_CMD` slot at all, so nothing in the
template's own scaffolding prompts a project to wire one up, even though
typecheck-as-a-separate-step-from-build is a standard, common need for any
TypeScript (or similarly statically-typed) stack this stack-agnostic
template gets applied to. This plan adds the slot and the corresponding
`init.sh` step, following the exact optional/skip-with-warning pattern the
other three commands already use.

## Current state

- `template/init.config.sh` (full file, 24 lines):

  ```bash
  #!/usr/bin/env bash
  # init.config.sh — Comandos específicos del proyecto. Editar al instalar.

  PROJECT_NAME="{{PROJECT_NAME}}"

  # Binarios que deben existir en PATH
  # node es necesario para las verificaciones de feature_list.json en init.sh
  REQUIRED_TOOLS=("node")

  # Variables de entorno críticas, ej: ("DATABASE_URL" "JWT_SECRET")
  REQUIRED_ENV_VARS=()

  # Comandos del stack. Vacío = saltar con aviso. Rellenar cuando el proyecto
  # tenga manifest. Ejemplo NestJS/pnpm:
  #   REQUIRED_TOOLS=("node" "pnpm")
  #   INSTALL_CMD="pnpm install"
  #   BUILD_CMD="pnpm run build"
  #   TEST_CMD="pnpm test -- --passWithNoTests"
  #   LINT_CMD="pnpm run lint"
  INSTALL_CMD=""
  BUILD_CMD=""
  TEST_CMD=""
  LINT_CMD=""
  ```

- `template/init.sh` — section "## 6. TESTS" (líneas 150-167) is the last
  command-execution section; its `LINT_CMD` block has no separate numbered
  header of its own (it's appended directly under "## 6. TESTS" rather than
  getting a "## 7." of its own) — this plan follows that same precedent for
  `TYPECHECK_CMD`, adding it as an unnumbered `if` block rather than
  renumbering any existing section:

  ```bash
  # ── 6. TESTS ─────────────────────────────────
  echo ""
  echo "→ Ejecutando tests..."
  if [ -n "$TEST_CMD" ]; then
    eval "$TEST_CMD" 2>&1
    ok "Tests pasados"
  else
    warn "TEST_CMD vacío en init.config.sh — se salta tests"
  fi

  if [ -n "$LINT_CMD" ]; then
    echo ""
    echo "→ Lint..."
    eval "$LINT_CMD" 2>&1
    ok "Lint sin errores"
  else
    warn "LINT_CMD vacío en init.config.sh — se salta lint"
  fi

  # ── 7. RESUMEN ───────────────────────────────
  ```

## Commands you will need

No build/test suite in this repo. Verification is structural `grep` plus a
direct run of `template/init.sh` if a Node/bash environment is available in
the executor's sandbox (optional — the grep checks alone are sufficient to
confirm this plan's done criteria).

| Purpose | Command | Expected on success |
|---|---|---|
| Confirm the new var exists in init.config.sh | `grep -n "TYPECHECK_CMD" template/init.config.sh` | at least 1 match |
| Confirm the new step exists in init.sh | `grep -n "TYPECHECK_CMD" template/init.sh` | at least 2 matches (the `if` check + the warn message) |

## Scope

**In scope**:
- `template/init.config.sh` (add `TYPECHECK_CMD=""` + mention it in the
  example comment)
- `template/init.sh` (add the conditional execution block)

**Out of scope** (do NOT touch):
- Reordering or renumbering any existing `## N.` section header in
  `template/init.sh` — this plan adds an unnumbered block after the
  existing `LINT_CMD` block, following the precedent `LINT_CMD` itself set
  (it also has no own numbered header).
- `template/docs/verification.md` — not touched by this plan; if it later
  needs a mention of typechecking, that's a separate, smaller follow-up,
  not bundled here.
- The `odc` project used as evidence above — separate, unrelated repo, do
  **not** open, read, or modify it.

## Git workflow

- Branch: `main`.
- Commit message: `feat(template): add TYPECHECK_CMD slot to init.config.sh/init.sh`

## Steps

### Step 1: Add `TYPECHECK_CMD` to `template/init.config.sh`

```diff
 # Comandos del stack. Vacío = saltar con aviso. Rellenar cuando el proyecto
 # tenga manifest. Ejemplo NestJS/pnpm:
 #   REQUIRED_TOOLS=("node" "pnpm")
 #   INSTALL_CMD="pnpm install"
 #   BUILD_CMD="pnpm run build"
 #   TEST_CMD="pnpm test -- --passWithNoTests"
 #   LINT_CMD="pnpm run lint"
+#   TYPECHECK_CMD="pnpm exec tsc --noEmit"
 INSTALL_CMD=""
 BUILD_CMD=""
 TEST_CMD=""
 LINT_CMD=""
+TYPECHECK_CMD=""
```

**Verify**: `grep -n "TYPECHECK_CMD" template/init.config.sh` → at least 1 match (2 expected: the example comment + the empty default)

### Step 2: Add the execution step to `template/init.sh`

Insert immediately after the existing `LINT_CMD` `if` block (after its
closing `fi`, before the `# ── 7. RESUMEN` comment):

```diff
 if [ -n "$LINT_CMD" ]; then
   echo ""
   echo "→ Lint..."
   eval "$LINT_CMD" 2>&1
   ok "Lint sin errores"
 else
   warn "LINT_CMD vacío en init.config.sh — se salta lint"
 fi

+if [ -n "$TYPECHECK_CMD" ]; then
+  echo ""
+  echo "→ Typecheck..."
+  eval "$TYPECHECK_CMD" 2>&1
+  ok "Typecheck sin errores"
+else
+  warn "TYPECHECK_CMD vacío en init.config.sh — se salta typecheck"
+fi
+
 # ── 7. RESUMEN ───────────────────────────────
```

**Verify**: `grep -n "TYPECHECK_CMD" template/init.sh` → at least 2 matches

## Test plan

No test runner in this repo. As an extra sanity check (optional, only if
bash + node are available in the executor's environment): copy
`template/init.config.sh` to a scratch location, source it, confirm
`$TYPECHECK_CMD` is an empty string and the new `init.sh` block doesn't
error when `set -e` is active with an empty/false-y variable check — the
`if [ -n "$TYPECHECK_CMD" ]` guard already handles this identically to how
`BUILD_CMD`/`TEST_CMD`/`LINT_CMD` do, so this is confirming consistency,
not new behavior.

## Done criteria

- [ ] `grep -n "TYPECHECK_CMD" template/init.config.sh` → at least 1 match
- [ ] `grep -n "TYPECHECK_CMD" template/init.sh` → at least 2 matches
- [ ] No existing `## N.` section header in `template/init.sh` was renumbered
- [ ] `git status --porcelain` shows changes only in the 2 in-scope files
- [ ] `plans/README.md` status row for 005 updated

## STOP conditions

- The line numbers/content in "Current state" don't match the live files —
  re-verify before editing.
- You're tempted to give `TYPECHECK_CMD` its own numbered `## N.` section
  header and renumber "RESUMEN" — don't; this plan deliberately follows the
  existing unnumbered-`LINT_CMD` precedent to minimize diff risk.
- You're tempted to also update `docs/verification.md` — out of scope for
  this plan; flag it as a possible follow-up in your NOTES instead of doing
  it here.

## Maintenance notes

- Like `BUILD_CMD`/`TEST_CMD`/`LINT_CMD`, an empty `TYPECHECK_CMD` only
  produces a `warn()`, never a `fail()` — a project that hasn't configured
  it yet (or whose stack has no separate typecheck step, e.g. plain JS)
  isn't blocked. This mirrors the existing three commands' philosophy
  exactly; do not change any of them to `fail()` while doing this.
- If a future revision adds more optional command slots (e.g. a
  `SECURITY_AUDIT_CMD`), follow this same pattern: empty-string default,
  `warn()` on skip, and no renumbering of existing sections.
