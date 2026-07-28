# Plan 002: Add a checkpoint that catches dead code left by a superseded feature

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 9056fc3..HEAD -- template/CHECKPOINTS.md template/.claude/agents/reviewer.md template/.claude/agents/implementer.md`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: tech-debt
- **Planned at**: commit `9056fc3`, 2026-07-28

## Why this matters

This finding comes from auditing a real project (`odc`, an unrelated repo)
that was built with this template. Its `feature_list.json` shows feature
`role-based-executive-dashboard` (#19) replaced three earlier dashboard
components (`odc-dashboard.tsx`, `admin-dashboard.tsx`,
`general-dashboard.tsx` — ~330 lines plus their test files) with a single
`ExecutiveDashboard`. The old files were never deleted: confirmed via
`grep -rn` across the frontend that none of the three is imported by any
route, only by their own now-pointless test files. That feature went through
this template's full reviewer cycle (CHECKPOINTS C1–C6) and was approved —
more than once, since a later feature (`executive-dashboard-visual-refinement`,
#20) touched the same area again without anyone flagging the orphaned files.

The root cause is a gap in this template, not a one-off mistake in that
project: `template/CHECKPOINTS.md`'s six checkpoints (C1–C6) and
`template/.claude/agents/reviewer.md`'s checklist cover harness completeness,
state coherence, layering, TDD, traceability, and spec approval — none of
them ask "did this feature leave behind code from a feature it replaces?"
Any project using this template's SDD pipeline as designed can accumulate
the same kind of orphaned files indefinitely, because the checklist that's
supposed to be the objective definition of "done" has no line item for it.

This plan adds that checkpoint (C7) and wires it into the reviewer's process
and the implementer's own pre-completion checklist, so the check happens
before a feature is ever marked `done`, not after the fact.

## Current state

- `template/CHECKPOINTS.md` — six checkpoints, C1 through C6, each a list of
  checkboxes. The file ends (lines 63-67) with:

  ```
  ---

  **Cómo usar este archivo:**
  El agente `reviewer` recorre cada checkbox relevante a la feature trabajada,
  marca `[x]` o `[ ]`, y rechaza el cierre si queda alguno vacío en C1–C6.
  ```

  There is no C7. The closest existing checkpoint, C3 (líneas 28-36), is
  scoped to layering (domain/application/infrastructure), not to whether a
  feature's changes orphaned code elsewhere in the tree.

- `template/.claude/agents/reviewer.md` — section "5. Correr el checklist de
  CHECKPOINTS" (líneas 43-50) lists which checkpoints to run and when:

  ```
  - C1 (harness) — solo si es la primera feature del proyecto
  - C2 (estado) — siempre
  - C3 (arquitectura) — siempre
  - C4 (TDD: tests nombran R-ids) — siempre
  - C5 (trazabilidad sin filas pendientes) — siempre
  - C6 (spec aprobada) — siempre
  ```

  The report template (líneas 58-91) has one `## Checklist C<n>` block per
  checkpoint category, ending with `## Checklist C6` (líneas 81-82) followed
  directly by `## Observaciones`.

- `template/.claude/agents/implementer.md` — section "Errores comunes a
  evitar" (líneas 100-113) lists 5 things NOT to do, each starting with ❌,
  e.g. line 102: `❌ Implementar antes de que la spec esté aprobada.` This is
  where implementer-facing anti-patterns live; nothing there currently
  addresses leaving old code behind when a feature supersedes prior UI/logic.

## Commands you will need

This repo (`harness-sdd-template`) has no build/test suite — it's docs and
shell scripts. Verification is `grep`/`test -f` structural checks, same as
plan 001.

| Purpose | Command | Expected on success |
|---|---|---|
| Confirm C7 exists | `grep -n "^## C7" template/CHECKPOINTS.md` | 1 match |
| Confirm reviewer.md references C7 | `grep -n "C7" template/.claude/agents/reviewer.md` | at least 2 matches (the "cuándo correr" list + the report template block) |
| Confirm implementer.md has the new anti-pattern line | `grep -n "huérfan\|superseded\|reemplaz" template/.claude/agents/implementer.md` | at least 1 match |

## Scope

**In scope**:
- `template/CHECKPOINTS.md` (add C7)
- `template/.claude/agents/reviewer.md` (wire C7 into the "cuándo correr"
  list and the report template)
- `template/.claude/agents/implementer.md` (add one ❌ anti-pattern line to
  "Errores comunes a evitar")

**Out of scope** (do NOT touch):
- `template/.claude/agents/leader.md`, `spec_author.md`, `explorer.md` — not
  relevant to this checkpoint.
- Any file under `template/specs/`, `template/docs/` — this plan only
  changes the checkpoint definition and the two agents that consume it.
- The `odc` project mentioned above — it is a separate repo used only as
  evidence for this finding. **Do not open, read, or modify it.**

