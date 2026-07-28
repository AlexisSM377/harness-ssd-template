# Plan 006: Tell skill installers to gitignore any local state/cache dir the skill creates

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 9056fc3..HEAD -- template/.claude/skills/README.md`
> If this file changed since this plan was written, compare the "Current
> state" excerpt against the live file before proceeding; on a mismatch,
> treat it as a STOP condition.

## Status

- **Priority**: P3
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: dx
- **Planned at**: commit `9056fc3`, 2026-07-28

## Why this matters

This finding comes from auditing a real project (`odc`, an unrelated repo)
built with this template, which had already adopted this template's own
`skills/` convention (from plan 001, this same repo). That project installed
a frontend-design skill called `impeccable`, which creates its own local
state directory at the project root (`.impeccable/` — config, critique logs,
a hooks cache). That directory was committed to git and never gitignored;
the project's own reviewer flagged this in a session log the day it
happened ("Considerar también añadir `.impeccable/` a `.gitignore`
(hallazgo no bloqueante del reviewer)"), and it was still unresolved as of
this audit — a day-old, self-identified, low-effort fix nobody circled back
to.

`template/.claude/skills/README.md` (written in plan 001, this repo) already
documents the naming convention for skills and how to add one — but says
nothing about what to do when a skill creates its own local state/cache
directory. This is a one-paragraph gap directly adjacent to content this
template already owns, and closing it means the next project that installs
a skill like `impeccable` sees the instruction *before* committing the
directory by accident, instead of relying on a reviewer to catch it after
the fact (which, per the evidence above, doesn't reliably happen either).

## Current state

`template/.claude/skills/README.md` (full file, 53 lines, written by plan
001 and merged at commit `9056fc3`) ends with:

```markdown
## Cómo añadir una skill nueva

1. Crea `.claude/skills/<track>-<nombre>/SKILL.md`.
2. Frontmatter mínimo:
   \`\`\`yaml
   ---
   name: <track>-<nombre>
   description: <una frase — qué hace y cuándo usarla; Claude Code la usa para decidir si aplica>
   ---
   \`\`\`
3. Verifica que quedó a un solo nivel: `find .claude/skills -mindepth 2 -name SKILL.md` debe salir vacío.
```

(Line 52 is the numbered item 3 above; línea 53 is the file's final
newline.) There is no section addressing skill-generated local
state/cache directories.

## Commands you will need

No build/test suite in this repo. Verification is a structural `grep`.

| Purpose | Command | Expected on success |
|---|---|---|
| Confirm the new section exists | `grep -n "estado o cache" template/.claude/skills/README.md` | at least 1 match |

## Scope

**In scope**:
- `template/.claude/skills/README.md` (append one new section)

**Out of scope** (do NOT touch):
- The naming-convention/tracks/how-to-add-a-skill content already in this
  file — this plan only appends, it doesn't edit existing sections.
- Root `template/.gitignore` — this template ships no root `.gitignore` of
  its own (each downstream project manages its own); this plan documents a
  per-skill instruction, it doesn't add speculative entries for skills this
  template doesn't know a given project will install.
- The `odc` project used as evidence above, including its own
  `.impeccable/` directory — separate, unrelated repo, do **not** open,
  read, or modify it, and do not fix its `.gitignore` as part of this plan.

## Git workflow

- Branch: `main`.
- Commit message: `docs(template): tell skill installers to gitignore local state dirs`

## Steps

### Step 1: Append the new section to `template/.claude/skills/README.md`

Add this section at the end of the file, after the existing "Cómo añadir
una skill nueva" section's item 3:

```markdown

## Si la skill genera estado o cache local

Algunas skills crean su propia carpeta de estado o cache en la raíz del
proyecto para guardar configuración, logs, o resultados intermedios (por
ejemplo, una skill de diseño de UI que guarda un historial de revisiones).
Esa carpeta es tooling local, no contenido del proyecto:

1. Al instalar una skill así, añade su carpeta a `.gitignore` **en el mismo
   commit** que instala la skill — no lo dejes para después.
2. Si ya se commiteó por accidente: `git rm -r --cached <carpeta>`, añádela
   a `.gitignore`, commitea ambos cambios juntos.
3. Si no estás seguro de si una skill genera este tipo de carpeta, revisa su
   `SKILL.md` o su documentación antes de la primera vez que la uses.
```

**Verify**: `grep -n "estado o cache" template/.claude/skills/README.md` → at least 1 match

## Test plan

No test runner in this repo. The grep check above is the verification —
this is a documentation-only addition.

## Done criteria

- [ ] `grep -n "estado o cache" template/.claude/skills/README.md` → at least 1 match
- [ ] The existing "Cómo añadir una skill nueva" section is unchanged (diff
      shows only an addition, no modified lines above it)
- [ ] `git status --porcelain` shows changes only in
      `template/.claude/skills/README.md`
- [ ] `plans/README.md` status row for 006 updated

## STOP conditions

- The file's content doesn't match the 53-line "Current state" excerpt —
  re-verify before editing (plan 001's content may have been revised since
  this plan was written).
- You're tempted to also fix `odc`'s actual `.impeccable/` `.gitignore`
  problem — don't; that's a separate, unrelated repo used only as evidence
  here, and this plan never touches it.

## Maintenance notes

- This is guidance, not an enforced check — there's no generic way for
  `init.sh` (stack-agnostic, doesn't know which skills a project installed)
  to detect "this directory belongs to a skill and should be gitignored."
  If a future version of this template wants to automate this, it would
  need each skill to self-declare its state directories in its own
  `SKILL.md`, which is a bigger change than this plan's scope.
- Pairs with plans 002-004 in spirit (all three are "a real project drifted
  because a convention was documented but not reinforced at the moment it
  mattered") but has no file/dependency overlap with them — safe to execute
  in any order relative to 002-005.
