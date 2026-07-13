# deps-docs-auto-gen — Implementation Plan

**Status:** executing (Phase 0 + Phase 1 complete, 2026-07-13)
**Spec:** [docs/specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md](../specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md) (Approved, 2026-07-13)
**Parent issue:** [docs/issues/2026-07-13-deps-docs-auto-gen.md](../issues/2026-07-13-deps-docs-auto-gen.md)
**Review trail:**
- [pass 1 aggregate](../reviews/2026-07-13-deps-docs-auto-gen-review-pass1.md) — A / C / D — 5 blocking + 12 non-blocking, all applied.
- [pass 2 aggregate](../reviews/2026-07-13-deps-docs-auto-gen-review-pass2.md) — A / C / D — 1 MEDIUM + 4 polish, all applied. No new CRITICAL/HIGH.

This plan is the mechanical checklist derived from the Approved design §4 (Phase 0–3). Each Phase is **one commit** in principle (per [00-document-management.md](../specifications/00-document-management.md) §6.5). When a Phase's Acceptance is met, write a result-log in `docs/issues/` (per §6.6).

**Revert order:** sequentially revertable in reverse order (Phase 3 → 2 → 1 → 0). Disable the Phase 3 hook (`chmod -x .git/hooks/pre-commit`) *before* reverting any earlier phase (per design §4 / pass-1 A5).

**Conventions for this plan:**
- "Run" means execute the command verbatim in a shell at the repo root (`/home/kiyama/.config/nvim`) unless otherwise noted.
- "Verify" means a human-or-agent check that must pass before the commit.
- Each Phase's commit message follows the repo style: `docs:` / `feat:` / `chore:` prefix + concise summary + body referencing the issue path.
- After each Phase commit, write a result-log at `docs/issues/2026-07-13-<phase>-deps-docs-auto-gen.md` recording the acceptance evidence (per design §4 + [00-document-management.md](../specifications/00-document-management.md) §6.6).

---

## Phases

### Phase 0 — Pre-refactor drift fix in `lua/dpp_loader.lua` (hand-edit)

**Goal:** reconcile the existing live drift so the Phase 1 generator is purely mechanical and S7 holds literally (per design §4 Phase 0, A2/C2 decision (i)).

**Scope:** hand-edit `lua/dpp_loader.lua` only. No generator script, no generated file. No `deps/*.toml` change.

#### Steps

1. Read `lua/dpp_loader.lua` lines 29–36 (current `normal_deps` table):
   ```lua
   local normal_deps = {
     "Shougo/dpp-ext-installer",
     "Shougo/dpp-ext-local",
     "Shougo/dpp-ext-packspec",
     "Shougo/dpp-ext-toml",
     "Shougo/dpp-protocol-git",
     "vim-denops/denops.vim",
   }
   ```
2. Replace the table body with the `deps/dpp.toml` file order (non-minimum entries) + `vim-denops/denops.vim` last (per design §5.5 sample). The result must be byte-identical to what the Phase 1 generator will produce:
   ```lua
   local normal_deps = {
     "Shougo/dpp-ext-toml",
     "Shougo/dpp-ext-local",
     "Shougo/dpp-ext-installer",
     "Shougo/dpp-ext-packspec",
     "Shougo/dpp-protocol-git",
     "Shougo/dpp-protocol-http",
     "vim-denops/denops.vim",
   }
   ```
   - The two changes vs. current: (a) add `"Shougo/dpp-protocol-http",` (it is in `deps/dpp.toml:35` but missing from the current list — the drift), (b) reorder to `deps/dpp.toml` file order (toml → local → installer → packspec → protocol-git → protocol-http), keeping `denops.vim` last.
   - **Do not** change `minimum_deps` (lines 22–26) — it already matches `MINIMUM_REPOS`.
   - **Do not** touch any other line in `dpp_loader.lua`.
