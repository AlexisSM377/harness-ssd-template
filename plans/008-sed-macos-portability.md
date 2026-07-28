# Plan 008: Make apply-template.sh's placeholder substitution portable across GNU and BSD sed

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat ca58fc0..HEAD -- apply-template.sh`
> If the file changed since this plan was written, compare the "Current
> state" excerpt below against the live file before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `ca58fc0`, 2026-07-28

## Why this matters

`apply-template.sh` is the entire installer for this template — its one job
is to copy `template/` into a destination project and substitute
`{{PROJECT_NAME}}`/`{{STACK}}`. The substitution step uses GNU sed's in-place
syntax (`sed -i "script" file`). On BSD sed — the default on stock macOS,
unless the user has installed GNU coreutils — `-i` requires a backup-suffix
argument immediately following it (even if empty: `-i ''`). Without it, BSD
sed reads the sed script itself as the backup suffix and treats the target
file path as the script to execute, which fails (or worse, silently does the
wrong thing). This means the installer's core step is broken by default for
any macOS user who hasn't specifically installed GNU sed — a portability gap
in the one script every user of this template runs first.

## Current state

`apply-template.sh:47-55` (full substitution block):

```bash
if [ "${#COPIED_FILES[@]}" -gt 0 ]; then
  echo ""
  echo "Sustituyendo placeholders..."
  # Escapar caracteres especiales de sed en el valor de reemplazo
  PROJECT_NAME_ESC=$(printf '%s' "$PROJECT_NAME" | sed -e 's/[\/&]/\\&/g')
  STACK_ESC=$(printf '%s' "$STACK" | sed -e 's/[\/&]/\\&/g')
  for f in "${COPIED_FILES[@]}"; do
    sed -i "s/{{PROJECT_NAME}}/${PROJECT_NAME_ESC}/g; s/{{STACK}}/${STACK_ESC}/g" "$f"
  done
else
```

The `sed -e 's/[\/&]/\\&/g'` calls (escaping `/` and `&` in the replacement
values) are portable between GNU and BSD sed — they don't use `-i`. Only the
`sed -i "..." "$f"` call on the line inside the `for` loop is the problem.

The standard portable detection idiom: GNU sed accepts `--version` and exits
0 printing version info; BSD sed doesn't recognize `--version` and exits
non-zero. Use that to branch which `-i` invocation form to use.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Syntax check | `bash -n apply-template.sh` | exit 0, no output |
| Confirm sed flavor on this machine | `sed --version >/dev/null 2>&1; echo $?` | `0` on GNU sed (most Linux, Git Bash on Windows); nonzero on BSD sed (stock macOS) — tells you which branch this environment will exercise |
| End-to-end smoke test | see Step 2 below | placeholders substituted, no `{{PROJECT_NAME}}`/`{{STACK}}` left in destination |

## Scope

**In scope** (the only file you should modify):
- `apply-template.sh`

**Out of scope** (do NOT touch, even though they look related):
- `template/init.sh`, `template/init.config.sh` — neither uses `sed -i`; no
  change needed.
- The escaping logic (`PROJECT_NAME_ESC`, `STACK_ESC`) — already portable,
  leave as-is.
- Anything about the `--issues` flag or other apply-template.sh behavior not
  related to the substitution loop.

## Git workflow

- Branch: `advisor/008-sed-macos-portability`
- Commit message style: conventional commits, English (e.g.
  `fix(template): make apply-template.sh's sed -i portable across GNU/BSD`)
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Detect sed flavor and branch the `-i` invocation

Replace the `for` loop in `apply-template.sh` (currently):

```bash
  for f in "${COPIED_FILES[@]}"; do
    sed -i "s/{{PROJECT_NAME}}/${PROJECT_NAME_ESC}/g; s/{{STACK}}/${STACK_ESC}/g" "$f"
  done
```

with a version that detects the sed flavor once, before the loop, and reuses
the right invocation form:

```bash
  if sed --version >/dev/null 2>&1; then
    SED_INPLACE=(-i)
  else
    SED_INPLACE=(-i '')
  fi
  for f in "${COPIED_FILES[@]}"; do
    sed "${SED_INPLACE[@]}" "s/{{PROJECT_NAME}}/${PROJECT_NAME_ESC}/g; s/{{STACK}}/${STACK_ESC}/g" "$f"
  done
```

Place the `if sed --version ...` detection block right before the `for` loop
starts (i.e., right after the `STACK_ESC=...` line), not inside the loop —
it only needs to run once.

**Verify**: `bash -n apply-template.sh` → exit 0, no syntax errors.

### Step 2: End-to-end smoke test on this machine's sed

Run the installer against a throwaway destination directory and confirm
substitution still works (this exercises whichever branch matches the
executor's own sed — document which one in your report):

```bash
mkdir -p /tmp/apply-template-smoke-test
./apply-template.sh /tmp/apply-template-smoke-test test-project some-stack
grep -rl "{{PROJECT_NAME}}" /tmp/apply-template-smoke-test | wc -l
grep -rl "{{STACK}}" /tmp/apply-template-smoke-test | wc -l
grep -c "test-project" /tmp/apply-template-smoke-test/STATUS.md
rm -rf /tmp/apply-template-smoke-test
```

**Verify**: both `grep -rl` counts print `0` (no leftover placeholders), and
the last `grep -c` prints `1` or more (substitution actually happened).

## Test plan

No automated test suite exists for this repo (it's a template of shell +
markdown, not an application). The verification is the smoke test in Step 2,
run against whatever sed is available in the executor's environment.

- If the executor's environment has GNU sed (likely, e.g. Linux CI or Git
  Bash on Windows): Step 2 confirms the `-i` (no-arg) branch still works
  exactly as before the change — this is a regression check.
- The BSD-sed branch (`-i ''`) cannot be exercised without an actual BSD sed
  binary. If the executor's environment doesn't have one, say so explicitly
  in the report rather than claiming macOS behavior was verified — the fix
  is applying the well-documented idiom correctly, not something this plan
  can prove end-to-end without that binary.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `bash -n apply-template.sh` → exit 0
- [ ] Smoke test (Step 2) shows 0 leftover `{{PROJECT_NAME}}`/`{{STACK}}`
      placeholders and confirms substitution happened
- [ ] `grep -n "sed --version" apply-template.sh` → one match (detection
      block present)
- [ ] `git status --short` shows changes only in `apply-template.sh`
- [ ] `plans/README.md` status row for 008 updated

## STOP conditions

Stop and report back (do not improvise) if:

- The `for f in "${COPIED_FILES[@]}"; do sed -i ...` block at
  `apply-template.sh:53-55` doesn't match the excerpt above (file has
  drifted — re-read the current version before adapting this plan).
- The smoke test in Step 2 leaves leftover placeholders on this machine's
  sed — that means the fix itself is wrong, not just untested on BSD; do not
  proceed to mark this done.
- You don't have a way to run `bash -n` or execute the script at all in your
  environment — report this limitation rather than skipping verification.

## Maintenance notes

- If this script ever gains more `sed -i` calls elsewhere, they should reuse
  the same `SED_INPLACE` array rather than re-deriving the detection logic.
- A reviewer should specifically check that the `SED_INPLACE=(-i '')` branch
  uses an actual empty-string array element (`''`), not a missing argument —
  that's the exact detail BSD sed requires and the easiest part to get subtly
  wrong.
- No follow-up deferred; this plan is complete in scope once both branches
  are structurally correct.
