# Plan 004: Require new env vars to be documented in the same commit that introduces them

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 9056fc3..HEAD -- template/AGENTS.md template/.claude/agents/implementer.md`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: docs
- **Planned at**: commit `9056fc3`, 2026-07-28

## Why this matters

This finding comes from auditing a real project (`odc`, an unrelated repo)
built with this template. Its `docs/conventions.md` has an "Variables de
entorno" table documenting exactly 3 environment variables
(`DATABASE_URL`, `JWT_SECRET`, `PORT`). The running code, however, reads 7:
those three plus `NODE_ENV`, `SEED_PASSWORD`, and three Cloudinary
credentials (`CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`,
`CLOUDINARY_API_SECRET`) — all introduced by later features
(file-upload support, the seed script) after the conventions doc was first
filled in. `.env.example` in that project happens to list all 7 correctly,
but the doc whose own stated purpose is "cuando tengas duda... busca aquí
primero" (`docs/conventions.md`'s header) fell behind and stayed behind.

This template already tells a first session to fill in
`docs/conventions.md`'s env-var table (`docs/conventions.md`'s own header:
"Rellenar en la primera sesión... no lo dejes vacío más de una sesión de
trabajo") — but nothing in `AGENTS.md`'s hard rules or `implementer.md`'s
pre-completion checklist says what happens *after* that first session, when
feature #7 or #14 introduces a new variable no one thought of at project
start. That's exactly the gap the real project fell into. This plan adds an
explicit rule: a feature that introduces a new environment variable updates
`docs/conventions.md` and `.env.example` in the same close-out, not as a
someday cleanup.

## Current state

- `template/AGENTS.md` — section "## 4. Reglas duras (no negociables)"
  (líneas 74-84):

  ```
  - **Una sola feature a la vez.** No mezcles cambios de varias tareas en la misma sesión.
  - **No se implementa sin spec aprobada.** Si la feature está `pending`, primero
    se escribe y aprueba la spec (ver §3).
  - **No declares una tarea `done` sin build verde y tests sin regresión.**
    Ejecuta `./init.sh` y confirma que todo pasa.
  - **Documenta lo que haces** en `progress/current.md` mientras trabajas, no al final.
  - **Deja el repositorio limpio** antes de cerrar la sesión (ver §6).
  - **Si no sabes cómo se hace algo en este proyecto, busca en `docs/`** antes de inventarlo.
    Si no está en docs/, sigue el patrón del módulo más similar en el código existente.
  ```

  No bullet addresses environment variables specifically.

- `template/.claude/agents/implementer.md` — section "## Checklist antes de
  declarar 'listo'" (líneas 48-58):

  ```
  - [ ] Build pasa sin errores (`$BUILD_CMD` de `init.config.sh`)
  - [ ] Tests pasan sin romper los existentes (`$TEST_CMD`)
  - [ ] Cada requisito de la spec tiene al menos un test que lo nombra
  - [ ] `specs/<feature>/traceability.md` no tiene ninguna fila "pendiente"
  - [ ] Sin `console.log`/prints de debug
  - [ ] Sin `TODO` sin contexto
  - [ ] El código respeta las capas de `docs/architecture.md` (domain sin
        imports de infrastructure, application depende solo de interfaces)
  ```

  No item checks for new environment variables.

- `template/docs/conventions.md` — section "## Variables de entorno"
  (líneas 80-83), the section this rule protects:

  ```
  <!-- Lista de variables requeridas por el proyecto, sin valores reales. -->
  ```

  (This is the skeleton shipped by the template — a downstream project
  fills this in with a real table, as `odc`'s did. This plan does not
  change this file's content, only adds the rule elsewhere that keeps it
  in sync going forward.)

## Commands you will need

No build/test suite in this repo. Verification is structural `grep`.

| Purpose | Command | Expected on success |
|---|---|---|
| Confirm AGENTS.md has the new rule | `grep -n "variable de entorno" template/AGENTS.md` | at least 1 match inside §4 |
| Confirm implementer.md checklist has the new item | `grep -n "variable de entorno" template/.claude/agents/implementer.md` | 1 match |

## Scope

**In scope**:
- `template/AGENTS.md` (§4 "Reglas duras" — add one bullet)
- `template/.claude/agents/implementer.md` (checklist — add one item)

**Out of scope** (do NOT touch):
- `template/docs/conventions.md` — its skeleton content stays as-is; this
  plan adds the *rule that keeps it updated*, not new content to the file
  itself.
- `template/init.config.sh`/`template/init.sh` — `REQUIRED_ENV_VARS` already
  exists there for a different purpose (which vars must be *set* for
  `init.sh` to pass); this plan is about which vars are *documented*, a
  separate concern. Do not merge the two mechanisms.
- The `odc` project used as evidence above — separate, unrelated repo, do
  **not** open, read, or modify it.

## Git workflow

- Branch: `main`.
- Commit message: `docs(template): require new env vars documented same-commit`

## Steps

### Step 1: Add the hard rule to `template/AGENTS.md` §4

Add a new bullet after the existing "Si no sabes cómo se hace algo..." line
(end of the list, línea 84):

```diff
 - **Si no sabes cómo se hace algo en este proyecto, busca en `docs/`** antes de inventarlo.
   Si no está en docs/, sigue el patrón del módulo más similar en el código existente.