3. Run the smoke test:
   ```
   nvim --headless -c 'qa'
   ```
   Expect: exit code 0, no error printed. (This verifies the eager-load of `dpp-protocol-http` at bootstrap does not break startup. Reviewer-C pass-2 already verified the safety mechanism: `load_plugins` at `dpp_loader.lua:70-78` only clones + `runtimepath:prepend`, no `:runtime!`, no sourced side effects — symmetric with `dpp-protocol-git` which is already eagerly loaded today.)
4. (Optional but recommended) verify `dpp-protocol-http` is now on rtp:
   ```
   nvim --headless -c 'lua print(vim.tbl_contains(vim.opt.runtimepath:get(), vim.fn.fnamemodify(vim.env.XDG_CACHE_HOME or (vim.env.HOME .. "/.cache"), ":p") .. "/dpp/repos/github.com/Shougo/dpp-protocol-http"))' -c 'qa'
   ```
   Expect: `true` (or the plugin path appears in `:echo &runtimepath`). If the clone has not happened yet, the first run may clone it; re-run to confirm.

#### Acceptance

- `nvim --headless -c 'qa'` exits 0 with no error.
- The hand-maintained `normal_deps` list (post-edit) is byte-identical to design §5.5 `M.normal_deps` sample (lines 313–321 of the design). Verify by diff:
  ```
  diff <(sed -n '/local normal_deps = {/,/^}/p' lua/dpp_loader.lua) <(sed -n '/M.normal_deps = {/,/^}/p' docs/specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md)
  ```
  Expect: only the wrapping line differs (`local normal_deps = {` vs `M.normal_deps = {`); the entry lines must match exactly (same order, same quotes, same trailing commas).
- No other file is modified in this commit. `git status --short` shows only `M lua/dpp_loader.lua`.

#### Rollback

