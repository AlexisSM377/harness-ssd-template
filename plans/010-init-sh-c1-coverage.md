# Plan 010: Close the gap between init.sh's harness-coherence check and CHECKPOINTS.md's C1 list

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat ca58fc0..HEAD -- template/init.sh template/CHECKPOINTS.md`
> If either file changed since this plan was written, compare the "Current
> state" excerpts below against the live file before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: tech-debt
- **Planned at**: commit `ca58fc0`, 2026-07-28

## Why this matters

`template/CHECKPOINTS.md`'s C1 checkpoint ("El arnés está completo") claims
five specific docs must exist: `docs/architecture.md`, `docs/conventions.md`,
`docs/verification.md`, `docs/specs.md`, `docs/obsidian.md`. But
`template/init.sh`'s own automated harness-coherence gate (§4, the block of
`[ -f ... ] || fail` checks) only hard-fails on three of those five —
`docs/specs.md` and `docs/obsidian.md` are never checked. The same gate also
only checks that a bare `specs/` directory exists, not that
`specs/_template/` (the skeleton `spec_author` copies for every new feature)
is actually present. This means a downstream project can delete
`docs/specs.md`, `docs/obsidian.md`, or `specs/_template/` and `init.sh` will
still print "✅ Todo verde" — false confidence against the exact checklist
CHECKPOINTS.md says `init.sh` is supposed to back. Since C1 is explicitly the
checkpoint a reviewer uses to confirm "the harness is complete," and
`init.sh` is the automated stand-in for manually walking that checklist, the
two should list the same files.

## Current state

`template/CHECKPOINTS.md:9-16` (C1 in full):

```markdown
## C1 — El arnés está completo

- [ ] Existen los archivos base: `CLAUDE.md`, `AGENTS.md`, `CHECKPOINTS.md`, `STATUS.md`, `init.sh`, `init.config.sh`, `feature_list.json`
- [ ] Existen los 5 docs: `docs/architecture.md`, `docs/conventions.md`, `docs/verification.md`, `docs/specs.md`, `docs/obsidian.md`
- [ ] Existe `specs/` con al menos la plantilla `_template/`
- [ ] Existen los 5 agentes: `.claude/agents/leader.md`, `spec_author.md`, `explorer.md`, `implementer.md`, `reviewer.md`
- [ ] `./init.sh` termina con exit code 0
```

`template/init.sh:78-97` (the §4 block this plan edits):

```bash
# ── 4. HARNESS — coherencia del arnés ───────
echo ""
echo "→ Verificando coherencia del harness..."

[ -f AGENTS.md ]             || fail "AGENTS.md no encontrado"
[ -f CLAUDE.md ]             || fail "CLAUDE.md no encontrado"
[ -f CHECKPOINTS.md ]        || fail "CHECKPOINTS.md no encontrado"
[ -f STATUS.md ]             || fail "STATUS.md no encontrado"
[ -f feature_list.json ]     || fail "feature_list.json no encontrado"
[ -f init.config.sh ]        || fail "init.config.sh no encontrado"
[ -f progress/current.md ]   || fail "progress/current.md no encontrado"
[ -d specs ]                 || fail "specs/ no encontrado"
[ -f docs/architecture.md ]  || fail "docs/architecture.md no encontrado"
[ -f docs/conventions.md ]   || fail "docs/conventions.md no encontrado"
[ -f docs/verification.md ]  || fail "docs/verification.md no encontrado"

for agent in leader spec_author explorer implementer reviewer; do
  [ -f ".claude/agents/${agent}.md" ] || fail ".claude/agents/${agent}.md no encontrado"
done
ok "Archivos del harness presentes"
```

Missing relative to C1: `docs/specs.md`, `docs/obsidian.md`, and a check that
`specs/_template/` specifically (not just `specs/`) exists. Note `init.sh`
itself is trivially present if it's running at all, so C1's mention of it
needs no explicit check (this is already the existing behavior's implicit
assumption, not something to add).

The four files `spec_author.md` expects to copy from `specs/_template/` (per
`template/docs/specs.md:27-28`: "Copia `specs/_template/` →
`specs/<feature-name>/`") are `requirements.md`, `design.md`, `tasks.md`,
`traceability.md` — confirmed by `template/specs/_template/` containing
exactly those four files.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Syntax check | `bash -n template/init.sh` | exit 0, no output |
| Confirm new checks present | `grep -n "docs/specs.md\|docs/obsidian.md" template/init.sh` | two matches (one per new check) |
| Run against this repo's own template dir as a smoke test | see Step 2 | new checks pass (files exist in `template/`) |

## Scope

**In scope** (the only file you should modify):
- `template/init.sh`

**Out of scope** (do NOT touch, even though it looks related):
- `template/CHECKPOINTS.md` — its C1 list is already correct; this plan
  brings `init.sh` up to match it, not the other way around.
- Any other CHECKPOINTS section (C2-C7) or other parts of `init.sh` (§1
  entorno, §2 env vars, §3 dependencias, §5-7 build/test/summary) — untouched.
- Adding schema validation for `feature_list.json` entries — that's plan 007,
  a separate concern (documentation, not `init.sh` behavior).

## Git workflow

- Branch: `advisor/010-init-sh-c1-coverage`
- Commit message style: conventional commits, English (e.g.
  `fix(template): close init.sh's coverage gap against CHECKPOINTS.md C1`)
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Add the missing file/dir checks to `init.sh` §4

In `template/init.sh`, in the §4 block (see "Current state" above), add
three new checks. Insert the two doc checks right after the existing
`docs/verification.md` line, and the `specs/_template/` checks right after
the existing `[ -d specs ]` line, so the block reads:

