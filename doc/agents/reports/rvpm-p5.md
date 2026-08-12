# P5 report — init.lua switched to rvpm

STATUS: PASS

## HEAD before the change

- **SHA:** `5cb916b8d23950e02105453219579557e9fdbe7e`
- **Branch:** `temp` (ahead of `origin/temp` by 1)
- **Working tree:** many untracked migration artifacts (`rvpm/`, scripts, reports); `init.lua` modified in place (not committed, per prompt)

## init.lua diff

**Kept:** env/debug/augroup block, `filetype plugin indent on`, `syntax on`.

**Added:**

```lua
vim.loader.enable()
local loader = vim.fn.expand('~/.cache/rvpm/nvim/plugins/loader.lua')
if vim.uv.fs_stat(loader) then
  dofile(loader)
end
```

**Removed (fate per plan §4.1):**

| Block | Fate |
|-------|------|
| minimal `&rtp` list | deleted — loader manages rtp |
| deno fallback (`g:denops#deno`) | moved → `rvpm/plugins/github.com/vim-denops/denops.vim/before.lua` |
| `rtp:prepend my_nvim_bootloader` + `require(...).startup()` | deleted — guarded `dofile(loader)` |
| `packpath = ''`, rtp remove/restore (`SourcePre`/`VimEnter`) | deleted — loader sets `vim.go.loadplugins = false` at phase 1 |

Net: 117 lines → 47 lines.

## First sync

Command: `export RVPM_NO_AUTOUPDATE=1; script -qec "rvpm sync" /dev/null` (log: `/tmp/rvpm-sync-p5.log`).

| Item | Result |
|------|--------|
| Plugins cloned | **129/129** (`rvpm doctor`) |
| Input vs emitted | 137 dpp entries → 129 rvpm (8 dpp-stack dropped in P3) |
| Failures | 0 clone failures |
| D7 merge (first-wins) | **1** file: `rustaceanvim` / `doc/mason.txt` (kept: `mason.nvim`) |
| Lazy→eager promotion | 4: `nvim-dap`, `rustaceanvim`, `skkeleton-henkan-highlight`, `skkeleton-state-popup` |
| Helptags | 27 dirs; warning `E154 Duplicate tag "neotest.config"` in merged doc |
| Loader | regenerated → `~/.cache/rvpm/nvim/plugins/loader.lua` |
| Lockfile | `rvpm/rvpm.lock` created by sync (not committed; user review) |

Symlink: removed stale stub `~/.config/rvpm/nvim`, ran `sh scripts/rvpm-link.sh` → `~/.config/rvpm/nvim` → `~/.config/nvim/rvpm/`.

## Startup

| config | measurement | source |
|--------|-------------|--------|
| dpp baseline | **81.6 ms** (`--- NVIM STARTED ---`) | `git restore init.lua` then `nvim --headless --startuptime /tmp/dpp-startup2.log -c 'qa!'` |
| rvpm | **64.7 ms** | same method with rvpm `init.lua` |
| rvpm profile | **37.6 ms** total (3 runs, instrumented) | `rvpm profile --no-tui` |

Profile phase breakdown: P6 eager 26.1 ms, P4 init 2.4 ms, P7 lazy reg 2.1 ms. Top eager offenders: user config, runtime rtp, merged denops bundle.

**Note:** dpp headless startup exits 0 but emits stderr from pre-existing `nvim-dap`/`overseer` hook ordering (`module 'overseer' not found`). rvpm headless stderr is empty.

## Acceptance

| # | check | result |
|---|-------|--------|
| 1 | headless nvim | **PASS** — `nvim --headless -c 'qa!'` exit 0, empty stderr |
| 2 | doctor + plugin count | **PASS** — `129/129` cloned, `init.lua loader hook — linked`; 2 warnings (merge stale link, D7 conflict), 0 errors |
| 3 | denops + skel/ddu/ddc | **PASS** — `doc/agents/reports/rvpm-p5-smoke.lua`: `denops#server#status()` → `running`; `denops#plugin#is_loaded` → **1** for skkeleton, ddu, ddc after triggers. `_G.rvpm_loaded_*` is only set by `load_lazy()`; eager skkeleton uses `rvpm_loaded_skkeleton` via User event, not `_G` |
| 4 | eager + lazy sample | **PASS** — **Eager:** `rcarriga/nvim-notify` (`lazy = false`): `require('notify')` succeeds at startup, `:Notifications` exists. **Lazy:** `previm/previm` (`on_ft = ["markdown","rst"]`): `_G.rvpm_loaded_previm` nil pre-buffer → `true` after `edit *.md` + filetype detected |
| 5 | startup measured | **PASS** — see Startup table; rvpm ~21% faster on `--startuptime`, profile 37.6 ms |
| 6 | rollback | **PASS** — `git restore init.lua` → dpp starts (exit 0); rvpm `init.lua` restored from backup → exit 0, clean stderr |

## Rollback

```sh
cd ~/.config/nvim
cp init.lua /tmp/init-rvpm-backup.lua   # optional safety
git restore init.lua                     # dpp bootstrap
nvim --headless -c 'qa!'                 # exit 0 (stderr: pre-existing dpp overseer hook noise)
cp /tmp/init-rvpm-backup.lua init.lua    # restore rvpm
nvim --headless -c 'qa!'                 # exit 0, clean stderr
```

`~/.cache/nvim/dpp/` left intact. `my_nvim_bootloader` clone untouched (P6).

## P5 fixes applied during validation

| Issue | Fix |
|-------|-----|
| `agentic.nvim/init.lua` `require` at phase 4 (no rtp) | removed `init.lua`; keymaps merged into `before.lua` after `setup()` |
| `skkeleton-henkan-highlight` broken multiline `vim.cmd` | single `vim.cmd([[...]])` in `before.lua` |
| `nvim-dap/before.lua` `require('overseer')` too early | deferred via `User` autocmd `rvpm_loaded_overseer.nvim` |
| `on_event = ["DenopsReady"]` invalid | → `["User DenopsReady"]` in `rvpm/config.toml` (ddu.vim, vim-gin); `scripts/dpp2rvpm.py` auto-prefixes bare `DenopsReady` |

## Surprises

| # | Item | vs design |
|---|------|-----------|
| 1 | 4 plugins promoted lazy→eager by rvpm sync | not in plan; dependency/init.lua interaction |
| 2 | `_G.rvpm_loaded_<name>` uses repo basename with **hyphens** (`nvim-notify`, `overseer.nvim`), not underscore variants | smoke scripts must match loader `name` arg |
| 3 | Phase-4 `dofile(.../init.lua)` runs for many plugins before lazy registration — hook init runs even when plugin files are lazy | §4.1 implied loader replaces rtp surgery; did not spell out init.lua-always-runs |
| 4 | dpp rollback stderr (overseer) pre-existed | not introduced by P5 |
| 5 | `on_event` bare event names need `User` prefix for DenopsReady | P3 converter gap; fixed in config + `dpp2rvpm.py` |

## Next

**P6:** delete `~/programs/nvim_plugins/my_nvim_bootloader` after review (init.lua no longer references it).

**Still referencing dpp (P7 rollback):** `deps/*.toml`, `lua/hooks/*.dpp`, `denops/dpp.ts`, `~/.cache/nvim/dpp/`, bootloader clone.

**Open items (non-blocking):**

- Commit decision on `rvpm/rvpm.lock`
- D7 `doc/mason.txt` conflict in rustaceanvim
- neotest helptags duplicate in merged doc
- denops `ddu.ts`/`ddc.ts` relative-path warnings in some hook paths (P1 workaround `after.lua` in place; monitor in interactive use)
