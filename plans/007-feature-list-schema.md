# Plan 007: Document feature_list.json's schema with a worked example

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat ca58fc0..HEAD -- template/docs/specs.md template/AGENTS.md`
> If either file changed since this plan was written, compare the "Current
> state" excerpts below against the live file before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: tech-debt
- **Planned at**: commit `ca58fc0`, 2026-07-28

## Why this matters

`template/feature_list.json` ships as a literal `[]` — intentionally empty, since
every downstream project starts fresh. But the exact JSON shape of an entry
(which fields exist, which are required, what values `status` may take) is
never written down in one place. It's scattered as passing references across
`template/AGENTS.md`, `template/CLAUDE.md`, `template/docs/specs.md`,
`template/.claude/agents/spec_author.md`, `template/.claude/agents/leader.md`,
and `template/init.sh` (which reads `.status`, `.name`, `.id`, `.priority` via
`node -e` with no schema validation). A human or agent filling in
`feature_list.json` for a new project has to reverse-engineer the shape by
grepping all of those files, and a typo'd field name (e.g. `filesAffected`
instead of `files_affected`) fails silently — `spec_author` just won't see the
optional context, and `init.sh`'s `next.priority` print falls back to
`undefined` with no error. Documenting the schema once, in the doc that
already owns the SDD process (`docs/specs.md`), removes that ambiguity for
every project built from this template.

## Current state

- `template/feature_list.json:1` — the entire file, verbatim: `[]`
- `template/docs/specs.md` — owns the SDD process description (states,
  gates, EARS notation). This is the natural home for the schema: it already
  has a "## Quién escribe qué" section and a "## Estados de una feature"
  section describing `pending → spec_ready → in_progress → done`. Add the new
  schema section right after "## Estados de una feature" (currently ends
  around line 37, right before "## Cómo se crea la spec de una feature
  nueva").
- `template/.claude/agents/spec_author.md:17-18` — the only place that names
  the optional fields:
  ```
  1. Lee la entrada de la feature en `feature_list.json` (description,
     acceptance_criteria, files_affected si ya están listados).
  ```
- `template/init.sh:207-230` — the only code that actually reads fields at
  runtime, confirming what's load-bearing: `.status` (filtered against
  `"pending"`, `"in_progress"`, `"done"`), `.name`, `.id`, `.priority` (the
  last two only used for the closing "Próxima feature" printout, not
  validated).
- `template/AGENTS.md:37` — the map-table row for `feature_list.json`:
  ```
  | `feature_list.json` | Lista de features con estado (pending / spec_ready / in_progress / done) | Siempre, al empezar |
  ```
  This row's middle column is where the pointer to the new schema section
  goes.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Confirm section added | `grep -n "^## Schema de" template/docs/specs.md` | one match |
| Confirm AGENTS.md points at it | `grep -n "Schema" template/AGENTS.md` | one match |
| Confirm feature_list.json untouched | `git diff --stat -- template/feature_list.json` | empty output (no changes) |

## Scope

**In scope** (the only files you should modify):
- `template/docs/specs.md` (add a new section)
- `template/AGENTS.md` (update one table cell to point at the new section)

**Out of scope** (do NOT touch, even though they look related):
- `template/feature_list.json` — stays `[]`. Do not add example entries to
  the actual file; it ships to every downstream project verbatim via
  `apply-template.sh`, and a fake entry would show up as a real feature in
  someone's fresh project.
- `template/init.sh` — no schema validation is being added to the script in
  this plan (that would be a separate, larger change with its own risk
  profile). This plan is documentation-only.
- `template/.claude/agents/spec_author.md` — its existing field list
  (line 17-18) is accurate and doesn't need to change; it references the new
  schema section only if you find a natural one-line spot to do so, but this
  is optional polish, not required for done criteria.

## Git workflow

- Branch: `advisor/007-feature-list-schema`
- Commit message style: conventional commits, English (matches repo history,
  e.g. `docs(template): document feature_list.json entry schema`)
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Add the schema section to `docs/specs.md`

Insert a new section immediately after "## Estados de una feature" and before
"## Cómo se crea la spec de una feature nueva". Use this content (adapt
formatting to match the file's existing heading style — `##` for top-level
sections, matching what's already there):

