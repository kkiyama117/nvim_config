# Auto-generate dependency documents — Design

**Status:** in-review (pass 1 complete, pass 2 requested)
**Date opened:** 2026-07-13
**Issue:** [docs/issues/2026-07-13-deps-docs-auto-gen.md](../../issues/2026-07-13-deps-docs-auto-gen.md)
**Author:** kkiyama
**Review trail:** [pass 1 aggregate](../../reviews/2026-07-13-deps-docs-auto-gen-review-pass1.md) — [A](../../reviews/2026-07-13-deps-docs-auto-gen-review-pass1-A-architecture.md) / [C](../../reviews/2026-07-13-deps-docs-auto-gen-review-pass1-C-plugin-loading.md) / [D](../../reviews/2026-07-13-deps-docs-auto-gen-review-pass1-D-devils-advocate.md) — 5 blocking + 12 non-blocking findings, all applied per §8; pass 2 requested with same letters (A + C + D) to verify RESOLVED without regression.

> **Review requirement (per [AGENTS.md](../../../AGENTS.md) §4):** this design touches startup order (`lua/dpp_loader.lua` requires a generated module) and plugin loading (reads `deps/*.toml`, declares the minimum dpp set). It therefore requires review letters **A + C + D** at minimum.

---

## §1 Context & success criteria

### 1.1 Context

`deps/README.md` declares three TODOs that are currently unimplemented:

1. "Update `docs` folder to write down this rule"
2. "Write scripts to generate plugin list; under `scripts` folder"
3. "Inject `minimum dpp plugin list` in `lua/dpp_loader.lua`"

`deps/README.md` already reserves two sentinel blocks for generated content:

```
-----------------------------------------------------------------------------
-- AUTO GENERATED PLUGIN LIST
-----------------------------------------------------------------------------

## Minimum loaded

-----------------------------------------------------------------------------
-- AUTO GENERATED PLUGIN LIST END
-----------------------------------------------------------------------------
```

Today, `lua/dpp_loader.lua` keeps two hand-maintained Lua tables (`minimum_deps`, `normal_deps`) that must mirror entries in `deps/dpp.toml`. They drift silently: nothing verifies that every `Shougo/dpp-*` entry in `dpp.toml` is present in those Lua tables, and nothing documents the plugin set for human readers.

The four source-of-truth TOML files under `deps/` are:

| File | Role |
|------|------|
| `deps/dpp.toml` | dpp.vim core + `dpp-ext-*` (eager-loaded bootstrap set) |
| `deps/denops.toml` | denops.vim itself + denops-related plugins |
| `deps/neovim.toml` | general Neovim plugins (lazy / on_event / on_ft) |
| `deps/merge.toml` | `hook_files` + cross-cutting plugin entries |

### 1.2 Success criteria

- **S1** — A script under `scripts/` parses all four `deps/*.toml` files and regenerates, between the sentinel markers in `deps/README.md`, a "Minimum loaded" plugin list derived from `deps/dpp.toml` (the dpp bootstrap set), plus a full per-TOML table covering all four files.
- **S2** — The script writes a generated Lua module `lua/dpp_min_deps.lua` exposing `minimum_deps` and `normal_deps` as Lua tables, derived from `deps/dpp.toml` per the classification rule in §3.2. The file is marked generated (header comment) and is git-tracked.
- **S3** — `lua/dpp_loader.lua` requires the generated module instead of declaring the two tables inline. Startup order is unchanged: the required module is a pure-data table that returns immediately.
- **S4** — A reference doc `docs/references/deps-list.md` is regenerated with a per-plugin table (repo, source TOML, on_ft / on_event / if / depends / external_commands, description). `docs/README.md` index is updated to list it.
- **S5** — A pre-commit hook runs the script and **fails the commit** if any generated file (`deps/README.md`, `lua/dpp_min_deps.lua`, `docs/references/deps-list.md`) differs from what the script would produce — i.e. enforces "generated files are up to date".
- **S6** — The script is invokable as a single Deno command. Per Q2 resolution (revised pass-1 D7), dependencies come from JSR `@std/toml` declared via `scripts/deno.json` import map and resolved from deno's default HTTP cache; the first run after a fresh clone may fetch `@std/toml` from JSR (network required once), and subsequent runs are cached. Exits non-zero on TOML parse error, missing sentinel markers, or classification inconsistency.
- **S7** — No plugin-runtime behavior change: the generated `minimum_deps` / `normal_deps` lists are byte-identical to the hand-maintained lists in `lua/dpp_loader.lua` **as corrected by Phase 0** (the pre-refactor drift-fix commit). `dpp#make_state`'s input is byte-identical before and after the refactor (verified by `:checkhealth dpp`-equivalent smoke test in the plan). The strict sub-claim "`dpp#make_state` input byte-identical" holds regardless because `dpp#make_state` takes `(dpp_cache_home, dpp_denops_script)`, not the Lua lists (verified by Reviewer-C).

