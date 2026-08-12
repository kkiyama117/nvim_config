# omp prompt — P4: convert lua/hooks/*.dpp to rvpm per-plugin hooks

You are working in `~/.config/nvim` (a git repo, branch `temp`).

Part of the dpp.vim → rvpm migration. Confirm `doc/agents/reports/rvpm-p1.md`,
`rvpm-p2.md`, and `rvpm-p3.md` all say `STATUS: PASS` before starting.

## Context — read these, then stop reading

1. `doc/agents/plan-rvpm-bootloader.md` §5.2 (hook mapping), §2.5 (the
   `vim-gin` denops-readiness idiom — you will need it).
2. `doc/agents/reports/rvpm-p3.md` — the "Hooks handoff for P4" table tells
   you which dpp hook file belongs to which plugin.
3. The `.dpp` files themselves, as input to your conversion script.

## Goal

Convert 35 `lua/hooks/*.dpp` files into rvpm per-plugin hook files under
`rvpm/plugins/github.com/<owner>/<repo>/`, driven by a re-runnable script
(`scripts/dpp-hooks2rvpm.<ext>`).

## Input format — already surveyed, do not re-survey

`.dpp` files are fold-marker sections. Section counts across all 35 files:

| Section | n | Format |
|---|---|---|
| `-- lua_source {{{` … `-- }}}` | 29 | Lua |
| `-- lua_add {{{` … `-- }}}` | 26 | Lua |
| `" hook_source {{{` … `" }}}` | 2 | Vim script, with `lua << EOF` heredocs |
| `" hook_add {{{` … `" }}}` | 1 | Vim script, with `lua << EOF` heredocs |

The three Vim-script sections live in exactly two files, and those same two
files are the `[[multiple_hooks]]` entries from P3:

- `lua/hooks/shared/ddc_skkeleton.dpp` → shared by `ddc.vim`, `skkeleton`
- `lua/hooks/shared/ddu_gin.dpp` → shared by `ddu.vim`, `vim-gin`

There are **no** `post_source` sections anywhere.

## Output mapping

| dpp section | rvpm file | Timing (identical semantics) |
|---|---|---|
| `lua_add` / `hook_add` | `rvpm/plugins/github.com/<owner>/<repo>/init.lua` | loader phase 4, before rtp is touched |
| `lua_source` / `hook_source` | `…/before.lua` | rtp appended, `plugin/*` not yet sourced — same as dpp's `hook_source` |
| *(none currently)* | `…/after.lua` | after `plugin/*`; use only where a block genuinely needs the plugin live |

The `lua_source` → `before.lua` mapping is 1:1 in timing: dpp adds the rtp
entry, runs `hook_source`, then sources `plugin/`. rvpm does the same. Move a
block to `after.lua` **only** if it demonstrably needs `plugin/*` to have run,
and say which blocks you moved and why.

## The two hard cases

**1. Shared hooks (`[[multiple_hooks]]`).** rvpm has no equivalent. Resolve
by extracting the body into a shared Lua module in this repo, then having
each plugin's hook require it:

```lua
-- rvpm/plugins/github.com/Shougo/ddc.vim/before.lua
require("hooks.shared.ddc_skkeleton").setup()
```

Put the modules at `lua/hooks/shared/*.lua` (this repo is on `runtimepath`,
so `require("hooks.shared.x")` resolves). Convert the `lua << EOF` heredoc
bodies to plain Lua; the surrounding Vim script is usually just the heredoc
wrapper — if it contains real Vim script, keep it as `vim.cmd([[...]])`.

**2. denops plugins.** A hook that calls into a denops plugin's functions must
not assume the plugin is live. Use the readiness idiom from the design doc
§2.5 (`lambdalisue/vim-gin/after.lua` in the rvpm author's own dotfiles):

```lua
local function setup() ... end
if vim.fn.exists("*denops#plugin#is_loaded") == 1
    and vim.fn["denops#plugin#is_loaded"]("gin") == 1 then
  setup()
else
  vim.api.nvim_create_autocmd("User", {
    pattern = "DenopsPluginPost:gin", once = true, callback = setup,
  })
end
```

Apply it where the current `.dpp` relied on dpp's `denops_wait` or on being
sourced after `DenopsReady`. List every hook you applied it to.

## Hard constraints

| Must not | Why |
|---|---|
| Delete or edit `lua/hooks/*.dpp` | they are the input and the fallback until P7 |
| Modify `deps/*.toml` | still the dpp fallback until P7 |
| Modify `init.lua` | P5 |
| Rewrite hook logic while converting | this is a **translation**, not a refactor. Behaviour must be preserved; note anything you had to change |
| Silently drop a section | every one of the 58 sections must land somewhere or be listed as dropped with a reason |
| `git commit` / `git push` | Claude reviews the working tree first |

New Lua files must pass whatever formatter the repo uses (`stylua` if
configured — check for `.stylua.toml` before assuming).

## Acceptance criteria

| # | Check |
|---|---|
| 1 | All 58 sections accounted for: emitted to `init.lua` / `before.lua` / `after.lua`, or listed as dropped with a reason |
| 2 | Every generated file is valid Lua: `luajit -bl <file> /dev/null` or `nvim -l <file>` parses without syntax error (do not *execute* side effects — a `luac`/`loadfile` syntax check is enough) |
| 3 | Both `[[multiple_hooks]]` cases resolved with a shared module, and both consuming plugins reference it |
| 4 | `RVPM_NO_AUTOUPDATE=1 rvpm doctor` still clean after the hooks exist |
| 5 | The conversion script re-runs and produces byte-identical output |
| 6 | Every hook touching a denops plugin either uses the readiness idiom or is justified as not needing it |

## Deliverable report

`doc/agents/reports/rvpm-p4.md`, created first with `TODO` markers:

```markdown
# P4 report — .dpp hooks → rvpm per-plugin hooks

STATUS: PASS | FAIL | BLOCKED | BUDGET EXHAUSTED

## Counts
58 sections in / emitted per target file / dropped (with reasons)

## Files created
tree of rvpm/plugins/... with section origin per file

## Shared hooks
how ddc_skkeleton and ddu_gin were resolved; the module API

## denops readiness idiom
table: hook, denops plugin name, why it needed it (or why not)

## Blocks moved to after.lua
table: hook, reason it needs plugin/* sourced

## Translation deviations
anything that is not a literal translation, and why

## Acceptance
| # | check | result |

## Surprises
contradictions with the design doc, with section numbers

## Next
what P5 needs
```

## Anti-loop rules

1. Report file first, `TODO`-filled.
2. Budget 60 tool calls; at 40 write state into the report; at 60 stop with
   `STATUS: BUDGET EXHAUSTED`.
3. No file read twice — the script reads the `.dpp` files, you do not.
4. Three failed attempts on one sub-question → `## Blocked`, move on.
5. Write the script early. Do not read 35 hook files by hand first; sample
   three, write the parser, iterate on its output.

## Definition of done

58 sections accounted for, all generated Lua parses, both shared-hook cases
resolved, `rvpm doctor` clean, converter deterministic. Then stop — do not
start P5.