```
git revert HEAD
```
(or `git checkout HEAD~1 -- lua/dpp_loader.lua` if the commit hasn't been made yet).

#### Commit

```
git add lua/dpp_loader.lua
git commit -m "fix(dpp_loader): reconcile normal_deps drift vs deps/dpp.toml

Add Shougo/dpp-protocol-http (in deps/dpp.toml:35 but missing from the
hand-maintained normal_deps list at dpp_loader.lua:29-36) and reorder to
deps/dpp.toml file order. This is the pre-refactor drift fix that makes
the Phase 1 generator (deps-docs-auto-gen) purely mechanical and S7
holds literally.

Phase 0 of docs/plans/2026-07-13-deps-docs-auto-gen-impl.md.
Issue: docs/issues/2026-07-13-deps-docs-auto-gen.md
"
```

#### Result-log

After the commit, create `docs/issues/2026-07-13-phase0-deps-docs-auto-gen.md` per [00-document-management.md](../specifications/00-document-management.md) §6.6, recording:
- The exact diff applied to `lua/dpp_loader.lua`.
- The `nvim --headless -c 'qa'` exit code and stderr (should be empty).
- Confirmation that the post-edit `normal_deps` matches design §5.5 sample.
- Commit hash.

---

### Phase 1 — Generator: parse TOML, generate `lua/dpp_min_deps.lua`, rewire `dpp_loader.lua`

**Goal:** introduce the Deno generator under `scripts/`, produce `lua/dpp_min_deps.lua`, and rewire `dpp_loader.lua` to `require()` it (per design §4 Phase 1, §5.1–§5.5).

**Scope:** new `scripts/` directory + generated `lua/dpp_min_deps.lua` + edit `lua/dpp_loader.lua` (replace inline tables with require + assert).

#### Steps

1. Create `scripts/deno.json` with the exact content from design §5.1:
   ```json
   {
     "tasks": {
       "gen": "deno run --allow-read=. --allow-write=deps/README.md,lua/dpp_min_deps.lua,docs/references/deps-list.md,docs/README.md scripts/gen_deps.ts"
     },
     "imports": { "@std/toml": "jsr:@std/toml@^1" }
   }
   ```
   - No `--no-remote` (per pass-1 D7 / design I7). No `cache` task (deno's default HTTP cache handles first-run fetching).
2. Create `scripts/deps_as_json.ts` implementing:
   - The `PluginEntry` and `DepsModel` interfaces from design §5.2.
   - TOML parsing via `@std/toml`'s `parse` (design §5.3). Each `[[plugins]]` array element → `PluginEntry` with `source_toml` set by file path (`"dpp"` for `deps/dpp.toml`, etc.).
   - The `classify()` function from design §5.4, including:
     - `MINIMUM_REPOS = new Set(["Shougo/dpp.vim", "Shougo/dpp-ext-lazy"])` (the only place the minimum set is named in code, per design §3.2 / pass-1 A7).
     - The Q1 assertion (`minimum_deps.length !== MINIMUM_REPOS.size` → throw).
     - The trimmed Q7 duplicate-detection assertion (3-line `Set(all).size !== all.length` check, per pass-1 D5).
3. Create `scripts/render_lua.ts` implementing the `lua/dpp_min_deps.lua` renderer per design §5.5. Output must be byte-stable: 2-space indent, single quotes, no trailing whitespace, the 3-line header comment, `local M = {}`, `M.minimum_deps = {...}`, `M.normal_deps = {...}`, `return M`.
4. Create `scripts/sentinels.ts` implementing the `replaceBetween()` API from design §5.8 (throws if either marker absent; preserves marker lines; exactly one blank line between marker and content). This module is used in Phase 2, not Phase 1, but ship it now so Phase 2 is purely additive renderers.
5. Create `scripts/gen_deps.ts` as the entrypoint orchestrating: parse → classify → render Lua → write `lua/dpp_min_deps.lua`. (Markdown renderers are added in Phase 2; for Phase 1, `gen_deps.ts` writes only `lua/dpp_min_deps.lua`. The `--allow-write` list in `deno.json` already covers all 4 outputs — deno allows writing a subset of the listed paths.)
6. Run the generator:
   ```
   deno task gen
   ```
   - First run may fetch `@std/toml` from JSR (network required once, per I7). Subsequent runs use the cache.
   - Expect: `lua/dpp_min_deps.lua` is created with content byte-identical to design §5.5 sample.
7. Verify the generated file:
   ```
   diff <(sed -n '/^-- AUTO-GENERATED/,/^return M$/p' lua/dpp_min_deps.lua) <(sed -n '/^```lua$/,/^```$/p' docs/specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md | sed '1d;$d')
   ```
   Expect: no diff (the generated file matches the design's §5.5 sample exactly, modulo the surrounding ```lua fences).
8. Rewire `lua/dpp_loader.lua`: replace the `local minimum_deps = { ... }` block (lines 22–26) AND the `local normal_deps = { ... }` block (lines 29–36) with:
   ```lua
   local deps = require("dpp_min_deps")
   assert(deps and deps.minimum_deps and deps.normal_deps,
          "dpp_min_deps missing fields")
   local minimum_deps, normal_deps = deps.minimum_deps, deps.normal_deps
   ```
   - The `assert` is per pass-1 A6 (guards the Lua/TS field-name contract; fires at the top of `dpp_loader.lua` before `initialize_dpp()` calls `load_plugins(minimum_deps)`).
   - Keep the surrounding comments (`-- plugins used to ...` etc.) if present; only the two table literals are replaced.
9. Run the smoke tests:
   ```
   nvim --headless -c 'lua print(vim.inspect(require("dpp_min_deps")))' -c 'qa'
   ```
   Expect: prints a table with `minimum_deps = { "Shougo/dpp.vim", "Shougo/dpp-ext-lazy" }` and `normal_deps = { "Shougo/dpp-ext-toml", "Shougo/dpp-ext-local", "Shougo/dpp-ext-installer", "Shougo/dpp-ext-packspec", "Shougo/dpp-protocol-git", "Shougo/dpp-protocol-http", "vim-denops/denops.vim" }` — byte-identical to the post-Phase-0 hand-maintained tables (S7).
   ```
   nvim --headless -c 'qa'
   ```
   Expect: exit 0, no error. dpp loads via the generated module.
10. (Idempotency check, I2) run the generator a second time:
    ```
    deno task gen
    git diff --exit-code -- lua/dpp_min_deps.lua
    ```
    Expect: `git diff --exit-code` exits 0 (no diff — the second run produced byte-identical output).

#### Acceptance

- `nvim --headless -c 'lua print(vim.inspect(require("dpp_min_deps")))' -c 'qa'` prints the two lists matching the post-Phase-0 hand-maintained tables (S7).
- `nvim --headless -c 'qa'` exits 0, no error.
- `deno task gen` is idempotent (second run produces no diff on `lua/dpp_min_deps.lua`).
- `lua/dpp_min_deps.lua` begins with the `-- AUTO-GENERATED by scripts/gen_deps.ts — do not edit by hand.` header (I3, R8).
- `lua/dpp_min_deps.lua` is pure data: only `local M = {}`, `M.minimum_deps = {...}`, `M.normal_deps = {...}`, `return M` — no `vim.*` calls, no side effects, no `require` of other modules (I4).
- `git status --short` shows: `?? lua/dpp_min_deps.lua`, `?? scripts/` (new), `M lua/dpp_loader.lua`. No `deps/*.toml` change.

#### Rollback

```
git revert HEAD
```
(or manually: `git checkout HEAD~1 -- lua/dpp_loader.lua && rm -rf scripts/ lua/dpp_min_deps.lua`).

#### Commit

```
git add scripts/ lua/dpp_min_deps.lua lua/dpp_loader.lua
git commit -m "feat(deps-gen): add Deno generator + generated lua/dpp_min_deps.lua

Introduce scripts/gen_deps.ts (Deno + JSR @std/toml) that parses
deps/{dpp,denops,neovim,merge}.toml, classifies per MINIMUM_REPOS, and
renders lua/dpp_min_deps.lua. Rewire dpp_loader.lua to require() the
generated module (with assert guarding the field-name contract) instead
of declaring minimum_deps/normal_deps inline. Startup order unchanged
(I5); generated lists byte-identical to post-Phase-0 hand-maintained
tables (S7).

Phase 1 of docs/plans/2026-07-13-deps-docs-auto-gen-impl.md.
Issue: docs/issues/2026-07-13-deps-docs-auto-gen.md
"
```

#### Result-log

Create `docs/issues/2026-07-13-phase1-deps-docs-auto-gen.md` recording:
- The `deno task gen` stdout/stderr (first run).
- The `vim.inspect(require("dpp_min_deps"))` output (the two lists).
- The idempotency check result (second run `git diff --exit-code` exit code).
- The `nvim --headless -c 'qa'` exit code.
- Commit hash.

---

### Phase 2 — Generate `deps/README.md` block + `docs/references/deps-list.md` + index line

**Goal:** add the markdown renderers and produce the human-readable docs (per design §4 Phase 2, §5.6–§5.7, S1/S4).

**Scope:** new `scripts/render_readme.ts`, `scripts/render_reference.ts`; regenerated `deps/README.md` (sentinel block), new `docs/references/deps-list.md`, edited `docs/README.md` (index line). No `dpp_loader.lua` change.

#### Steps

1. Create `scripts/render_readme.ts` implementing the `deps/README.md` sentinel-block renderer per design §5.6:
   - Output: `## Minimum loaded` table (repo, description) for `minimum_deps`, `## Normal dpp deps` table for `normal_deps`, `## Other TOMLs` bullet list with per-TOML plugin counts and a link to `docs/references/deps-list.md`.
   - Descriptions come from the `description` field in each TOML entry; if absent, render `_(no description in toml)_`.
2. Create `scripts/render_reference.ts` implementing the `docs/references/deps-list.md` renderer per design §5.7:
   - Full per-plugin table, grouped by source TOML (`## deps/dpp.toml`, `## deps/denops.toml`, etc.).
   - Columns: `repo`, `description`, `if`, `on_ft`, `on_event`, `on_source`, `depends`, `external_commands`, `rtp`, `has_hooks` (✓ if any of `hook_add`/`hook_source`/`lua_source` is present, else empty).
   - **Omit** `hook_add`/`hook_source`/`lua_source` content from the table (they are code, not docs) — only the `has_hooks` marker.
   - **No** in-body `Last updated:` date line (per A3/D8 decision, I2/H5 idempotency).
   - File begins with `<!-- AUTO-GENERATED by scripts/gen_deps.ts — do not edit -->` (R8).
   - Footer: `> Auto-generated by \`scripts/gen_deps.ts\` from \`deps/*.toml\`. Do not edit by hand. Regenerate via \`deno task gen\`; the pre-commit hook will refuse commits with stale output.`
3. Extend `scripts/gen_deps.ts` to also call `render_readme` (writing `deps/README.md` via `sentinels.replaceBetween` between the `AUTO GENERATED PLUGIN LIST` and `AUTO GENERATED PLUGIN LIST END` markers) and `render_reference` (writing `docs/references/deps-list.md` as a full-file rewrite).
   - Sentinel markers in `deps/README.md` are the exact lines:
     ```
     -----------------------------------------------------------------------------
     -- AUTO GENERATED PLUGIN LIST
     -----------------------------------------------------------------------------
     ```
     and
     ```
     -----------------------------------------------------------------------------
     -- AUTO GENERATED PLUGIN LIST END
     -----------------------------------------------------------------------------
     ```
     Use `replaceBetween()` from `scripts/sentinels.ts` (already shipped in Phase 1). If either marker is missing, exit with code 3 (I8, design §5.9).
4. The `docs/README.md` index line is **not** sentinel-protected. Extend `gen_deps.ts` to ensure a line pointing to `references/deps-list.md` exists in `docs/README.md` (append if missing; do not modify if present). Suggested line under the "Directories" section:
   ```
   - [references/deps-list.md](references/deps-list.md) — Auto-generated plugin list across all `deps/*.toml`.
   ```
5. Run the generator:
   ```
   deno task gen
   ```
   Expect: `deps/README.md` sentinel block rewritten, `docs/references/deps-list.md` created, `docs/README.md` index line added (if not already present).
6. Verify the outputs:
   - `deps/README.md`: the `## Minimum loaded` table lists `Shougo/dpp.vim` and `Shougo/dpp-ext-lazy`; the `## Normal dpp deps` table lists the 6 `normal_deps` entries; the `## Other TOMLs` section lists per-TOML counts.
   - `docs/references/deps-list.md`: contains a row for every `[[plugins]]` entry across all four TOMLs. Verify the count:
     ```
     rg -c '^\| `[^`]+` \|' docs/references/deps-list.md
     ```
     Expect: the total matches the sum of `[[plugins]]` blocks in `deps/{dpp,denops,neovim,merge}.toml` (count them: `rg -c '^\[\[plugins\]\]' deps/*.toml | awk -F: '{s+=$2} END{print s}'`).
   - `docs/README.md`: the index line is present (`rg 'references/deps-list.md' docs/README.md` returns a match).
7. (Idempotency check, I2) run the generator a second time:
   ```
   deno task gen
   git diff --exit-code -- deps/README.md docs/references/deps-list.md docs/README.md
   ```
   Expect: exit 0 (no diff).
8. Smoke test (no behavior change expected):
   ```
   nvim --headless -c 'qa'
   ```
   Expect: exit 0, no error. (Phase 2 does not touch `dpp_loader.lua` or any Lua file, so nvim startup is unaffected.)

#### Acceptance

- `deps/README.md` sentinel block lists every `deps/dpp.toml` plugin under "Minimum loaded" (2 entries) and "Normal dpp deps" (6 entries); the "Other TOMLs" section lists counts for `denops.toml`, `neovim.toml`, `merge.toml` with a link to `docs/references/deps-list.md` (S1).
- `docs/references/deps-list.md` contains a row for every `[[plugins]]` entry across all four TOMLs (S4). No in-body date line. Begins with the `<!-- AUTO-GENERATED ... -->` marker.
- `docs/README.md` index lists `references/deps-list.md` (S4).
- `deno task gen` is idempotent (second run produces no diff on any of the 3 files) (I2, H5).
- `nvim --headless -c 'qa'` exits 0 (no behavior change from Phase 2).
- `git status --short` shows: `M deps/README.md`, `?? docs/references/deps-list.md`, `M docs/README.md`, `M scripts/gen_deps.ts` (extended), `?? scripts/render_readme.ts`, `?? scripts/render_reference.ts`. No `lua/` change.

#### Rollback

```
git revert HEAD
```
(or manually: `git checkout HEAD~1 -- deps/README.md docs/README.md scripts/gen_deps.ts && rm -f docs/references/deps-list.md scripts/render_readme.ts scripts/render_reference.ts`).

#### Commit

```
git add scripts/gen_deps.ts scripts/render_readme.ts scripts/render_reference.ts deps/README.md docs/references/deps-list.md docs/README.md
git commit -m "feat(deps-gen): generate deps/README.md block + docs/references/deps-list.md

Add markdown renderers (render_readme.ts, render_reference.ts) and
extend gen_deps.ts to rewrite the AUTO GENERATED PLUGIN LIST sentinel
block in deps/README.md, write docs/references/deps-list.md (full
per-plugin table across all 4 TOMLs, no in-body date line per A3/D8),
and ensure docs/README.md index links to the reference. Idempotent
(I2/H5); no Lua change so nvim startup unaffected.

Phase 2 of docs/plans/2026-07-13-deps-docs-auto-gen-impl.md.
Issue: docs/issues/2026-07-13-deps-docs-auto-gen.md
"
```

#### Result-log

Create `docs/issues/2026-07-13-phase2-deps-docs-auto-gen.md` recording:
- The `deno task gen` stdout/stderr.
- The plugin count in `docs/references/deps-list.md` vs the `[[plugins]]` count in `deps/*.toml` (should match).
- The idempotency check result (second run `git diff --exit-code` exit code).
- The `nvim --headless -c 'qa'` exit code.
- Commit hash.

---

### Phase 3 — Pre-commit hook

**Goal:** install the pre-commit hook that refuses commits with stale generated files (per design §4 Phase 3, §6, S5; concrete instance of [09-dev-workflow.md](../specifications/09-dev-workflow.md) §5).

**Scope:** new `scripts/hooks/pre-commit` (tracked), new `scripts/install-hooks.sh` (tracked), symlinked `.git/hooks/pre-commit` (not tracked). No `lua/` change, no `deps/*.toml` change.

#### Steps

1. Create `scripts/hooks/pre-commit` with the exact content from design §6:
   ```sh
   #!/usr/bin/env sh
   set -e
   cd "$(git rev-parse --show-toplevel)"

   deno task gen

   # Diff only the generated files; if any changed, the user forgot to regen.
   if ! git diff --exit-code -- \
       deps/README.md \
       lua/dpp_min_deps.lua \
       docs/references/deps-list.md \
       docs/README.md; then
     echo "Generated dependency docs are stale." >&2
     echo "Run \`deno task gen\` and \`git add\` the updated files, then re-run your commit." >&2
     exit 1
   fi
   ```
   - **No** `deno task cache` hint (per D7, removed in pass-1 revision).
   - The hook does **not** `git add` (per I6 / H3 — the user reviews and stages the diff themselves).
2. Make the hook script executable:
   ```
   chmod +x scripts/hooks/pre-commit
   ```
3. Create `scripts/install-hooks.sh`:
   ```sh
   #!/usr/bin/env sh
   set -e
   cd "$(git rev-parse --show-toplevel)"

   target="../../scripts/hooks/pre-commit"
   hook=".git/hooks/pre-commit"

   mkdir -p .git/hooks
   ln -sf "$target" "$hook"
   chmod +x scripts/hooks/pre-commit
   echo "Installed .git/hooks/pre-commit -> scripts/hooks/pre-commit"
   ```
   - Idempotent: `ln -sf` overwrites an existing symlink safely.
4. Make the installer executable:
   ```
   chmod +x scripts/install-hooks.sh
   ```
5. Run the installer:
   ```
   sh scripts/install-hooks.sh
   ```
   Expect: `.git/hooks/pre-commit` is a symlink to `scripts/hooks/pre-commit` (`ls -l .git/hooks/pre-commit` shows `-> ../../scripts/hooks/pre-commit`).
6. (Positive test) verify the hook passes when generated files are fresh:
   ```
   deno task gen
   git commit --allow-empty -m "test: hook positive case (will be amended away)"
   ```
   Expect: commit succeeds (generated files are up-to-date, `git diff --exit-code` exits 0).
   - Then amend away the test commit so it doesn't pollute history:
     ```
     git reset --soft HEAD~1
     ```
     (Or just leave it and squash later — but `--allow-empty` test commits should not land on `develop`.)
7. (Negative test) verify the hook blocks when generated files are stale:
   - Make a deliberate change to a generated file's source, e.g. add a comment to `deps/dpp.toml` (do NOT commit it):
     ```
     echo "# test stale" >> deps/dpp.toml
     ```
   - Run `deno task gen` so the generated files are updated, but do **not** `git add` them:
     ```
     deno task gen
     ```
   - Attempt a commit:
     ```
     git commit --allow-empty -m "test: hook negative case (should be blocked)"
     ```
     Expect: the hook re-runs `deno task gen` (which is a no-op since files are already fresh), then `git diff --exit-code` on the generated files... wait — if `deno task gen` already ran and the files are fresh, the diff against the *staged* state is what matters. The correct negative test is: modify `deps/dpp.toml`, do NOT run `deno task gen`, attempt to commit. The hook runs `deno task gen` (which regenerates the files), then `git diff --exit-code` sees the regenerated files differ from the committed state → exit 1 → commit blocked.
   - Corrected negative test:
     ```
     echo "# test stale" >> deps/dpp.toml
     git commit --allow-empty -m "test: hook negative case (should be blocked)"
     ```
     Expect: the hook runs `deno task gen` (regenerates `deps/README.md` etc.), then `git diff --exit-code` exits 1 (the generated files changed), the hook prints "Generated dependency docs are stale." and exits 1. The commit is blocked.
   - Clean up the test:
     ```
     git checkout -- deps/dpp.toml deps/README.md lua/dpp_min_deps.lua docs/references/deps-list.md docs/README.md
     ```
8. Verify the symlink is not tracked (`.git/hooks/` is not in the repo):
   ```
   git status --short
   ```
   Expect: only `?? scripts/hooks/pre-commit`, `?? scripts/install-hooks.sh` (and the Phase 3 commit will track these). `.git/hooks/pre-commit` is not listed (it's outside the worktree).

#### Acceptance

- `scripts/hooks/pre-commit` and `scripts/install-hooks.sh` exist, are executable, and are tracked.
- `.git/hooks/pre-commit` is a symlink to `scripts/hooks/pre-commit`.
- Positive test: `git commit` succeeds when generated files are fresh.
- Negative test: `git commit` is blocked (exit 1, "Generated dependency docs are stale." message) when `deps/dpp.toml` is modified but the generated files are not regenerated/committed (S5).
- The hook does not auto-stage (I6 / H3) — verify by checking the negative test leaves the regenerated files unstaged (`git status` shows them as modified, not staged).
- `git status --short` after cleanup shows only `?? scripts/hooks/pre-commit`, `?? scripts/install-hooks.sh`.

#### Rollback

```
chmod -x .git/hooks/pre-commit   # or: rm .git/hooks/pre-commit
git revert HEAD
```
(The symlink is outside the worktree, so `git revert` handles the tracked `scripts/hooks/` files; manually remove the symlink if desired.)

#### Commit

```
git add scripts/hooks/pre-commit scripts/install-hooks.sh
git commit -m "feat(deps-gen): add pre-commit hook refusing stale generated files

Install scripts/hooks/pre-commit (symlinked into .git/hooks/pre-commit
via scripts/install-hooks.sh) that runs deno task gen then git diff
--exit-code on the 4 generated files. Blocks commits with stale output
(S5); does not auto-stage (I6/H3). Concrete instance of
09-dev-workflow.md §5. Run \`sh scripts/install-hooks.sh\` once on fresh
clones.

Phase 3 of docs/plans/2026-07-13-deps-docs-auto-gen-impl.md.
Issue: docs/issues/2026-07-13-deps-docs-auto-gen.md
"
```

#### Result-log

Create `docs/issues/2026-07-13-phase3-deps-docs-auto-gen.md` recording:
- The `ls -l .git/hooks/pre-commit` output (showing the symlink).
- The positive test result (commit succeeded).
- The negative test result (commit blocked, exit 1, "stale" message).
- Confirmation that the hook does not auto-stage (negative test left files unstaged).
- Commit hash.

---

## Post-execution

After Phase 3's commit + result-log:

1. Update the parent issue `docs/issues/2026-07-13-deps-docs-auto-gen.md`:
   - **Status:** `open` → `closed`.
   - Add a closing note referencing the 4 result-logs and confirming S1–S7 are all met (per [00-document-management.md](../specifications/00-document-management.md) §4 lifecycle: `issue (closed)` after `result-log`).
2. Update `docs/README.md` index if needed (the Phase 2 generator already adds the `references/deps-list.md` line; no manual edit).
3. Verify the full smoke matrix one final time:
   ```
   nvim --headless -c 'qa'
   deno task gen
   git diff --exit-code -- deps/README.md lua/dpp_min_deps.lua docs/references/deps-list.md docs/README.md
   ```
   Expect: nvim exits 0; `deno task gen` is a no-op; `git diff --exit-code` exits 0.
4. (Optional) Push:
   ```
   git push origin develop
   ```

## Open questions carried forward (not blocking execution)

- **Q3** (CI integration) — deferred until CI is set up (design §7, out of scope per §1.3). The pre-commit hook is the only enforcement surface for now.
- **Q5** (`@std/toml` newline preservation in `''' … '''` strings) — non-issue for the current scope (hooks are omitted from the reference table, only a `✓` marker is rendered). Becomes relevant only if a future "render hooks" feature is added. No verification needed in Phase 1 (per pass-1 D6).

## Summary table

| Phase | Commit type | Files touched | Acceptance key | Rollback |
|-------|-------------|---------------|----------------|----------|
| 0 | `fix(dpp_loader):` | `lua/dpp_loader.lua` | `nvim --headless -c 'qa'` exits 0; `normal_deps` matches design §5.5 sample | `git revert HEAD` |
| 1 | `feat(deps-gen):` | `scripts/`, `lua/dpp_min_deps.lua`, `lua/dpp_loader.lua` | `vim.inspect(require("dpp_min_deps"))` matches post-Phase-0 tables; idempotent | `git revert HEAD` |
| 2 | `feat(deps-gen):` | `scripts/render_*.ts`, `deps/README.md`, `docs/references/deps-list.md`, `docs/README.md` | per-TOML plugin counts match; idempotent; nvim unaffected | `git revert HEAD` |
| 3 | `feat(deps-gen):` | `scripts/hooks/pre-commit`, `scripts/install-hooks.sh` | positive + negative hook tests pass; no auto-stage | `chmod -x .git/hooks/pre-commit` + `git revert HEAD` |
