# Plan 009: Ship a seeded .gitignore instead of only instructing users to create one

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat ca58fc0..HEAD -- README.md apply-template.sh template/docs/obsidian.md`
> If any of these files changed since this plan was written, compare the
> "Current state" excerpts below against the live files before proceeding;
> on a mismatch, treat it as a STOP condition.
>
> **Sequencing note**: Plan 008 also touches `apply-template.sh`, but a
> different section (the `sed -i` substitution loop vs. this plan's printed
> next-steps message). If 008 has already landed, re-read
> `apply-template.sh` before editing — line numbers below will have shifted.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (safe to run before or after 008; see sequencing note)
- **Category**: tech-debt
- **Planned at**: commit `ca58fc0`, 2026-07-28

## Why this matters

Three separate places in this template tell a downstream project to maintain
a `.gitignore`: `README.md`'s post-install steps (add `.obsidian/`),
`template/docs/obsidian.md` (same instruction, repeated), and
`template/.claude/skills/README.md` (add a skill's local state/cache dir "in
the same commit" it's installed). But the template ships **no `.gitignore`
at all** — not in the repo root, not in `template/`. Every downstream project
starts from zero and has to create the file from scratch before any of those
instructions can be followed, which is exactly the kind of "left for later"
step that a previous plan (006, already merged) was written to prevent for
skill state-dirs specifically. The same gap still exists one level up, for
the base template itself. Shipping a minimal seeded `.gitignore` with
`.obsidian/` in it turns three "create a file and add a line" instructions
into one "the file's already there, just add to it" — and removes the one
concrete thing the instructions currently promise (`.obsidian/` ignored) but
never deliver.

## Current state

- No `.gitignore` exists anywhere in this repository. Confirmed via
  `git ls-files | grep -i gitignore` (no output) and a directory listing of
  both the repo root and `template/` (neither contains one).
- `README.md` — the "Uso" section's post-install steps list (near the top of
  the file, right after the `./apply-template.sh` usage block):
  ```
  5. Añade `.obsidian/` al `.gitignore` del proyecto destino.
  ```
- `apply-template.sh:65-71` — the script's own printed next-steps message,
  which mirrors the README list:
  ```bash
  echo "Listo. Próximos pasos:"
  echo "  1) Edita $DEST_DIR/init.config.sh con las herramientas y comandos reales del proyecto"
  echo "  2) Rellena $DEST_DIR/docs/conventions.md"
  echo "  3) Ejecuta ./init.sh dentro de $DEST_DIR"
  echo "  4) Añade features a $DEST_DIR/feature_list.json"
  echo "  5) Añade .obsidian/ al .gitignore del proyecto destino"
  ```
- `template/docs/obsidian.md:32-33`:
  ```
  Añade `.obsidian/` a `.gitignore` del proyecto destino tras la primera
  apertura, para no versionar configuración local de un editor.
  ```

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Confirm new file present | `test -f template/.gitignore && echo present` | prints `present` |
| Confirm apply-template.sh copies it | see Step 4 smoke test | destination has `.gitignore` with `.obsidian/` in it |
| Confirm no leftover "create a .gitignore" wording | `grep -rn "Añade \`\.obsidian/\` a" README.md template/docs/obsidian.md apply-template.sh` | no matches after Step 2/3 edits (wording changed to "already seeded / verify") |

## Scope

**In scope** (the only files you should modify, or create):
- `template/.gitignore` (new file)
- `README.md` (update the step-5 wording in the post-install list)
- `apply-template.sh` (update the printed step-5 message, lines ~65-71 —
  re-read the file first per the sequencing note above)
- `template/docs/obsidian.md` (update the `.gitignore` instruction wording)

**Out of scope** (do NOT touch, even though it looks related):
- `template/.claude/skills/README.md` — its instruction about skill-specific
  state/cache directories (from plan 006) is a separate, per-skill concern
  and stays as-is; this plan does not attempt to predict or pre-seed
  hypothetical skill directories.
- Anything about `node_modules/`, build output dirs, or other stack-specific
  ignores — the template is explicitly stack-agnostic (see README.md
  "Filosofía" section); adding stack-specific entries would presume a stack
  that hasn't been chosen yet. Keep the seeded file to universally-applicable
  entries only.

## Git workflow

- Branch: `advisor/009-ship-gitignore-seed`
- Commit message style: conventional commits, English (e.g.
  `feat(template): ship a seeded .gitignore instead of instructing users to create one`)
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Create `template/.gitignore`

Create the file with exactly this content (universally-applicable entries
only — see Scope's out-of-scope note on why stack-specific ignores don't
belong here):

```gitignore
# Obsidian local config (this repo is Obsidian-vault-compatible; see docs/obsidian.md)
.obsidian/