### 1.3 Out of scope

- Generating per-plugin README/documentation pages (only the summary reference doc).
- Auto-installing missing plugins (already handled by `dpp-ext-installer` at runtime).
- Migrating any `hook_source` / `hook_add` content out of TOML.
- CI integration beyond the pre-commit hook (CI runner may adopt the same hook later — Q3).

---

## §2 Alternatives considered

| ID | Alternative | Verdict |
|----|-------------|---------|
| A1 | Lua script run via `nvim --headless -l` | Rejected. Reuses nvim runtime, but couples doc generation to a running nvim process (slow, side-effects on `~/.local/state/nvim`). Pre-commit hook latency unacceptable. |
| A2 | Python script via mise | Rejected. Adds a runtime not currently used for config tooling. |
| A3 | POSIX shell + `tomlq` | Rejected. `tomlq`/`yq` availability is fragile across contributor machines; TOML edge cases (multi-line `lua_source = ''' … '''`) handled poorly. |
| A4 | **Deno / TypeScript** (chosen) | deno is already a hard host dep for denops (`init.lua` references `MISE_DATA_DIR/.../deno`). JSR `@std/toml` parses TOML reliably; no new runtime introduced. |
| A5 | In-place rewrite of `dpp_loader.lua` between sentinels | Rejected. Mutating a load-bearing Lua file via regex is fragile; review letter C would block. |
| A6 | **Generated Lua module required by `dpp_loader.lua`** (chosen) | Clean separation: data vs. logic. The generated file is pure data, trivially reviewable, and `dpp_loader.lua` stays hand-maintained. |
| A7 | CI-only enforcement (no pre-commit) | Rejected by user choice. Pre-commit gives faster feedback and works in the no-PR workflow defined in [00-document-management.md](../00-document-management.md) §4. |
| A8 | Generate one mega-doc under `docs/specifications/` | Rejected. Plugin list is reference material, not a normative spec — belongs in `docs/references/`. |

---

## §3 Architecture / Invariants

### 3.1 Component diagram

```
            ┌──────────────────────────┐
            │  deps/{dpp,denops,       │
            │         neovim,merge}.   │
            │         toml             │
            │  (source of truth)       │
            └────────────┬─────────────┘
                         │ read
                         ▼
        ┌────────────────────────────────────────┐
        │  scripts/gen_deps.ts                   │
        │  (deno run; JSR @std/toml via cache)   │
        │  - parse TOML                          │
        │  - classify (§3.2)                     │
        │  - render markdown + lua               │
        └───┬──────────────────┬─────────────┬───┘
            │                  │             │
            ▼                  ▼             ▼
   deps/README.md   lua/dpp_min_deps     docs/references/
   (sentinel block   .lua                deps-list.md
    rewrite)         (full file rewrite) (full file rewrite)
                                            │
                                            ▼
                                   docs/README.md
                                   (index line rewrite)

            ┌──────────────────────────────────────┐
            │  .git/hooks/pre-commit  (or           │
            │  .husky/pre-commit equivalent)        │
            │  - runs `deno run scripts/gen_deps.ts`│
            │  - `git diff --exit-code` on outputs  │
            │  - fail commit if stale               │
            └──────────────────────────────────────┘
                         ▲
                         │ require()
            ┌────────────┴─────────────┐
            │  lua/dpp_loader.lua      │
            │  (no longer declares     │
            │   minimum_deps /         │
            │   normal_deps inline)    │
            └──────────────────────────┘
```

### 3.2 Classification rule (dpp.toml → minimum_deps / normal_deps)

`lua/dpp_loader.lua` currently splits the dpp bootstrap set into two lists:

- `minimum_deps` — `Shougo/dpp.vim`, `Shougo/dpp-ext-lazy`
- `normal_deps` — the rest of `deps/dpp.toml` plus `vim-denops/denops.vim`

To make this data-driven without re-introducing drift, the script derives the split from `deps/dpp.toml` (and `deps/denops.toml` for `denops.vim`) using a **classification predicate**, not a hardcoded list:

| Bucket | Predicate |
|--------|-----------|
| `minimum_deps` | `deps/dpp.toml` entries whose `repo` ∈ `{Shougo/dpp.vim, Shougo/dpp-ext-lazy}` — the set needed to call `dpp#load_state` before denops is up. |
| `normal_deps`  | All remaining `deps/dpp.toml` entries **plus** `vim-denops/denops.vim` from `deps/denops.toml`. |

The "minimum set" predicate is encoded **once** in the script as a constant:

```ts
const MINIMUM_REPOS = new Set(["Shougo/dpp.vim", "Shougo/dpp-ext-lazy"]);
```

This is the only place where the minimum set is named explicitly **in code**; everywhere else (README, generated Lua, reference doc) is derived. (Prose restatements of the set elsewhere in this design — §1.1, §3.2, §5.5 — are illustrative and must not be treated as a second source of truth.) Changing the minimum set is a one-line edit + re-run.

### 3.3 Invariants

- **I1** — `deps/*.toml` files are the **only** source of truth for the plugin list. The script never reads `lua/dpp_loader.lua` or any prior generated output as a *source of plugin data*. Reads of `deps/README.md` to locate sentinel markers (for in-place block replacement per §5.6) are permitted — they do not feed plugin data into the model.
- **I2** — The script is **idempotent**: running it twice produces byte-identical output (deterministic ordering: TOML file order → table insertion order → sorted-by-repo only where explicitly stated in the rendered output).
- **I3** — Generated files are **marked generated** at the top: `<!-- AUTO-GENERATED by scripts/gen_deps.ts — do not edit -->` for markdown, and a Lua header comment for `lua/dpp_min_deps.lua`.
- **I4** — `lua/dpp_min_deps.lua` is a **pure-data module**: only `return { minimum_deps = {...}, normal_deps = {...} }`. No `vim.*` calls, no side effects, no `require` of other modules. Required at top of `dpp_loader.lua` before `initialize_dpp()` runs.
- **I5** — Startup order is unchanged. The `require('dpp_min_deps')` call resolves synchronously via `vim.loader` (already enabled in `init.lua`), executes in microseconds, and returns a table. No new autocmds, no new `User` events.
- **I6** — The pre-commit hook **does not commit on its own**; it only verifies freshness and stages the regenerated files for the user to review. The commit is still the user's.
- **I7** — The generator's deno process relies on deno's default HTTP cache: the first run after a fresh clone may fetch `@std/toml` from JSR (network required once), and subsequent runs are served from the local cache. Per pass-1 D7 decision, `--no-remote` is **not** used — it created a UX hazard on fresh clones (confusing "module not found in cache" error). Note (C5): this applies only to the **generator's** deno process (a one-shot `deno run` for `gen_deps.ts`). denops.vim spawns its own separate deno process at `ensure_denops_plugin()` time (`dpp_loader.lua:82`) with its own dependency surface (`@shougo/dpp-vim`, `@denops/std`, etc.); the generator's cache strategy does not affect denops's deno.
- **I8** — If a sentinel marker is missing from `deps/README.md`, the script **exits non-zero** with a clear error rather than silently appending.

---

## §4 Scope / staging breakdown

The implementation is split into 4 phases (Phase 0 + Phases 1–3), each one commit (per [00-document-management.md](../00-document-management.md) §6.5).

**Revert order (per pass-1 A5 decision):** phases are *sequentially* revertable, not independently. To roll back, revert in reverse order (Phase 3 → 2 → 1 → 0). Reverting an earlier phase while keeping a later phase breaks the build (e.g. reverting Phase 1 while keeping Phase 3's hook makes `deno task gen` fail → every commit is blocked; reverting Phase 0 while keeping Phase 1 makes the generated module's `normal_deps` differ from the now-un-drift-fixed `dpp_loader.lua`). Disable Phase 3's hook (`chmod -x .git/hooks/pre-commit`) *before* reverting any earlier phase.

### Phase 0 — Pre-refactor drift fix in `dpp_loader.lua` (hand-edit)
- Hand-edit `lua/dpp_loader.lua`: add `Shougo/dpp-protocol-http` to `normal_deps` (it is in `deps/dpp.toml:35` but missing from the current hand-maintained list at `dpp_loader.lua:29-36`), and reorder `normal_deps` to match `deps/dpp.toml` file order (toml, local, installer, packspec, protocol-git, protocol-http, denops.vim).
- No generator script is touched in this phase. This is a pure hand-edit that reconciles the existing drift so the Phase 1 generator is purely mechanical and S7 holds literally.
- **Acceptance:** `nvim --headless -c 'qa'` starts without error; `:checkhealth` clean or equivalent smoke (dpp loads, `dpp-protocol-http` is cloned and on rtp). The hand-maintained `normal_deps` now matches what the Phase 1 generator will produce.
- **Rollback:** revert `dpp_loader.lua`.