```bash
[ -f AGENTS.md ]             || fail "AGENTS.md no encontrado"
[ -f CLAUDE.md ]             || fail "CLAUDE.md no encontrado"
[ -f CHECKPOINTS.md ]        || fail "CHECKPOINTS.md no encontrado"
[ -f STATUS.md ]             || fail "STATUS.md no encontrado"
[ -f feature_list.json ]     || fail "feature_list.json no encontrado"
[ -f init.config.sh ]        || fail "init.config.sh no encontrado"
[ -f progress/current.md ]   || fail "progress/current.md no encontrado"
[ -d specs ]                 || fail "specs/ no encontrado"
[ -d specs/_template ]       || fail "specs/_template/ no encontrado"
[ -f specs/_template/requirements.md ] || fail "specs/_template/requirements.md no encontrado"
[ -f specs/_template/design.md ]       || fail "specs/_template/design.md no encontrado"
[ -f specs/_template/tasks.md ]        || fail "specs/_template/tasks.md no encontrado"
[ -f specs/_template/traceability.md ] || fail "specs/_template/traceability.md no encontrado"
[ -f docs/architecture.md ]  || fail "docs/architecture.md no encontrado"
[ -f docs/conventions.md ]   || fail "docs/conventions.md no encontrado"
[ -f docs/verification.md ]  || fail "docs/verification.md no encontrado"
[ -f docs/specs.md ]         || fail "docs/specs.md no encontrado"
[ -f docs/obsidian.md ]      || fail "docs/obsidian.md no encontrado"
```

Keep the existing alignment style (spaces before `||`) consistent with the
surrounding lines — match column width to whatever reads cleanly, exact
alignment is cosmetic and not verified.

**Verify**: `bash -n template/init.sh` → exit 0, no syntax errors.

### Step 2: Smoke test against this repo's own `template/` directory

`template/init.sh` is written to run from a destination project's root (it
does `cd "$SCRIPT_DIR"` to the directory containing itself), so the cleanest
smoke test is copying it into a scratch copy of `template/` and running it
there — `template/` already has every file this plan's new checks look for.

```bash
cp -r template /tmp/init-sh-smoke-test
cd /tmp/init-sh-smoke-test
chmod +x init.sh
./init.sh 2>&1 | grep -A1 "coherencia del harness"
cd -
rm -rf /tmp/init-sh-smoke-test
```

**Verify**: output includes `✅ Archivos del harness presentes` (the new
checks didn't fail against `template/`'s own known-good file set — if any
new check fails here, the path in the check is wrong, not the file that's
missing).

### Step 3: Confirm the checks would actually catch a deletion

As a negative-case check, delete one of the newly-checked files in the
scratch copy and confirm `init.sh` now fails where it previously wouldn't
have:

```bash
cp -r template /tmp/init-sh-negative-test
cd /tmp/init-sh-negative-test
chmod +x init.sh
rm docs/obsidian.md
./init.sh 2>&1 | tail -5
cd -
rm -rf /tmp/init-sh-negative-test
```

**Verify**: output shows `❌ docs/obsidian.md no encontrado` and the script
exits non-zero (confirm with `echo $?` if not obvious from output) — this is
the exact failure this plan intends to introduce; before this plan, deleting
`docs/obsidian.md` would NOT have caused `init.sh` to fail.

## Test plan

No automated test suite applies (template repo — `init.sh` itself is the
verification tool, there's no meta-test-runner for it). The smoke test
(Step 2, positive case) and negative-case check (Step 3) together are the
verification: one confirms no false positives against a known-good tree, the
other confirms the new checks actually catch what they're meant to catch.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `bash -n template/init.sh` → exit 0
- [ ] `grep -c "docs/specs.md\|docs/obsidian.md" template/init.sh` → 2 (one
      `[ -f ... ]` line each)
- [ ] `grep -n "specs/_template" template/init.sh` → at least 5 matches (the
      dir check plus 4 file checks)
- [ ] Step 2 smoke test passes (`✅ Archivos del harness presentes` against
      `template/`'s own tree)
- [ ] Step 3 negative-case test shows the new check actually fails when the
      file is missing
- [ ] `git status --short` shows changes only in `template/init.sh`
- [ ] `plans/README.md` status row for 010 updated

## STOP conditions

Stop and report back (do not improvise) if:

- The §4 block in `template/init.sh` doesn't match the "Current state"
  excerpt (drift since this plan was written — re-read the live file).
- The Step 2 smoke test fails against `template/`'s own tree — that means a
  path in one of the new checks is wrong (e.g. typo), not that a real file is
  missing; fix the check, don't work around it.
- You're tempted to also add a check for `init.sh` itself, or for the
  `.claude/skills/` directory — both are out of scope: `init.sh`'s own
  presence is self-evident (it's running), and `.claude/skills/` isn't part
  of CHECKPOINTS.md's C1 list.

## Maintenance notes

- If `CHECKPOINTS.md`'s C1 list changes in the future (a doc added, removed,
  or renamed), `init.sh`'s §4 block must be updated in the same commit — the
  whole point of this plan is that the two shouldn't drift apart again.
- A reviewer should check that the new checks fail closed (script exits
  non-zero via `fail()`, which itself calls `exit 1`) rather than just
  printing a warning — matching the severity of the existing checks in this
  same block, which are all hard `fail`, not `warn`.
- No follow-up deferred; this plan is complete in scope once `init.sh`'s §4
  matches CHECKPOINTS.md's C1 exactly.
