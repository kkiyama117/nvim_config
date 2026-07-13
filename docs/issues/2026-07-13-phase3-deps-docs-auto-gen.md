# Phase 3 result-log — deps-docs-auto-gen

**Date:** 2026-07-13
**Phase:** 3 (Pre-commit hook)
**Plan:** [docs/plans/2026-07-13-deps-docs-auto-gen-impl.md](../plans/2026-07-13-deps-docs-auto-gen-impl.md) §Phase 3
**Issue:** [docs/issues/2026-07-13-deps-docs-auto-gen.md](2026-07-13-deps-docs-auto-gen.md)
**Design:** [§4 Phase 3](../specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md), [§6](../specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md)
**Commit:** `2d772f2`

## Acceptance evidence

| Criterion (plan §Phase 3 Acceptance) | Result | Evidence |
|---------------------------------------|--------|----------|
| `scripts/hooks/pre-commit` and `scripts/install-hooks.sh` exist, are executable, and are tracked | ✅ PASS | `git show --stat 2d772f2`: both files with mode 100755 |
| `.git/hooks/pre-commit` is a symlink to `scripts/hooks/pre-commit` | ✅ PASS | `ls -l .git/hooks/pre-commit` → `-> ../../scripts/hooks/pre-commit` |
| Positive test: `git commit` succeeds when generated files are fresh | ✅ PASS | see Positive test section below |
| Negative test: `git commit` is blocked (exit 1, "Generated dependency docs are stale." message) when `deps/dpp.toml` is modified but generated files are not committed (S5) | ✅ PASS | see Negative test section below |
| The hook does not auto-stage (I6 / H3) — negative test leaves regenerated files unstaged | ✅ PASS | `git status --short` showed ` M` (unstaged), not `M ` (staged) |
| `git status --short` after cleanup shows only `?? scripts/hooks/pre-commit`, `?? scripts/install-hooks.sh` | ✅ PASS | after cleanup: only untracked hook files (pre-commit) |

## Files created

| Path | Mode | Purpose |
|------|------|---------|
| `scripts/hooks/pre-commit` | 100755 | Tracked hook script: `set -e; cd to repo root; deno task gen; git diff --exit-code` on 4 generated files; blocks with "stale" message + remediation hint if any differ. No `deno task cache` hint (D7). Does not `git add` (I6/H3). |
| `scripts/install-hooks.sh` | 100755 | Tracked installer: `ln -sf ../../scripts/hooks/pre-commit .git/hooks/pre-commit; chmod +x scripts/hooks/pre-commit`. Idempotent via `ln -sf`. |

## Symlink verification

```
$ sh scripts/install-hooks.sh
Installed .git/hooks/pre-commit -> scripts/hooks/pre-commit

$ ls -l .git/hooks/pre-commit
lrwxrwxrwx 1 kkiyama kiyama 30  7月 13 07:11 .git/hooks/pre-commit -> ../../scripts/hooks/pre-commit
```

The symlink is not tracked by git (`.git/hooks/` is outside the worktree). `git status` does not list it.

## Positive test

```
$ deno task gen >/dev/null 2>&1
$ git commit --allow-empty -m "test: hook positive case (will be reset)"
Task gen deno run --allow-read=. --allow-write=... scripts/gen_deps.ts
[gen_deps] wrote lua/dpp_min_deps.lua
[gen_deps] updated sentinel block in deps/README.md
[gen_deps] wrote docs/references/deps-list.md
[develop 56e1935] test: hook positive case (will be reset)
COMMIT_EXIT=0
```

The hook ran `deno task gen` (regenerated files, but content identical to committed state), then `git diff --exit-code` on the 4 generated files exited 0 (no diff). Commit succeeded.

Test commit reset:
```
$ git reset --soft HEAD~1
RESET_EXIT=0
$ git log --oneline -1
80b713c docs: add Phase 2 result-log for deps-docs-auto-gen
```

## Negative test

The plan's suggested `echo "# test stale" >> deps/dpp.toml` would add a TOML comment, which `@std/toml` ignores — the generated output would not change, so the hook would pass (not block). This is a bug in the plan's negative test. Instead, I added `description = 'test stale'` to the `dpp-ext-lazy` entry (which previously had no description), which changes the generated `deps/README.md` (replacing `_(no description in toml)_` with `test stale`) and `docs/references/deps-list.md`.