+- **Toda variable de entorno nueva se documenta en el mismo cierre que la
+  introduce.** Añádela a `docs/conventions.md` (tabla "Variables de
+  entorno") y a `.env.example` si el proyecto usa uno — no la dejes para
+  "después"; después es cuando se te olvida.
```

**Verify**: `grep -n "variable de entorno" template/AGENTS.md` → at least 1 match

### Step 2: Add the checklist item to `template/.claude/agents/implementer.md`

Add a new item to "Checklist antes de declarar 'listo'" (after línea 57,
the last existing item):

```diff
 - [ ] El código respeta las capas de `docs/architecture.md` (domain sin
       imports de infrastructure, application depende solo de interfaces)
+- [ ] Si esta feature introduce una variable de entorno nueva, está en
+      `docs/conventions.md` y en `.env.example` (si el proyecto usa uno)
```

**Verify**: `grep -n "variable de entorno" template/.claude/agents/implementer.md` → 1 match

## Test plan

No test runner in this repo. The grep checks above are the verification —
there's no executable behavior to test, only doc/checklist text.

## Done criteria

- [ ] `grep -n "variable de entorno" template/AGENTS.md` → at least 1 match in §4
- [ ] `grep -n "variable de entorno" template/.claude/agents/implementer.md` → 1 match
- [ ] `git status --porcelain` shows changes only in the 2 in-scope files
- [ ] `plans/README.md` status row for 004 updated

## STOP conditions

- The line numbers/content in "Current state" don't match the live files —
  re-verify before editing.
- You're tempted to also edit `template/docs/conventions.md`'s skeleton
  content — out of scope; this plan changes the rule, not the doc's shipped
  starting content.
- You're tempted to merge this with `REQUIRED_ENV_VARS` in
  `init.config.sh`/`init.sh` — don't; "documented" and "required for
  `init.sh` to pass" are different concerns and conflating them would make
  a project fail its harness check over a missing table row, which is too
  strong a consequence for a docs-sync issue.

## Maintenance notes

- This is a process rule, not an automated check — unlike plan 003's
  `STATUS.md` drift check, there's no cheap mechanical way to verify "every
  `process.env.X` read in the codebase has a matching row in
  `docs/conventions.md`" without a stack-specific grep pattern this
  stack-agnostic template can't hardcode. If a future revision of this
  template wants to automate this, it would need to live in each project's
  own `init.config.sh`/`init.sh` customization, not here.
- Pairs naturally with plan 003 (`STATUS.md` drift) — both are cases where
  "update this doc when X happens" existed only as an unenforced convention
  and drifted in the real project this finding is based on.