```markdown
## Schema de una entrada en feature_list.json

Cada elemento del array es un objeto con estos campos:

| Campo | Tipo | Obligatorio | Significado |
|---|---|---|---|
| `id` | number | sí | Identificador único, estable, no se reutiliza |
| `name` | string | sí | Slug usado como nombre de carpeta en `specs/<name>/` |
| `status` | string | sí | Uno de: `pending`, `spec_ready`, `in_progress`, `done` |
| `priority` | string | no | Valor libre (ej: `P1`/`P2`/`P3` o `alta`/`media`/`baja`) — elegir una convención por proyecto y mantenerla |
| `description` | string | no | Resumen de qué hace la feature; usado por `spec_author` como contexto inicial |
| `acceptance_criteria` | string[] | no | Lista de criterios en lenguaje natural; `spec_author` los traduce a requisitos EARS |
| `files_affected` | string[] | no | Rutas o módulos que probablemente toque la feature; pista para `explorer`/`spec_author`, no una restricción dura |

Ejemplo:

```json
{
  "id": 1,
  "name": "user-auth",
  "status": "pending",
  "priority": "P1",
  "description": "Permitir login con email y password",
  "acceptance_criteria": [
    "Usuario puede loguearse con credenciales válidas",
    "Sistema rechaza credenciales inválidas con 401"
  ],
  "files_affected": [
    "src/modules/auth/"
  ]
}
```

Solo `id`, `name` y `status` son leídos por `init.sh`. El resto es contexto
opcional para `spec_author` — vale la pena rellenarlo cuando ya se sabe, pero
no bloquea nada si falta.
```

**Verify**: `grep -n "^## Schema de una entrada" template/docs/specs.md` →
one match.

### Step 2: Point `AGENTS.md`'s map table at the new section

In `template/AGENTS.md`, update the `feature_list.json` row (currently line
37) to reference the schema section. Change:

```
| `feature_list.json` | Lista de features con estado (pending / spec_ready / in_progress / done) | Siempre, al empezar |
```

to:

```
| `feature_list.json` | Lista de features con estado (pending / spec_ready / in_progress / done) — schema de cada entrada en `docs/specs.md` §Schema | Siempre, al empezar |
```

**Verify**: `grep -n "Schema" template/AGENTS.md` → one match, on the
`feature_list.json` row.

## Test plan

No automated tests apply — this is a documentation-only change to a template
repo with no test runner. Verification is the grep commands above plus a
manual read-through confirming the new section renders as valid Markdown
(table syntax, JSON fence) and doesn't break any existing heading anchors
that other files might link to (check with the command below).

- `grep -rn "specs.md#" template/` → confirm no existing anchor-based link
  targets a heading you moved or renamed. (There should be none — this plan
  only adds a new section, doesn't rename existing ones.)

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `grep -n "^## Schema de una entrada" template/docs/specs.md` → one match
- [ ] `grep -n "Schema" template/AGENTS.md` → one match
- [ ] `git diff --stat -- template/feature_list.json` → empty (file untouched)
- [ ] `git status --short` shows changes only in `template/docs/specs.md` and
      `template/AGENTS.md`
- [ ] `plans/README.md` status row for 007 updated

## STOP conditions

Stop and report back (do not improvise) if:

- `template/docs/specs.md` no longer has a "## Estados de una feature"
  section at the location described (the file has drifted structurally since
  this plan was written).
- You find yourself wanting to add fields to `template/feature_list.json`
  itself — that's explicitly out of scope; report the temptation instead.
- The AGENTS.md table row has already been restructured by another plan
  (check `plans/README.md` for conflicts before editing).

## Maintenance notes

- If a future plan adds automated schema validation to `init.sh` (e.g. a
  small `node -e` check that every entry has `id`/`name`/`status`), that
  validation should reference this same field list so the two stay in sync —
  point back at `docs/specs.md` §Schema rather than redefining the fields.
- No follow-up is deferred by this plan; it's documentation-only and
  complete in scope.