### Phase 1 — Generator: parse TOML, generate `lua/dpp_min_deps.lua`, rewire `dpp_loader.lua`
- Create `scripts/gen_deps.ts`, `scripts/deno.json`, `scripts/deps_as_json.ts` (parse + classify), `scripts/render_lua.ts`, `scripts/sentinels.ts`.
- `deno task gen` writes `lua/dpp_min_deps.lua` (full file rewrite).
- Edit `lua/dpp_loader.lua`: replace the inline `minimum_deps` / `normal_deps` table declarations with:
  ```lua
  local deps = require("dpp_min_deps")
  assert(deps and deps.minimum_deps and deps.normal_deps,
         "dpp_min_deps missing fields")
  local minimum_deps, normal_deps = deps.minimum_deps, deps.normal_deps
  ```
  (The `assert` is per pass-1 A6 decision — guards the Lua/TS field-name contract.)
- **Acceptance:** `nvim --headless -c 'lua print(vim.inspect(require("dpp_min_deps")))' -c qa` prints the same two lists as the post-Phase-0 hand-maintained tables (S7). `nvim --headless -c 'qa'` starts without error; dpp loads. (Q5 — `@std/toml` multi-line string round-tripping — is a non-issue for this scope since `hook_add`/`hook_source`/`lua_source` are omitted from the reference table per §5.7; no verification needed per pass-1 D6.)
- **Rollback:** revert `dpp_loader.lua`; delete `lua/dpp_min_deps.lua` and `scripts/`.

### Phase 2 — Generate `deps/README.md` block + `docs/references/deps-list.md` + index line
- Add markdown renderers (`scripts/render_readme.ts`, `scripts/render_reference.ts`).
- Rewrite the `AUTO GENERATED PLUGIN LIST … END` block in `deps/README.md` in place.
- Write `docs/references/deps-list.md` (full file rewrite, no in-body date line — per pass-1 A3/D8 decision).
- Add an entry to `docs/README.md` index pointing to `references/deps-list.md` (this line is **not** sentinel-protected — it is added once and stable; the script only ensures it exists, appending if missing).
- **Acceptance:** `deps/README.md` block lists every `deps/dpp.toml` plugin under "Minimum loaded" / "Other dpp-ext"; `docs/references/deps-list.md` contains a row for every `[[plugins]]` across all four TOMLs.
- **Rollback:** revert the three files.

### Phase 3 — Pre-commit hook
- Install `.git/hooks/pre-commit` (via `scripts/install-hooks.sh` that symlinks from `scripts/hooks/pre-commit` so updates flow) that runs `deno task gen`, then `git diff --exit-code -- deps/README.md lua/dpp_min_deps.lua docs/references/deps-list.md docs/README.md`. If non-zero, print instructions and exit 1.
- Document the hook in [docs/specifications/09-dev-workflow.md](../../09-dev-workflow.md) (already created in the design phase; Phase 3 only adds the concrete hook script and installer that the spec references).
- **Acceptance:** with a dirty `deps/dpp.toml` not yet regenerated, `git commit` is blocked; after `deno task gen && git add …`, commit succeeds.
- **Rollback:** `chmod -x .git/hooks/pre-commit` or remove the symlink.
- **Note (D3):** for a solo-maintainer repo with no other contributors, the hook's onboarding cost is marginal and `deno task gen` can be run manually before commit if preferred. The hook is included per the issue's Acceptance criteria (goal 3: generator framework); it can be disabled without affecting Phases 0–2.

---

## §5 Implementation detail — `scripts/gen_deps.ts`

### 5.1 Module layout

```
scripts/
├── deno.json                       # {
│                                   #   "tasks": {
│                                   #     "gen": "deno run --allow-read=. --allow-write=deps/README.md,lua/dpp_min_deps.lua,docs/references/deps-list.md,docs/README.md scripts/gen_deps.ts"
│                                   #   },
│                                   #   "imports": { "@std/toml": "jsr:@std/toml@^1" }
│                                   # }
├── gen_deps.ts                     # entrypoint: orchestrate parse → render → write
├── deps_as_json.ts                 # parse TOML files; classify; return typed model
├── render_lua.ts                   # model → lua/dpp_min_deps.lua source
├── render_readme.ts                # model → deps/README.md sentinel-block content
├── render_reference.ts             # model → docs/references/deps-list.md
└── sentinels.ts                    # read file, replace between markers, assert markers exist
```

