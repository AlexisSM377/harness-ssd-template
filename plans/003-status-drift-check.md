# Plan 003: Catch STATUS.md drift automatically, and make updating it an explicit close-out step

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 9056fc3..HEAD -- template/init.sh template/AGENTS.md template/STATUS.md`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: dx
- **Planned at**: commit `9056fc3`, 2026-07-28

## Why this matters

This finding comes from auditing a real project (`odc`, an unrelated repo)
that was built with this template. Its `STATUS.md` said "Features
completadas: 14/14... Pendientes: ninguna" while `feature_list.json` actually
had 20 features, all `done` — six shipped features and roughly eight ad-hoc
UI sessions had passed since anyone touched `STATUS.md`. Its `PRODUCT.md`
was worse: it named a "next capability" that had actually shipped the day
*before* `PRODUCT.md` was committed.

Reading this template's own files explains why: **`template/AGENTS.md`'s
session close-out checklist (§7 "Cierre de sesión") never mentions
`STATUS.md` at all.** It tells the agent to run `init.sh`, mark the feature
`done` in `feature_list.json`, move the summary from `progress/current.md`
to `progress/history.md`, and clean up temp files/TODOs — but nowhere does
it say to update `STATUS.md`. Any project scaffolded from this template
today has zero built-in instruction to keep `STATUS.md` in sync; whatever
discipline keeps it current has to come from outside the template (a
personal habit, a global tool preference) rather than the harness itself.

This plan does two things: makes updating `STATUS.md` an explicit step in
`AGENTS.md`'s close-out checklist, and adds a cheap, mechanical drift check
to `init.sh` so a stale `STATUS.md` is visible on *every single run* of
`init.sh` — not just something you're supposed to remember at the end of a
session under time pressure, which is exactly the condition that failed in
the real project this finding is based on.

## Current state

- `template/AGENTS.md` — section "## 7. Cierre de sesión (lifecycle)"
  (líneas 112-123):

  ```
  Antes de terminar:

  1. Ejecuta `./init.sh` — todo debe terminar verde.
  2. Si la tarea está acabada: marca `status: "done"` en `feature_list.json` y
     confirma que `specs/<feature>/traceability.md` no tiene filas "pendiente".
  3. Mueve el resumen de `progress/current.md` al final de `progress/history.md`.
  4. Vacía `progress/current.md` dejando solo la plantilla base.
  5. No dejes archivos temporales, ni `console.log` de debug, ni TODOs sin contexto.
  ```

  No step mentions `STATUS.md`.

- `template/STATUS.md` (the skeleton shipped to every new project) opens
  with a header block whose second line is always in this exact shape
  (líneas 1-6):

  ```
  # {{PROJECT_NAME}} — Status

  **Última actualización**: —
  **Features completadas**: 0/0 (`feature_list.json`)
  **Pendientes**: —
  **En producción**: no
  ```

  The `X/Y` in "Features completadas" is meant to track
  `feature_list.json`'s done-count/total-count — exactly the pair that
  drifted in the real project this finding is based on.

- `template/init.sh` — section "## 4. HARNESS — coherencia del arnés"
  already requires `STATUS.md` to exist (línea 85:
  `[ -f STATUS.md ] || fail "STATUS.md no encontrado"`), and already reads
  `feature_list.json` via inline `node -e` blocks multiple times in this
  section (líneas 100-138) for the "features in_progress" and "spec exists"
  checks. The section ends at línea 138, immediately followed by:

  ```
  # ── 5. BUILD ─────────────────────────────────
  ```

  (línea 140-142). There is currently no check comparing `STATUS.md`'s
  declared `X/Y` against the real count in `feature_list.json`.

## Commands you will need

No build/test suite in this repo. Verification is running the modified
`init.sh` logic directly and structural `grep` checks.

| Purpose | Command | Expected on success |
|---|---|---|
| Confirm AGENTS.md mentions STATUS.md in §7 | `grep -n "STATUS.md" template/AGENTS.md` | at least 1 match inside the "Cierre de sesión" section |
| Confirm init.sh has the new check | `grep -n "Features completadas" template/init.sh` | 1 match |
| Dry-run the check logic in isolation | see Step 2's verify command | prints `OK` when run against `template/STATUS.md` + a matching stub `feature_list.json` |

## Scope

**In scope**:
- `template/AGENTS.md` (§7 "Cierre de sesión" — add one step)
- `template/init.sh` (add one check in section 4)

**Out of scope** (do NOT touch):
- `template/STATUS.md`'s skeleton content/wording — only its *consumption*
  by `init.sh` changes, not its shape.
- `template/.claude/agents/*` — this plan changes the harness's own
  lifecycle doc and health-check script, not agent role definitions.
- The `odc` project used as evidence above — separate, unrelated repo, do
  **not** open, read, or modify it.

## Git workflow

- Branch: `main`.
- Commit message: `feat(template): warn on STATUS.md drift, require it at session close`

## Steps

### Step 1: Add the STATUS.md step to `template/AGENTS.md` §7

Insert a new step 3, renumbering the current 3-5 to 4-6:

```diff
 1. Ejecuta `./init.sh` — todo debe terminar verde.
 2. Si la tarea está acabada: marca `status: "done"` en `feature_list.json` y
    confirma que `specs/<feature>/traceability.md` no tiene filas "pendiente".
-3. Mueve el resumen de `progress/current.md` al final de `progress/history.md`.
-4. Vacía `progress/current.md` dejando solo la plantilla base.
-5. No dejes archivos temporales, ni `console.log` de debug, ni TODOs sin contexto.
+3. Actualiza `STATUS.md`: la línea "Features completadas: X/Y" contra el
+   conteo real de `feature_list.json`, la sección "Estado actual", y añade
+   una entrada en "Última sesión" con fecha, qué se hizo y qué sigue. Esto
+   no es opcional ni se pospone — `init.sh` lo verifica en el siguiente paso.
+4. Mueve el resumen de `progress/current.md` al final de `progress/history.md`.
+5. Vacía `progress/current.md` dejando solo la plantilla base.
+6. No dejes archivos temporales, ni `console.log` de debug, ni TODOs sin contexto.
```

**Verify**: `grep -n "STATUS.md" template/AGENTS.md` → at least 1 match in this section (there may be other unrelated matches elsewhere in the file — that's fine)

### Step 2: Add the drift check to `template/init.sh`

Insert this block right after the existing "spec exists for in_progress/done
features" loop (after línea 138, immediately before the blank line and the
`# ── 5. BUILD` comment):

```bash
# Verificar que STATUS.md refleja el conteo real de feature_list.json
STATUS_SYNC=$(node -e "
  const fs = require('fs');
  const f = require('./feature_list.json');
  const done = f.filter(x => x.status === 'done').length;
  const total = f.length;
  const status = fs.readFileSync('STATUS.md', 'utf8');
  const m = status.match(/Features completadas\*\*:\s*(\d+)\/(\d+)/);
  if (!m) {
    console.log('NO_MATCH');
  } else if (Number(m[1]) !== done || Number(m[2]) !== total) {
    console.log('MISMATCH:' + m[1] + '/' + m[2] + ' declarado vs ' + done + '/' + total + ' real');
  } else {
    console.log('OK');
  }
")

if [ "$STATUS_SYNC" = "OK" ]; then
  ok "STATUS.md sincronizado con feature_list.json"
elif [ "$STATUS_SYNC" = "NO_MATCH" ]; then
  warn "STATUS.md no tiene la línea 'Features completadas: X/Y' en el formato esperado"
else
  warn "STATUS.md desactualizado (${STATUS_SYNC#MISMATCH:}) — actualízalo antes de cerrar la sesión"
fi
```

This must be a `warn()`, never a `fail()` — a stale `STATUS.md` is a
documentation-hygiene problem, not a broken harness; `init.sh`'s existing
convention (e.g. the "features en progreso" check, líneas 110-121) already
uses `warn()` for informational-but-not-blocking conditions, and this
follows the same pattern.

**Verify**: `grep -n "Features completadas" template/init.sh` → 1 match.
Then dry-run the embedded node snippet directly against the template's own
skeleton files to confirm it doesn't crash:
```bash
cd template && node -e "
  const fs = require('fs');
  const f = require('./feature_list.json');
  const done = f.filter(x => x.status === 'done').length;
  const total = f.length;
  const status = fs.readFileSync('STATUS.md', 'utf8');
  const m = status.match(/Features completadas\*\*:\s*(\d+)\/(\d+)/);
  if (!m) { console.log('NO_MATCH'); }
  else if (Number(m[1]) !== done || Number(m[2]) !== total) { console.log('MISMATCH'); }
  else { console.log('OK'); }
"
```
Expected: `OK` (the shipped skeleton is `0/0` declared against an empty
`feature_list.json` array, which is `0/0` real — they match).

## Test plan

No test runner in this repo. The dry-run in Step 2's verify command is the
test: it must print `OK` against the unmodified template skeleton (0/0 vs
0/0), proving the check doesn't false-positive on a fresh project before it
has any features.

## Done criteria

- [ ] `grep -n "STATUS.md" template/AGENTS.md` finds it inside §7's numbered list
- [ ] `grep -n "Features completadas" template/init.sh` → 1 match
- [ ] The dry-run node snippet against `template/feature_list.json` +
      `template/STATUS.md` prints `OK`
- [ ] `git status --porcelain` shows changes only in `template/AGENTS.md` and `template/init.sh`
- [ ] `plans/README.md` status row for 003 updated

## STOP conditions

- The line numbers/content in "Current state" don't match the live files —
  re-verify before editing.
- You find `template/feature_list.json` (the shipped skeleton) is not `[]` —
  that would mean the template itself changed in a way this plan didn't
  anticipate; stop and check before assuming `0/0` is still the right
  dry-run expectation.
- You're tempted to make this a `fail()` instead of a `warn()` — don't; a
  brand-new project or one mid-feature legitimately has a temporarily-stale
  `STATUS.md` for the duration of a single session, and hard-failing
  `init.sh` over documentation lag would block real work. Stop and ask if
  you think `fail()` is actually right here.

## Maintenance notes

- This check only compares the `X/Y` *count* — it can't detect that
  `STATUS.md`'s prose ("Estado actual", "Última sesión") is stale while the
  count happens to still match (e.g. right after a feature closes but before
  its narrative is written). That's a real but harder-to-automate gap;
  regex-matching prose staleness isn't attempted here.
- If a project's `STATUS.md` format ever changes (e.g. the "Features
  completadas" line is reworded), this regex breaks silently into the
  `NO_MATCH` warn path — that's the safe failure mode (a warning, not a
  crash), but worth knowing if this check ever seems to stop firing.
