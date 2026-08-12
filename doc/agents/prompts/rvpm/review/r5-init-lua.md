# Claude review — P5: init.lua switched to rvpm

Read `doc/agents/prompts/rvpm/review/README.md` first. Then this.

**This is the phase that changed how the user's Neovim starts.** Review it
harder than the others. A defect here is felt on every launch.

## What P5 was supposed to do

Replace the dpp bootstrap in `init.lua` with rvpm's guarded `dofile`, run the
first real sync of 137 plugins, measure startup, and prove rollback works.
Design doc §4.1 (per-block fate), §4.2 (cold start), §4.3 (why the rtp surgery
goes).

Target shape (matches the rvpm author's own, design doc §2.5):

```lua
vim.loader.enable()
local loader = vim.fn.expand("~/.cache/rvpm/nvim/plugins/loader.lua")
if vim.uv.fs_stat(loader) then
  dofile(loader)
end
```

## Read

1. `doc/agents/reports/rvpm-p5.md`
2. `git diff init.lua` — the actual change, before the report's description
3. `doc/agents/prompts/rvpm/p5-init-lua.md` and design doc §4.1–§4.3
4. `doc/agents/reports/rvpm-review-log.md`

## The traps

| # | Trap | How to detect |
|---|---|---|
| 1 | **Rollback not actually tested.** Criterion 6 was "checkout the old `init.lua`, confirm dpp still starts, re-apply". Easy to claim, tedious to do | The report must show the commands and both outcomes. If it says "rollback is possible" rather than "rollback was performed at <time>, output was", treat it as unmet |
| 2 | **The rtp surgery survived** | grep `init.lua` for `packpath`, `VIMRUNTIME`, `SourcePre`. All must be gone. Leaving them is not harmless: the loader `dofile`s Lua, which never fires `SourcePre`, so the restore may never run |
| 3 | **Startup numbers not comparable** | Both sides must use the same method. A `--startuptime` for rvpm against a remembered number for dpp is not a measurement. If the dpp baseline was not captured before the switch, say so — it can still be captured on the rollback branch |
| 4 | **`rvpm init --write` used** | It appends its own `dofile` line. Check for a duplicated or rvpm-authored line in `init.lua` |
| 5 | **The dpp cache was deleted** | `ls ~/.cache/nvim/dpp/` must still exist. It is the rollback path until P7 |
| 6 | **Merge collisions ignored** | The first sync prints a `first-wins` summary for `merge = true` path collisions (design doc D7). With 137 plugins this is where a silently wrong file comes from. The report must contain the summary, not a claim that it was fine |
| 7 | **Env moved to the wrong place** | `NVIM_CONFIG_HOME` / `NVIM_CACHE_HOME` / `vimrc#augroup` stay in `init.lua`; the deno fallback moves to `rvpm/plugins/github.com/vim-denops/denops.vim/before.lua`. Check the deno fallback still exists *somewhere* — if it was dropped, a machine with `deno` off PATH silently loses denops |
| 8 | **denops assertions weakened** | P1's assertions must be re-run against the **real** config, not asserted by analogy. `is_loaded == 1` for skkeleton / ddu / ddc |
| 9 | **Plugin count silently short** | `rvpm doctor` `cloned plugins — N/N`: N must match the emitted count from P3. A failed clone that only appeared in sync output is a finding |

## Reproduce

```sh
export RVPM_NO_AUTOUPDATE=1
git diff init.lua
grep -nE 'packpath|VIMRUNTIME|SourcePre|my_nvim_bootloader' init.lua   # expect nothing
rvpm doctor
nvim --headless -c 'qa!' ; echo "exit=$?"
nvim --headless --startuptime /tmp/rvpm-startup.log -c 'qa!' ; tail -3 /tmp/rvpm-startup.log
ls ~/.cache/nvim/dpp/ >/dev/null && echo "dpp cache intact"
```

Then re-run P1's denops assertions against the real config, and open a real
file interactively-ish (`nvim --headless -c 'e lua/vimrc/options.lua' -c 'qa!'`)
to check nothing errors on a normal buffer.

## Acceptance to confirm

| # | Criterion |
|---|---|
| 1 | `nvim --headless -c 'qa!'` exits 0, clean stderr |
| 2 | `rvpm doctor`: `cloned plugins N/N`, `init.lua loader hook — ok` |
| 3 | denops up; skkeleton / ddu / ddc register in the real config |
| 4 | one eager and one lazy plugin demonstrated working, by name |
| 5 | startup measured both ways, same method, plus `rvpm profile --no-tui` |
| 6 | rollback performed and re-applied |

## Write back

- Design doc: add the real startup numbers. The migration's justification was
  partly performance; record whether it delivered. If rvpm is slower, that is
  a finding worth keeping, not burying.
- §4.1: correct the per-block fate table against what actually had to happen.
- If anything in `init.lua` had to stay that §4.1 said would go, say why —
  that is exactly the kind of fact that gets lost between sessions.
- Append the review-log row, and note that P6 is now unblocked (its
  precondition (b) is "`init.lua` no longer requires the bootloader").