Per Q2 resolution, `@std/toml` is declared in `deno.json` `imports` (deno's import map mechanism). Per pass-1 D7 decision, `--no-remote` is **not** used — deno's default HTTP cache is relied upon (first run after fresh clone may fetch `@std/toml` from JSR; subsequent runs are cached). An optional `deno cache scripts/gen_deps.ts` can pre-populate the cache for strict offline-first runs.

### 5.2 Type model

```ts
interface PluginEntry {
  repo: string;
  description?: string;
  rtp?: string;
  if_expr?: string;        // `if` field
  on_ft?: string[] | string;
  on_event?: string[] | string;
  on_source?: string[] | string;
  depends?: string[] | string;
  external_commands?: string[] | string;
  hook_add?: string;
  hook_source?: string;
  lua_source?: string;
  extAttrs?: Record<string, unknown>;
  source_toml: "dpp" | "denops" | "neovim" | "merge";
}

interface DepsModel {
  plugins: PluginEntry[];                  // insertion order across all 4 files
  by_toml: Record<SourceToml, PluginEntry[]>;
  minimum_deps: string[];                  // repos, dpp.toml order
  normal_deps: string[];                   // repos, dpp.toml order + denops.vim last
}
```

### 5.3 TOML parsing

- Use JSR `@std/toml`'s `parse` (or `@std/toml/parse`). Multi-line `''' … '''` strings (`lua_source`, `hook_source`) are valid TOML basic multi-line strings per the spec dpp-ext-toml accepts; confirm `@std/toml` preserves embedded newlines (Q5 — verify in Phase 1).
- Each `[[plugins]]` array element becomes a `PluginEntry`. `source_toml` is set by the file path.

### 5.4 Classification implementation

```ts
const MINIMUM_REPOS = new Set(["Shougo/dpp.vim", "Shougo/dpp-ext-lazy"]);

function classify(model: DepsModel): void {
  const dppEntries = model.by_toml.dpp;
  model.minimum_deps = dppEntries.filter(p => MINIMUM_REPOS.has(p.repo)).map(p => p.repo);
  model.normal_deps  = dppEntries.filter(p => !MINIMUM_REPOS.has(p.repo)).map(p => p.repo);
  const denopsVim = model.by_toml.denops.find(p => p.repo === "vim-denops/denops.vim");
  if (denopsVim) model.normal_deps.push(denopsVim.repo);

  // Q1: MINIMUM_REPOS must be fully present in dpp.toml.
  if (model.minimum_deps.length !== MINIMUM_REPOS.size) {
    throw new Error(`dpp.toml is missing one of MINIMUM_REPOS: ${[...MINIMUM_REPOS].join(", ")}`);
  }

  // Q7: no repo classified twice, no dpp.toml repo unclassified.
  // (Trimmed per pass-1 D5: the complementary predicate already guarantees
  //  every dppEntries item lands in exactly one bucket; this 3-line check
  //  only guards against denops.vim being added to dpp.toml or duplicate
  //  [[plugins]] entries.)
  const all = [...model.minimum_deps, ...model.normal_deps];
  if (new Set(all).size !== all.length) {
    throw new Error(`repo classified twice in minimum_deps/normal_deps: ${all.join(", ")}`);
  }
}
```

The two assertions guard against: (1) accidental removal of a bootstrap plugin from `dpp.toml` (startup would break silently), and (2) a repo appearing twice — either a duplicate `[[plugins]]` entry in `dpp.toml`, or `vim-denops/denops.vim` being added to `dpp.toml` while also injected from `denops.toml`. Per pass-1 D5, the full "every repo classified" + "size mismatch" checks were trimmed because the complementary predicate (`filter(MINIMUM_REPOS.has)` / `filter(!MINIMUM_REPOS.has)`) already guarantees coverage by construction.

### 5.5 `lua/dpp_min_deps.lua` rendering

Output shape (exact bytes matter for idempotency — use stable 2-space indent, single quotes, no trailing whitespace):

```lua
-- AUTO-GENERATED by scripts/gen_deps.ts — do not edit by hand.
-- Source: deps/{dpp,denops,neovim,merge}.toml
-- Regenerate: `deno task gen`

local M = {}

M.minimum_deps = {
  'Shougo/dpp.vim',
  'Shougo/dpp-ext-lazy',
}

M.normal_deps = {
  'Shougo/dpp-ext-toml',
  'Shougo/dpp-ext-local',
  'Shougo/dpp-ext-installer',
  'Shougo/dpp-ext-packspec',
  'Shougo/dpp-protocol-git',
  'Shougo/dpp-protocol-http',
  'vim-denops/denops.vim',
}

return M
```

### 5.6 `deps/README.md` sentinel-block rendering

The script reads `deps/README.md`, asserts both sentinel lines exist, and replaces the content **between** (not including) the markers. Rendered content:

```markdown
## Minimum loaded

| repo | description |
|------|-------------|
| `Shougo/dpp.vim` | Dark powered plugin manager for Vim/Neovim |
| `Shougo/dpp-ext-lazy` | _(no description in toml)_ |

## Normal dpp deps (loaded before denops ready)

| repo | description |
|------|-------------|
| `Shougo/dpp-ext-toml` | … |
| … |

## Other TOMLs

- `deps/denops.toml`: N plugins — see [docs/references/deps-list.md](../docs/references/deps-list.md) for the full table.
- `deps/neovim.toml`: N plugins
- `deps/merge.toml`: N plugins
```

### 5.7 `docs/references/deps-list.md` rendering

Full per-plugin table, grouped by source TOML. Columns: `repo`, `description`, `if`, `on_ft`, `on_event`, `on_source`, `depends`, `external_commands`, `rtp`. Long fields (`hook_add`, `hook_source`, `lua_source`) are **omitted** from the table (they are code, not docs) and replaced with a `✓` marker column (`has_hooks`).

Per Q6 resolution, the filename carries **no** `YYYY-MM-DD-` prefix (the file is regenerated constantly, so a fixed name is more practical). Per pass-1 A3/D8 decision, there is **no in-body `Last updated:` date line** either — a system-clock-derived date would violate I2/H5 idempotency (the date changes even when `deps/*.toml` is unchanged). The file's last-changed date is available via `git log docs/references/deps-list.md`; no redundant in-body date is needed.

The doc begins with the standard marker header (per [09-dev-workflow.md](../09-dev-workflow.md) R8):

```markdown
<!-- AUTO-GENERATED by scripts/gen_deps.ts — do not edit -->
```

Footer of the doc states:

> Auto-generated by `scripts/gen_deps.ts` from `deps/*.toml`. Do not edit by hand. Regenerate via `deno task gen`; the pre-commit hook will refuse commits with stale output.

### 5.8 `sentinels.ts` API

```ts
function replaceBetween(
  filePath: string,
  startMarker: RegExp,
  endMarker: RegExp,
  newContent: string,
  opts: { preserveMarkers: true },
): void
```

- Throws if either marker is absent.
- Preserves the marker lines themselves.
- Ensures exactly one blank line between marker and content (idempotency).

### 5.9 Exit codes

| Code | Cause |
|------|-------|
| 0 | All outputs written and unchanged-or-updated |
| 2 | TOML parse error |
| 3 | Missing sentinel marker in `deps/README.md` |
| 4 | `MINIMUM_REPOS` not satisfied by `dpp.toml` (Q1 assertion) |
| 5 | I/O error writing outputs |
| 6 | Classification inconsistency: a repo is duplicated across `minimum_deps` / `normal_deps` (Q7 assertion) |

Note (per pass-1 C8): exits 4 and 6 are **generation-time guards**. The script runs at pre-commit time, not at Neovim startup. A classification failure refuses to write outputs and blocks the commit; the existing generated module on disk continues to be `require()`d at the top of `dpp_loader.lua` and Neovim starts unchanged. The whole purpose of exits 4 and 6 is to prevent classification failures from reaching runtime (and thus from becoming CRITICAL startup-breaking outcomes).

---

## §6 Pre-commit hook detail

The hook is the concrete instance of rules H1–H5 in [09-dev-workflow.md](../09-dev-workflow.md). The tracked hook script lives at `scripts/hooks/pre-commit` and is symlinked into `.git/hooks/pre-commit` by `scripts/install-hooks.sh` (so hook edits flow without re-installation):

`scripts/hooks/pre-commit`:

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

The hook **does not** auto-stage — the user reviews the diff (per I6 and H3). When a second generator is added, the umbrella `gen` task (per [09-dev-workflow.md](../09-dev-workflow.md) §4) chains all `gen-*` tasks so this hook stays a single `deno task gen` call. Per pass-1 D7 decision, the `deno task cache` hint was removed — deno's default HTTP cache handles first-run fetching transparently, so no separate onboarding step is needed.

---

## §7 Open questions

### Resolved

- **Q1** — **RESOLVED (2026-07-13).** Issue raised retroactively as [docs/issues/2026-07-13-deps-docs-auto-gen.md](../../issues/2026-07-13-deps-docs-auto-gen.md). The `issue → design → review → plan → result-log → issue (closed)` lifecycle per [00-document-management.md](../00-document-management.md) §4 is now traceable via the shared `deps-docs-auto-gen` slug. The trigger being a README TODO rather than a bug does not exempt it from the lifecycle.
- **Q2** — **RESOLVED (2026-07-13, revised pass-1).** Use JSR `@std/toml` declared via `scripts/deno.json` `imports` (deno's import map). No vendoring. Originally the cache was pre-populated via a separate `deno task cache` step and `--no-remote` was used at run time; however pass-1 finding D7 showed this creates a UX hazard on fresh clones (confusing "module not found in cache" error). Per D7 decision, `--no-remote` was **dropped** — deno's default HTTP cache is relied upon (first run after fresh clone may fetch `@std/toml`; subsequent runs are cached). The separate `deno task cache` onboarding step was removed. Reflected in I7, S6, §5.1. Codified as R6/R7/R8/R9 in [09-dev-workflow.md](../09-dev-workflow.md) (slimmed per D4).
- **Q4** — **RESOLVED (2026-07-13, revised pass-1).** Developer workflow (pre-commit hook, `deno task gen`) lives in a new normative spec: [docs/specifications/09-dev-workflow.md](../09-dev-workflow.md). Per pass-1 D4 decision (a), the spec was slimmed to 5 genuinely cross-cutting rules (R6, R7, R8, R9, H5) + tasks registry + hook installation mechanism. The per-generator rules (R1–R5, R10, G1–G2, G4, H1–H4) are carried as invariants I1–I8 in this design and will be re-elevated into the spec only when a second generator proves them genuinely cross-cutting. The `docs/README.md` index lists the new spec.
- **Q6** — **RESOLVED (2026-07-13, revised pass-1).** No date prefix in the filename — `docs/references/deps-list.md` stays fixed. Originally the [00-document-management.md](../00-document-management.md) §6.7 "prefix if content changes over time" rule was satisfied by embedding `<!-- Last updated: YYYY-MM-DD -->` in the doc body; however pass-1 finding A3/D8 showed that a system-clock-derived date line violates I2/H5 idempotency (date changes even when inputs are unchanged). The date line was therefore **dropped** (A3/D8 decision (a)). The file's last-changed date is available via `git log docs/references/deps-list.md`; no redundant in-body date is needed. Reflected in §5.7. G3 was removed from [09-dev-workflow.md](../09-dev-workflow.md).
- **Q7** — **RESOLVED (2026-07-13, revised pass-1).** Yes — the script asserts that no repo is duplicated across `minimum_deps` / `normal_deps` (e.g. `denops.vim` being added to `dpp.toml` while also injected from `denops.toml`, or a duplicate `[[plugins]]` entry). Failure exits with code 6. Per pass-1 D5, the full "every repo classified" + "size mismatch" checks were trimmed (the complementary predicate `filter(MINIMUM_REPOS.has)` / `filter(!MINIMUM_REPOS.has)` already guarantees coverage by construction); only the duplicate-detection 3-line check remains. Reflected in §5.4 and §5.9.

### Still open

- **Q3** — Should the same `deno task gen` check also run in CI (once CI is set up) as a second line of defense, or is the pre-commit hook sufficient given the no-PR workflow?
- **Q5** — Confirm `@std/toml` preserves embedded newlines in `''' … '''` basic multi-line strings exactly (significant for `lua_source` round-tripping if we ever render hooks). To be verified in Phase 1 acceptance. (Reviewer-D finding D6 notes this is a non-issue for the current scope since hooks are omitted from the reference table — only a `✓` marker is rendered. Q5 only matters for a future "render hooks" feature that is out of scope.)

---

## §8 Revision decisions (pass 1 → pass 2)

Recording author decisions on pass-1 blocking findings from [the aggregate](../../reviews/2026-07-13-deps-docs-auto-gen-review-pass1.md). All 5 blocking findings are resolved; non-blocking findings are applied in the same revision pass.

| Finding | Severity | Decision | Status |
|---------|----------|----------|--------|
| **A1** — Lua require path resolution | CRITICAL | **`lua/dpp_min_deps.lua` + `require("dpp_min_deps")`.** No dot in the module name → resolves directly to `lua/dpp_min_deps.lua`. The "generated" signal is carried by the `-- AUTO-GENERATED by scripts/gen_deps.ts — do not edit by hand.` header comment (per [09-dev-workflow.md](../09-dev-workflow.md) R8), not the filename. | ✅ Applied: S2, S5, I3, I4, I5, §3.1, §4 Phase 1, §4 Phase 3, §5.1, §5.5, §6, [09-dev-workflow.md](../09-dev-workflow.md) §4. |
| **D1** — scope: check-only vs full generator | HIGH | **Full generator.** Issue body widened to explicitly include goals 2 (human-readable plugin docs) and 3 (generator framework). See [issue](../../issues/2026-07-13-deps-docs-auto-gen.md) Problem + Acceptance criteria. The narrower check-only alternative was rejected because it would solve goal 1 only. | ✅ Applied: issue body updated. |
| **A2 / C2 / D1-cross** — generated `normal_deps` drift vs S7 | HIGH | **(i) Split drift fix into a pre-refactor commit.** Added Phase 0: hand-edit `dpp_loader.lua` to add `dpp-protocol-http` + reorder to TOML order, smoke-test. Phase 1 generator then produces lists byte-identical to the post-Phase-0 hand-maintained tables, so S7 holds literally. Reviewer-C verified the strict sub-claim (`dpp#make_state` input byte-identical) already holds — the change is in `load_plugins(normal_deps)` only, and Phase 0 reconciles that too. | ✅ Applied: §4 Phase 0 added, S7 updated, §4 Phase 1 Acceptance references post-Phase-0 tables. C4 (denops.vim position) folded in. |
| **A3 / D8** — `Last updated:` date line breaks I2/H5 | HIGH/MEDIUM | **(a) Drop the in-body date line entirely.** `git log docs/references/deps-list.md` records the last-changed date; no redundant in-body date is needed. G3 removed from [09-dev-workflow.md](../09-dev-workflow.md); §5.7 and Q6 resolution updated. | ✅ Applied: §5.7 rewritten (no date line), G3 removed from spec, Q6 resolution revised. |
| **D4** — `09-dev-workflow.md` 19 rules premature | HIGH | **(a) Slim to ~5 genuinely cross-cutting rules.** [09-dev-workflow.md](../09-dev-workflow.md) now contains only R6 (idempotent), R7 (never read prior output as data), R8 (marker header), R9 (documented exit codes), H5 (no-op on unchanged inputs). The deferred rules (R1–R5, R10, G1–G2, G4, H1–H4) are carried as invariants I1–I8 in this design; they will be re-elevated into the spec only when a second generator proves them genuinely cross-cutting. G3 was removed entirely (A3/D8). | ✅ Applied: [09-dev-workflow.md](../09-dev-workflow.md) rewritten (5 rules + deferred-rules note). |

### Non-blocking findings applied in this revision

| ID | Severity | How applied |
|----|----------|-------------|
| A4 | MEDIUM | I1 scoped to "never reads as *source of plugin data*; reads to locate sentinel markers are permitted". |
| A5 | MEDIUM | §4 revert order stated explicitly: sequentially revertable (Phase 3 → 2 → 1 → 0); disable Phase 3 hook before reverting earlier phases. |
| A6 | LOW | `assert(deps and deps.minimum_deps and deps.normal_deps, "dpp_min_deps missing fields")` added to §4 Phase 1 `dpp_loader.lua` rewire. |
| A7 | LOW | §3.2 `MINIMUM_REPOS` "encoded once" claim scoped to "in code"; prose restatements noted as illustrative. |
| C4 | MEDIUM | Folded into A2/C2 fix (Phase 0 reconciles denops.vim position + surrounding order). |
| C5 | LOW | I7 updated: `--no-remote` scope note added — applies only to generator's deno, not denops's separate deno process. |
| C8 | LOW | §5.9 note added: exits 4 and 6 are generation-time guards preventing classification failures from reaching runtime. |
| D2 | MEDIUM | Phase 1 (skeleton, JSON-only) merged into Phase 1 (generator + rewire). 4 phases total (Phase 0 + 1–3), down from 5. |
| D3 | MEDIUM | Phase 3 note added: hook is included per issue Acceptance (goal 3) but can be disabled without affecting Phases 0–2; manual `deno task gen` is the fallback. |
| D5 | LOW | §5.4 Q7 assertion trimmed from 20 lines to 3 (the complementary predicate already guarantees coverage; only duplicate detection remains). |
| D6 | LOW | Q5 noted as non-issue for current scope (hooks omitted from reference table); Q5/Q3 left deferred. |
| D7 | MEDIUM | `--no-remote` dropped from `gen` task and I7; deno's default HTTP cache used instead. Separate `deno task cache` onboarding step removed. §6 hook cache hint removed. |
