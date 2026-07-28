# Plan 001: Add a flat, prefix-named `skills/` convention to the template

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 293655e..HEAD -- template/.claude template/AGENTS.md README.md`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts below against the live code before proceeding; on
> a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: dx
- **Planned at**: commit `293655e`, 2026-07-28

## Why this matters

The user is building `harness-sdd-template` to be applied across several
downstream projects. They observed that skills they install don't get
auto-detected by Claude Code when working across multiple projects, and want
to give the template an organized `skills/` layout (inspired by a screenshot
of an unrelated "loopkit" vault that groups skills into category subfolders,
e.g. `skills/security/`, `skills/frontend/`, each holding several skill
folders — "33 skills · 9 tracks").

Root cause, confirmed against Claude Code's own GitHub issue tracker
(anthropics/claude-code #28266, #40640): **Claude Code scans `.claude/skills/`
only one level deep.** A skill is discovered at
`.claude/skills/<skill-name>/SKILL.md`. Nesting one level further —
`.claude/skills/<category>/<skill-name>/SKILL.md`, exactly what the
screenshot shows — is invisible to the auto-loader. This is filed as an open
feature request, not yet shipped, and applies identically to project-level
(`.claude/skills/`), personal (`~/.claude/skills/`), and plugin-provided
skills. There is no supported "categorized folder" mechanism today; the
workaround people use is a **flat directory one level deep, with the category
encoded as a name prefix** (e.g. `security-audit`, `frontend-a11y-check`).

Today `template/.claude/` has no `skills/` directory at all — only
`template/.claude/agents/` with 5 fixed role subagents (`leader`,
`spec_author`, `explorer`, `implementer`, `reviewer`) and an intentionally
empty `template/.claude/settings.json` (`{}`). This plan adds the convention,
one working exemplar skill, and wires it into the two docs that already map
the repo (`README.md`, `template/AGENTS.md`) — without inventing a nested
taxonomy that would silently fail to load in every project this template is
applied to.

## Current state

- `template/.claude/agents/` — 5 files (`leader.md`, `spec_author.md`,
  `explorer.md`, `implementer.md`, `reviewer.md`). No `skills/` sibling
  exists yet.
- `template/.claude/settings.json` — literally `{}` (1 line), shipped empty
  on purpose (see `README.md:94-117`, section "Hooks opcionales").
- `README.md:18-30` — the "8 componentes" table. Row 5 currently reads:

  ```
  | 5 | Jerarquía de agentes/skills | `template/.claude/agents/` (leader, spec_author, explorer, implementer, reviewer) |
  ```

  It mentions "skills" in the label but only points at `agents/` — there is
  no skills location to point to yet.
- `template/AGENTS.md:33-49` — section "2. Mapa del repositorio", a table of
  `Archivo / carpeta | Qué contiene | Cuándo leerlo`. Row for
  `.claude/agents/` exists (line 47); no row for skills.
- `apply-template.sh:34-45` copies **every file** under `template/` via
  `find "$TEMPLATE_DIR" -type f -print0`, preserving directory structure,
  skipping files that already exist at the destination. This already works
  for any depth — the bug this plan fixes is Claude Code's own runtime
  discovery inside a project, not the copy step, so `apply-template.sh`
  itself needs no changes.
- Repo commit style (`docs/conventions.md:65-77`, and real history via
  `git log --oneline`): Conventional Commits in English, e.g.
  `fix(template): ship empty stack commands in init.config.sh`.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Confirm no skills/ dir pre-exists | `test -d template/.claude/skills && echo EXISTS \|\| echo ABSENT` | prints `ABSENT` before Step 1 |
| Validate SKILL.md frontmatter is well-formed YAML | `node -e "const fs=require('fs'); const m=fs.readFileSync('template/.claude/skills/docs-readme-sync/SKILL.md','utf8').match(/^---\n([\s\S]*?)\n---/); if(!m) throw new Error('no frontmatter'); console.log('frontmatter block found, ' + m[1].split(String.fromCharCode(10)).length + ' lines')"` | prints a line count, no error |
| Confirm no nested skill folders were introduced | `find template/.claude/skills -mindepth 2 -name SKILL.md` | empty output (every `SKILL.md` is exactly one level under `skills/`) |
| Repo-wide sanity (this repo has no build/test/lint configured) | `test -f template/init.config.sh && grep -q 'INSTALL_CMD=""' template/init.config.sh` | exit 0 — confirms you're not expected to run a build for this repo itself |

This repo (`harness-sdd-template`) has no package manager, build, or test
suite of its own — it is documentation and shell scripts. Verification here
is file-existence and structural checks, not a test runner.

## Scope

**In scope** (the only files you should create or modify):
- `template/.claude/skills/README.md` (create)
- `template/.claude/skills/docs-readme-sync/SKILL.md` (create — the one
  exemplar skill)
- `README.md` (edit — component table row 5, plus one new section)
- `template/AGENTS.md` (edit — map table, one new row)

**Out of scope** (do NOT touch, even though they look related):
- `template/.claude/agents/*` — the 5 fixed role subagents are a separate,
  already-working mechanism (Task-tool subagents, not Skills). Do not merge
  or rename anything between `agents/` and `skills/`.
- `template/.claude/settings.json` — stays `{}`. This plan does not add
  hooks, and the empty settings file is an intentional, documented default
  (`README.md:94-117`). Do not add a `hooks/` directory.
- `apply-template.sh` — already copies arbitrary nested paths correctly; no
  change needed (see "Current state" above for why).
- `template/init.sh` — do NOT add a required-file check for `skills/` in the
  "coherencia del arnés" section (`template/init.sh:82-96`). Skills are
  optional per downstream project; making the directory mandatory would
  break `init.sh` for every project that adds zero skills.
- Do not create more than the one exemplar skill. This is a template meant
  to be adapted per project — shipping a large fixed catalog (the
  screenshot's "33 skills") would be content specific to someone else's
  project, not generic scaffolding.
- Do not attempt to build a custom recursive skill loader, symlink farm, or
  plugin to work around the one-level limitation. That is a real Claude Code
  product gap (tracked upstream in anthropics/claude-code #28266, #40640),
  not something this template should paper over with a bespoke mechanism.

## Git workflow

- Branch: work directly on `main` unless the operator says otherwise (this
  repo has only 2 commits, both on `main`, no branching convention observed
  yet).
- Commit message style — Conventional Commits, English, scope `template`
  (matches `293655e fix(template): ship empty stack commands in init.config.sh`):
  `feat(template): add flat prefix-named skills/ convention`
- Do NOT push unless the operator instructed it.

## Steps

### Step 1: Create the skills convention doc

Create `template/.claude/skills/README.md` with this content:

```markdown
# Skills — convención de nombres

> Claude Code descubre skills en `.claude/skills/<nombre>/SKILL.md`,
> **un solo nivel de profundidad**. Carpetas anidadas por categoría
> (`.claude/skills/<categoria>/<nombre>/SKILL.md`) NO se auto-detectan —
> es una limitación conocida y todavía abierta del propio Claude Code
> (anthropics/claude-code#28266, #40640), no un bug de esta plantilla.

## Convención: nombre plano con prefijo de track

En vez de anidar en subcarpetas, cada skill vive directo bajo `skills/` y
codifica su categoría ("track") como prefijo del nombre de carpeta:

```
.claude/skills/
  docs-readme-sync/SKILL.md
  security-audit/SKILL.md
  security-threat-model/SKILL.md
  frontend-a11y-check/SKILL.md
  git-ops-commit-msg/SKILL.md
```

Patrón: `<track>-<skill-name>/SKILL.md`.

## Tracks sugeridos

Punto de partida, no obligatorio — edítalo según las skills reales del
proyecto:

| Track | Prefijo | Para qué |
|---|---|---|
| agent-llm | `agent-llm-` | patrones de prompting/uso de Claude propios del proyecto |
| debug | `debug-` | triage y reproducción de bugs |
| security | `security-` | auditoría y modelado de amenazas |
| frontend | `frontend-` | React/UI y accesibilidad |
| testing | `testing-` | convenciones de test del stack elegido |
| refactor | `refactor-` | reescrituras seguras |
| docs | `docs-` | READMEs, changelogs, sincronía de docs |
| data | `data-` | consultas y transformaciones de datos |
| git-ops | `git-ops-` | mensajes de commit, PRs, rebases |

## Cómo añadir una skill nueva

1. Crea `.claude/skills/<track>-<nombre>/SKILL.md`.
2. Frontmatter mínimo:
   ```yaml
   ---
   name: <track>-<nombre>
   description: <una frase — qué hace y cuándo usarla; Claude Code la usa para decidir si aplica>
   ---
   ```
3. Verifica que quedó a un solo nivel: `find .claude/skills -mindepth 2 -name SKILL.md` debe salir vacío.
```

**Verify**: `test -f template/.claude/skills/README.md && echo OK` → prints `OK`

### Step 2: Add one exemplar skill

Create `template/.claude/skills/docs-readme-sync/SKILL.md`:

```markdown
---
name: docs-readme-sync
description: Keep README.md's "componentes" table and AGENTS.md's map table in sync when files move or new top-level pieces are added to the harness. Use when a file referenced by either table is renamed, moved, or removed.
---

# docs-readme-sync

Cuando un archivo o carpeta referenciado en la tabla "Los 8 componentes" de
`README.md` o en la tabla "Mapa del repositorio" de `AGENTS.md` cambia de
ruta, se renombra o se elimina:

1. Busca todas las referencias a la ruta vieja: `grep -rn "<ruta-vieja>" README.md AGENTS.md`
2. Actualiza cada fila afectada con la ruta nueva.
3. Si el cambio agrega un componente nuevo (no solo mueve uno existente),
   añade una fila nueva en vez de sobrescribir una existente.
4. No toques el resto de la tabla ni reordenes filas no afectadas.
```

**Verify**: `node -e "const fs=require('fs'); const m=fs.readFileSync('template/.claude/skills/docs-readme-sync/SKILL.md','utf8').match(/^---\n([\s\S]*?)\n---/); if(!m) throw new Error('no frontmatter'); console.log('OK')"` → prints `OK`

### Step 3: Wire into `README.md`

In the "Los 8 componentes" table (`README.md:20-30`), replace row 5:

```diff
-| 5 | Jerarquía de agentes/skills | `template/.claude/agents/` (leader, spec_author, explorer, implementer, reviewer) |
+| 5 | Jerarquía de agentes/skills | `template/.claude/agents/` (5 roles fijos) + `template/.claude/skills/` (convención plana, ver su README) |
```

Then, after the existing "## Hooks opcionales" section
(`README.md:94-117`, ends right before "## Filosofía"), insert a new section
**before** "## Filosofía":

```markdown
---

## Skills opcionales

`template/.claude/skills/` se instala con la convención documentada en
`template/.claude/skills/README.md` y un único ejemplo
(`docs-readme-sync`). Claude Code sólo autodetecta skills a un nivel de
profundidad bajo `skills/` — por eso la convención es plana con prefijo de
track (`<track>-<nombre>/SKILL.md`), no carpetas anidadas por categoría.
Añade las skills reales del proyecto siguiendo ese patrón.
```

**Verify**: `grep -n "Skills opcionales" README.md` → one match; `grep -n "template/.claude/skills" README.md` → at least 2 matches (table row + new section)

### Step 4: Wire into `template/AGENTS.md`

In the "Mapa del repositorio" table (`template/AGENTS.md:35-49`), add a row
directly after the existing `.claude/agents/` row (line 47):

```diff
 | `.claude/agents/` | Definiciones de subagentes (leader, spec_author, explorer, implementer, reviewer) | Si orquestas trabajo |
+| `.claude/skills/` | Skills reutilizables, un nivel plano (`<track>-<nombre>/SKILL.md`) — ver `.claude/skills/README.md` | Antes de repetir una tarea ya resuelta en otro proyecto |
```

**Verify**: `grep -n "claude/skills" template/AGENTS.md` → one match

## Test plan

This repo has no test runner (it's docs + shell scripts). Validation is
structural, already covered by the "Commands you will need" table and each
step's own `Verify` line:

- Frontmatter parses as YAML-delimited block (Step 2's verify command).
- No nested `SKILL.md` beyond one level (`find template/.claude/skills
  -mindepth 2 -name SKILL.md` → empty).
- Both docs (`README.md`, `template/AGENTS.md`) reference the new path.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `test -f template/.claude/skills/README.md` → exit 0
- [ ] `test -f template/.claude/skills/docs-readme-sync/SKILL.md` → exit 0
- [ ] `find template/.claude/skills -mindepth 2 -name SKILL.md` → empty output
- [ ] `grep -n "Skills opcionales" README.md` → 1 match
- [ ] `grep -n "claude/skills" template/AGENTS.md` → 1 match
- [ ] `git status --porcelain` shows changes only in: `template/.claude/skills/README.md`, `template/.claude/skills/docs-readme-sync/SKILL.md`, `README.md`, `template/AGENTS.md`
- [ ] `plans/README.md` status row for 001 updated

## STOP conditions

Stop and report back (do not improvise) if:

- `template/.claude/skills/` already exists with different content than
  described in "Current state" (the codebase has drifted since this plan
  was written — re-read it before touching anything).
- You find yourself wanting to add more than one exemplar skill "while
  you're in there" — that's scope creep for a template repo; stop and ask.
- You find yourself wanting to add a `hooks/` directory or populate
  `template/.claude/settings.json` — out of scope for this plan (see
  "Scope" above); a separate plan would cover that if requested.
- The row 5 text in `README.md`'s component table, or the `.claude/agents/`
  row in `template/AGENTS.md`'s map table, doesn't match the excerpts in
  "Current state" (table structure has changed — re-verify line numbers).

## Maintenance notes

- If Claude Code ever ships recursive `.claude/skills/` discovery (tracked
  upstream in anthropics/claude-code #28266 / #40640), this convention can
  be relaxed to real nested folders. Until then, do not "fix" the flat
  naming — it's a deliberate workaround for a real, currently-open product
  limitation, not an aesthetic choice.
- Anyone applying this template to a new project and adding skills should
  read `template/.claude/skills/README.md` first — it's the source of truth
  for the naming pattern, not this plan file (which won't travel with the
  applied template).
- A reviewer should scrutinize: no nested `SKILL.md` was introduced, and
  the two doc edits are additive (no unrelated rows reworded or reordered).