```
$ sed -i "/^repo = 'Shougo\/dpp-ext-lazy'$/a description = 'test stale'" deps/dpp.toml
$ git commit --allow-empty -m "test: hook negative case (should be blocked)"
Task gen deno run --allow-read=. --allow-write=... scripts/gen_deps.ts
[gen_deps] wrote lua/dpp_min_deps.lua
[gen_deps] updated sentinel block in deps/README.md
[gen_deps] wrote docs/references/deps-list.md
diff --git a/deps/README.md b/deps/README.md
index b50368c..65d3c82 100644
--- a/deps/README.md
+++ b/deps/README.md
@@ -19,7 +19,7 @@ This subdirectory has a data of the dependencies of vimrc
 | repo | description |
 |------|-------------|
 | `Shougo/dpp.vim` | Dark powered plugin manager for Vim/Neovim |
-| `Shougo/dpp-ext-lazy` | _(no description in toml)_ |
+| `Shougo/dpp-ext-lazy` | test stale |
 
 ## Normal dpp deps (loaded before denops ready)
 
diff --git a/docs/references/deps-list.md b/docs/references/deps-list.md
index c8c6ec4..83dd151 100644
--- a/docs/references/deps-list.md
+++ b/docs/references/deps-list.md
@@ -12,7 +12,7 @@ Regenerate via `deno task gen`; the pre-commit hook refuses stale output.
 | repo | description | if | on_ft | on_event | on_source | depends | external_commands | rtp | has_hooks |
 |------|-------------|----|-------|----------|----------|---------|-------------------|-----|-----------|
 | `Shougo/dpp.vim` | Dark powered plugin manager for Vim/Neovim |  |  |  |  |  |  | "" |  |
-| `Shougo/dpp-ext-lazy` |  |  |  |  |  |  |  | "" |  |
+| `Shougo/dpp-ext-lazy` | test stale |  |  |  |  |  |  | "" |  |
 | `Shougo/dpp-ext-toml` |  |  |  |  |  |  |  |  | ✓ |
 | `Shougo/dpp-ext-local` |  |  |  |  |  |  |  |  |  |
 | `Shougo/dpp-ext-installer` |  |  |  |  |  |  |  |  |  |
Generated dependency docs are stale.
Run `deno task gen` and `git add` the updated files, then re-run your commit.
COMMIT_EXIT=1
```

The hook:
1. Ran `deno task gen` → regenerated `deps/README.md` and `docs/references/deps-list.md` with the new description
2. `git diff --exit-code` on the 4 generated files → found differences in `deps/README.md` and `docs/references/deps-list.md` → exit 1
3. Printed "Generated dependency docs are stale." + remediation hint to stderr
4. Exited 1 → commit blocked

### No auto-stage verification (I6 / H3)

```
$ git status --short
 M deps/README.md
 M deps/dpp.toml
 M docs/references/deps-list.md
?? scripts/hooks/
?? scripts/install-hooks.sh
```

All modified files show ` M` (space before M = modified but NOT staged). The hook did not `git add` the regenerated files. The user must review the diff and stage manually (I6 / H3).

## Cleanup

```
$ git checkout -- deps/dpp.toml deps/README.md docs/references/deps-list.md
$ deno task gen >/dev/null 2>&1
$ git status --short
?? scripts/hooks/
?? scripts/install-hooks.sh
```

Working tree clean except for the untracked hook files (which are committed in `2d772f2`).

## Plan revision suggestion

Update plan §Phase 3 step 7 negative test: replace `echo "# test stale" >> deps/dpp.toml` with a change that actually affects the generated output, e.g. `sed -i "/^repo = 'Shougo\/dpp-ext-lazy'$/a description = 'test stale'" deps/dpp.toml`. A TOML comment (`# ...`) is ignored by `@std/toml` and does not change the generated files, so the hook would not block — defeating the purpose of the negative test.

## Plan status

`docs/plans/2026-07-13-deps-docs-auto-gen-impl.md`: `executing (Phase 0+1+2 complete)` → `executing (Phase 0+1+2+3 complete) — pending post-execution issue closure`. This status update was included in the Phase 3 commit (`2d772f2`).

## Rollback

```
chmod -x .git/hooks/pre-commit   # or: rm .git/hooks/pre-commit
git revert 2d772f2
```

The symlink is outside the worktree, so `git revert` handles the tracked `scripts/hooks/` files; manually remove or disable the symlink if desired. Phases 0–2 remain intact.

Revert order per plan: Phase 3 → 2 → 1 → 0. Disable the hook (`chmod -x .git/hooks/pre-commit`) *before* reverting Phase 3 so the hook doesn't interfere with the revert commit.