## Git workflow

- Branch: work directly on `main` (this repo's only branch so far).
- Commit message (Conventional Commits, English, scope `template`):
  `feat(template): add C7 checkpoint for dead code from superseded features`

## Steps

### Step 1: Add checkpoint C7 to `template/CHECKPOINTS.md`

Insert a new section after C6 (after line 62, before the closing `---` and
"Cómo usar este archivo" block):

```markdown
---

## C7 — Ninguna feature deja código huérfano de una que reemplaza

- [ ] Si esta feature reemplaza o vuelve obsoleto un componente/módulo de una
      feature anterior (UI, use-case, endpoint), ese código viejo fue
      eliminado en el mismo cierre — no se dejó "por si acaso"
- [ ] Los tests del código eliminado también se eliminaron (no quedan
      `.spec`/`.test` de un archivo que ya no existe)
- [ ] `grep`/búsqueda de importadores del módulo reemplazado no devuelve
      resultados fuera de su propio archivo de test (que también se elimina)
```

Then update the closing line (previously "C1–C6") to "C1–C7":

```diff
-marca `[x]` o `[ ]`, y rechaza el cierre si queda alguno vacío en C1–C6.
+marca `[x]` o `[ ]`, y rechaza el cierre si queda alguno vacío en C1–C7.
```

**Verify**: `grep -n "^## C7" template/CHECKPOINTS.md` → 1 match; `grep -n "C1–C7" template/CHECKPOINTS.md` → 1 match

### Step 2: Wire C7 into `template/.claude/agents/reviewer.md`

In section "5. Correr el checklist de CHECKPOINTS" (líneas 43-50), add a
line after the C6 entry:

```diff
 - C6 (spec aprobada) — siempre
+- C7 (sin código huérfano de una feature reemplazada) — siempre que la spec
+  o el reporte del implementer mencionen reemplazar/deprecar algo existente
```

In the report template (the markdown block starting línea 58), add a new
checklist block after `## Checklist C6` (línea 81-82) and before
`## Observaciones`:

```diff
 ## Checklist C6 — Spec aprobada
 - [x] / [ ] requirements.md con status: approved y casilla humana marcada

+## Checklist C7 — Sin código huérfano
+- [x] / [ ] Componentes/módulos reemplazados por esta feature fueron eliminados
+- [x] / [ ] Sus tests también fueron eliminados
+- [ ] N/A — esta feature no reemplaza nada existente
+
 ## Observaciones
```

**Verify**: `grep -n "C7" template/.claude/agents/reviewer.md` → at least 2 matches

### Step 3: Add the anti-pattern line to `template/.claude/agents/implementer.md`

In "Errores comunes a evitar" (líneas 100-113), add one line after the
existing 5:

```diff
 ❌ Entidades de domain que importan tipos o decoradores de la capa de
    infraestructura (ORM, framework HTTP).
+
+❌ Dejar componentes, use-cases o endpoints huérfanos cuando esta feature
+   reemplaza a los de una feature anterior — bórralos en el mismo cierre,
+   junto con sus tests. "Podría servir después" no es razón para no
+   borrarlos: `git log` los recupera si hace falta.
```

**Verify**: `grep -n "huérfan" template/.claude/agents/implementer.md` → 1 match

## Test plan

No test runner in this repo. Verification is the grep/structural checks in
each step above, plus a manual read confirming the new C7 section reads
consistently with C1–C6's existing tone and checkbox format.

## Done criteria

- [ ] `grep -n "^## C7" template/CHECKPOINTS.md` → 1 match
- [ ] `grep -n "C1–C7" template/CHECKPOINTS.md` → 1 match
- [ ] `grep -n "C7" template/.claude/agents/reviewer.md` → at least 2 matches
- [ ] `grep -n "huérfan" template/.claude/agents/implementer.md` → 1 match
- [ ] `git status --porcelain` shows changes only in the 3 in-scope files
- [ ] `plans/README.md` status row for 002 updated

## STOP conditions

- The line numbers in "Current state" don't match the live files (drift
  since this plan was written) — re-read before editing.
- You find yourself wanting to also rewrite C1–C6 "while you're in there" —
  out of scope; this plan only adds C7.
- You find yourself wanting to open, read, or modify the `odc` project used
  as evidence in "Why this matters" — it is a separate, unrelated repo; this
  plan never touches it.

## Maintenance notes

- If a future project using this template reports a C7 false-positive (a
  reviewer flags legitimately-kept old code, e.g. a deprecated-but-still-used
  API version), that's a signal C7's wording needs a "documented exception"
  clause — not a reason to drop the checkpoint.
- This checkpoint only fires when a feature's spec or implementer report
  says it replaces/deprecates something. It won't catch dead code from
  causes other than feature-supersession (e.g. an abandoned experiment) —
  that's a different, broader "dead code" audit, out of scope here.
