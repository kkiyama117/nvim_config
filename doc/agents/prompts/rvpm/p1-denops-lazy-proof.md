# omp prompt — P1: prove lazy denops plugins load under rvpm

You are working in `~/.config/nvim` (a git repo, branch `temp`).

This is the **gate phase** of a dpp.vim → rvpm migration. If lazy denops
plugins cannot be made to register, the entire migration is void and we stay
on dpp. Your job is to settle that question with one decisive experiment, not
to migrate anything.

## Context — read these, then stop reading

1. `doc/agents/plan-rvpm-bootloader.md` — the design doc. §2.4 (rvpm's denops
   handling), §2.6 (what is already verified), §6 (risks). **This is the
   source of truth. Do not re-derive what it already records.**
2. `~/.cache/rvpm/nvim-rvpm/plugins/loader.lua` — a real generated loader
   (38 lines) from the isolated test appname. Read `load_lazy` in it.

That is the whole reading list. Everything else you need is below.

## What is already established (do not re-verify)

- rvpm 3.44.0 is at `~/.local/bin/rvpm`.
- rvpm's generated `load_lazy` helper calls
  `denops#plugin#load(name, main_script)` followed by
  `denops#plugin#wait(name, {silent=1})` for every denops plugin it detected
  at generate time (`denops/<name>/main.{ts,js}`). Source: rvpm
  `src/loader.rs`, and it is present verbatim in the generated loader above.
- An isolated test appname already exists and works:
  `RVPM_APPNAME=nvim-rvpm`, config `~/.config/rvpm/nvim-rvpm/config.toml`,
  cache `~/.cache/rvpm/nvim-rvpm/`. It currently holds `yukimemi/rvpm.nvim`.
- `:Rvpm`, `:RvpmAddCursor`, `require("rvpm")`, and `:checkhealth rvpm` all
  work in that environment.

**The open question is only this:** does that mechanism actually register a
lazy denops plugin at runtime, when the trigger fires *after* `DenopsReady`
has already passed and `denops#plugin#discover()` has already run?

## Hard constraints

| Must not | Why |
|---|---|
| Touch `~/.config/rvpm/nvim/` (no appname suffix) | that is the real config; P5 owns it |
| Modify `~/.config/nvim/init.lua` | P5 owns it |
| Modify `deps/*.toml`, `lua/hooks/*`, `denops/dpp.ts` | P3/P4/P7 own them |
| Run `rvpm init --write` | it edits the real `init.lua` |
| Delete `~/programs/nvim_plugins/my_nvim_bootloader` | P6 owns it; `init.lua:76` still requires it |
| `git commit` / `git push` | Claude reviews the working tree first |

Everything you create lives under `RVPM_APPNAME=nvim-rvpm` or in
`doc/agents/reports/`.

## Environment rules

```sh
export RVPM_NO_AUTOUPDATE=1     # else rvpm self-updates its binary every run
export RVPM_APPNAME=nvim-rvpm   # isolation
```

`rvpm sync` opens a progress TUI and **fails on a non-TTY** with
`Error: No such device or address (os error 6)`. Always run it through a pty:

```sh
script -qec "rvpm sync" /dev/null
```

`deno` must be on PATH for denops. If `command -v deno` fails, use
`~/.local/share/mise/installs/deno/latest/bin/deno` and set
`vim.g["denops#deno"]` in the test init (the real `init.lua` has the same
fallback — copy that pattern).

## The experiment

Add these four plugins to `~/.config/rvpm/nvim-rvpm/config.toml`, keeping
`rvpm.nvim`. The triggers are chosen to fire **late**, well after
`DenopsReady`:

| Plugin | rvpm config | denops name | Why this one |
|---|---|---|---|
| `vim-denops/denops.vim` | eager (no `on_*`) | — | the host |
| `vim-skk/skkeleton` | `on_map` `<C-j>` (modes `i`, `c`, `t`, `n`) | `skkeleton` | the exact plugin that made this risky; today it has **no** `on_*` in `deps/coding.toml` and relies on dpp-ext-lazy `FuncUndefined` |
| `Shougo/ddu.vim` | `on_cmd = ["Ddu"]`, `depends = ["denops.vim"]` | `ddu` | latest possible trigger; deliberately *not* the real config's `on_event = "DenopsReady"`, which would prove nothing |
| `Shougo/ddc.vim` | `on_event = ["InsertEnter"]`, `depends = ["denops.vim"]` | `ddc` | a second, different trigger kind |

Then sync, and drive Neovim with a scratch init (put it in a temp dir, not in
the repo) shaped like the P5 target:

```lua
vim.loader.enable()
local loader = vim.fn.expand("~/.cache/rvpm/nvim-rvpm/plugins/loader.lua")
if vim.uv.fs_stat(loader) then dofile(loader) end
```

## Acceptance criteria

For **each** of `skkeleton`, `ddu`, `ddc`, assert all four, in order, in one
Neovim session:

| # | Assertion | Meaning |
|---|---|---|
| 1 | denops server reaches `running` (`denops#server#status()`) and `DenopsReady` has fired | discovery has already happened |
| 2 | before the trigger: `_G["rvpm_loaded_<plugin>"]` is `nil` **and** `denops#plugin#is_loaded("<denops name>") == 0` | genuinely lazy, genuinely unregistered |
| 3 | fire the trigger (feed `<C-j>`, run `:Ddu`, enter insert mode) | — |
| 4 | after the trigger: `_G["rvpm_loaded_<plugin>"] == true` **and** `denops#plugin#is_loaded("<denops name>") == 1` | **this is the result that matters** |

Assertion 4 failing for any plugin = P1 FAILED = migration aborted. Say so
plainly; do not try to invent workarounds beyond the two below.

If assertion 4 fails, before declaring failure try exactly these two, in
order, and record the outcome of each:

1. `merge = true` with `lazy = true` (does the rtp view layout matter?)
2. a per-plugin `after.lua` hook that calls
   `vim.fn["denops#plugin#load"](name, main_script)` itself

Nothing else. Do not go source-diving into denops.vim internals — that is the
loop that burned the last session.

## Deliverable

`doc/agents/reports/rvpm-p1.md`, created **first** with headings and `TODO`
markers, updated as you work:

```markdown
# P1 report — lazy denops under rvpm

STATUS: PASS | FAIL | BLOCKED | BUDGET EXHAUSTED

## Verdict
One paragraph. Does the migration proceed?

## Environment
rvpm version, deno version, nvim version, appname, exact config.toml used

## Results
| Plugin | trigger | pre `rvpm_loaded_` | pre `is_loaded` | post `rvpm_loaded_` | post `is_loaded` | verdict |

## How it was driven
The exact nvim invocation and assertion script, copy-pasteable.

## Surprises
Anything that contradicts doc/agents/plan-rvpm-bootloader.md, with the
section number to correct.

## Blocked
Sub-questions abandoned after 3 attempts, with what was tried.

## Next
What P2 should know.
```

Also leave `~/.config/rvpm/nvim-rvpm/config.toml` and your assertion script in
place — Claude re-runs them.

## Anti-loop rules

1. Report file first, `TODO`-filled, before any experiment.
2. Budget 60 tool calls. At 40, write current state into the report. At 60,
   stop with `STATUS: BUDGET EXHAUSTED`.
3. Read no file twice. If you need it again, it belongs in the report.
4. Three failed attempts at one sub-question → write it under `## Blocked`,
   move on.
5. One decisive experiment beats five reads of plugin source. You are not
   here to understand denops; you are here to observe whether a number is 0
   or 1.

## Definition of done

`doc/agents/reports/rvpm-p1.md` exists, `STATUS:` is set, the results table
has real values for all three plugins, and the assertion script re-runs
cleanly. Then stop — do not start P2.