# OS noise
.DS_Store
Thumbs.db
```

**Verify**: `test -f template/.gitignore && cat template/.gitignore` → shows
the three-line content above (plus comments).

### Step 2: Update `README.md`'s step-5 wording

Find the post-install steps list (the one right after the
`./apply-template.sh <dir-proyecto-destino> <nombre-proyecto> [stack]` usage
block). Change:

```
5. Añade `.obsidian/` al `.gitignore` del proyecto destino.
```

to:

```
5. Revisa `.gitignore` (ya incluye `.obsidian/`) y añade lo específico de tu stack (`node_modules/`, `dist/`, etc.).
```

**Verify**: `grep -n "ya incluye" README.md` → one match.

### Step 3: Update `apply-template.sh`'s printed message

Re-read `apply-template.sh` first (per the sequencing note — if plan 008
already landed, the substitution loop above this message changed, but the
message block itself should be untouched by 008). Find the step-5 line in
the printed next-steps block and change:

```bash
echo "  5) Añade .obsidian/ al .gitignore del proyecto destino"
```

to:

```bash
echo "  5) Revisa .gitignore (ya incluye .obsidian/) y añade lo especifico de tu stack"
```

(Avoid accented characters inside this particular `echo` string if the rest
of the script's `echo` lines in this block already do — check the existing
lines for the convention used and match it; the existing lines do use
accented Spanish elsewhere in the script, e.g. "Instalando", so matching
accents is fine too. Prioritize consistency with the surrounding lines over
this suggestion.)

**Verify**: `grep -n "ya incluye" apply-template.sh` → one match.

### Step 4: Update `template/docs/obsidian.md`

Change the instruction at (currently) lines 32-33 from:

```
Añade `.obsidian/` a `.gitignore` del proyecto destino tras la primera
apertura, para no versionar configuración local de un editor.
```

to:

```
`.obsidian/` ya está en el `.gitignore` que trae la plantilla — no hace falta
añadirlo a mano. Si tu proyecto ya tenía un `.gitignore` propio antes de
aplicar la plantilla, confirma que la línea sigue ahí tras el merge.
```

**Verify**: `grep -n "ya está en el" template/docs/obsidian.md` → one match.

### Step 5: End-to-end smoke test

```bash
mkdir -p /tmp/gitignore-smoke-test
./apply-template.sh /tmp/gitignore-smoke-test test-project
cat /tmp/gitignore-smoke-test/.gitignore
rm -rf /tmp/gitignore-smoke-test
```

**Verify**: the `cat` output shows the `.obsidian/` line (confirms
`apply-template.sh`'s generic file-copy loop picked up the new file with no
code changes needed there — it copies everything under `template/` via
`find "$TEMPLATE_DIR" -type f`).

## Test plan

No automated test suite applies (template repo, no app code). Verification
is the grep commands per step plus the Step 5 smoke test, which is the
closest thing to an integration test this repo has — it exercises the same
`apply-template.sh` path a real user would run.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `test -f template/.gitignore` → true, contains `.obsidian/`
- [ ] `grep -n "ya incluye" README.md` → one match
- [ ] `grep -n "ya incluye" apply-template.sh` → one match
- [ ] `grep -n "ya está en el" template/docs/obsidian.md` → one match
- [ ] Step 5 smoke test shows `.obsidian/` present in the destination's
      copied `.gitignore`
- [ ] `git status --short` shows changes only in the four in-scope files
      (three edits + one new file)
- [ ] `plans/README.md` status row for 009 updated

## STOP conditions

Stop and report back (do not improvise) if:

- Any of the three files' current wording doesn't match the excerpts above
  (drift since this plan was written — especially `apply-template.sh` if
  plan 008 landed first; re-read before editing).
- You're tempted to add stack-specific entries (`node_modules/`, `.env`,
  build output dirs) to `template/.gitignore` — that's explicitly out of
  scope per the "Filosofía: stack-agnostico" principle documented in
  `README.md`. Report the temptation instead of acting on it.
- `apply-template.sh`'s generic copy loop (`find "$TEMPLATE_DIR" -type f`)
  appears to have an exclusion list that would skip dotfiles — re-check
  Step 5's smoke test carefully if `.gitignore` doesn't show up in the
  destination; this would indicate the copy mechanism itself needs a fix,
  which is a different, out-of-scope problem.

## Maintenance notes

- If a future project adds a stack-specific `.gitignore` seed (e.g. a
  Node-specific variant), it should append to `template/.gitignore` rather
  than replacing it — the Obsidian and OS-noise entries apply regardless of
  stack.
- A reviewer should check that `apply-template.sh`'s idempotency guarantee
  still holds: running it twice against the same destination should `SKIP` an
  existing `.gitignore` (not overwrite a user's customized one) — this is
  existing behavior (the `[ -e "$dest" ]` check in the copy loop), not
  something this plan changes, but worth re-confirming since a `.gitignore`
  is more likely to be hand-edited by users than most other template files.
