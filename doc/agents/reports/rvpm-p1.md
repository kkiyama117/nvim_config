# P1 report — lazy denops under rvpm

STATUS: FAIL

## Verdict

rvpm's native lazy-denops path works for **skkeleton** (the migration blocker in D1): after
`DenopsReady`, `<C-j>` loads the plugin and `denops#plugin#is_loaded("skkeleton")` becomes 1
via the generated `load_lazy` denops block. **ddu** and **ddc** fail the native gate: rvpm's
generate-time scan only records `denops/<name>/main.{ts,js}`; both plugins ship
`denops/{ddu,ddc}/app.ts` and register manually from autoload when `ddu#start` /
`ddc#enable` run — not when the rvpm lazy trigger alone fires. Workaround 1
(`merge = true`, `lazy = true`) changed nothing. Workaround 2 (per-plugin `after.lua` calling
`denops#plugin#load`) makes all three pass. Migration may proceed for the common
`main.ts` layout (skkeleton and ~similar plugins), but P4 must hand-write denops hooks for
`app.ts`-style plugins (ddu, ddc, and likely others) unless rvpm's scanner is extended.

## Environment

| Item | Value |
|------|-------|
| rvpm | `rvpm 3.44.0` (`RVPM_NO_AUTOUPDATE=1`) |
| deno | `deno 2.9.5` at `/usr/bin/deno` |
| nvim | `NVIM v0.13.0-dev-1192+ga5103c0853` |
| appname | `RVPM_APPNAME=nvim-rvpm` |
| config | `~/.config/rvpm/nvim-rvpm/config.toml` (see repo-adjacent copy below) |

```toml
# isolated test config for rvpm.nvim (RVPM_APPNAME=nvim-rvpm)
[options]
auto_update = "off"
concurrency = 8

[[plugins]]
url = "yukimemi/rvpm.nvim"

[[plugins]]
url = "vim-denops/denops.vim"

[[plugins]]
url = "vim-skk/skkeleton"
on_map = [{ lhs = "<C-j>", mode = ["i", "c", "t", "n"] }]

[[plugins]]
url = "Shougo/ddu.vim"
depends = ["denops.vim"]
on_cmd = ["Ddu"]
merge = true
lazy = true

[[plugins]]
url = "Shougo/ddc.vim"
depends = ["denops.vim"]
on_event = ["InsertEnter"]
merge = true
lazy = true
```

Per-plugin hooks added for workaround 2:

- `~/.config/rvpm/nvim-rvpm/plugins/github.com/Shougo/ddu.vim/after.lua`
- `~/.config/rvpm/nvim-rvpm/plugins/github.com/Shougo/ddc.vim/after.lua`

## Results

### Native rvpm mechanism (no after.lua hooks)

| Plugin | trigger | pre `rvpm_loaded_` | pre `is_loaded` | post `rvpm_loaded_` | post `is_loaded` | verdict |
|--------|---------|-------------------|-----------------|---------------------|-----------------|---------|
| skkeleton | `<C-j>` | nil | 0 | true | 1 | PASS |
| ddu | `:Ddu` | nil | 0 | true | 0 | FAIL |
| ddc | InsertEnter | nil | 0 | true | 0 | FAIL |

### After workarounds

| Attempt | skkeleton | ddu | ddc |
|---------|-----------|-----|-----|
| 1. `merge=true`, `lazy=true` | PASS (unchanged) | FAIL | FAIL |
| 2. per-plugin `after.lua` → `denops#plugin#load` | PASS (native) | PASS | PASS |

## How it was driven

```sh
export RVPM_NO_AUTOUPDATE=1
export RVPM_APPNAME=nvim-rvpm
cd ~/.config/nvim

# sync (needs pty)
script -qec "rvpm sync" /dev/null

# run gate (uses after.lua hooks in current loader)
doc/agents/reports/rvpm-p1-run.sh
# equivalent:
# script -qec 'nvim --headless -u doc/agents/reports/rvpm-p1-init.lua -l doc/agents/reports/rvpm-p1-assert.lua' /dev/null
```

Scratch init (`doc/agents/reports/rvpm-p1-init.lua`):

```lua
vim.loader.enable()
if vim.fn.executable("deno") == 0 then
  local mise_deno = vim.fs.joinpath(vim.env.HOME, ".local/share/mise/installs/deno/latest/bin/deno")
  if vim.fn.executable(mise_deno) == 1 then vim.g["denops#deno"] = mise_deno end
end
local loader = vim.fn.expand("~/.cache/rvpm/nvim-rvpm/plugins/loader.lua")
if vim.uv.fs_stat(loader) then dofile(loader) end
```

Assertion script: `doc/agents/reports/rvpm-p1-assert.lua` (also copied to
`~/.config/rvpm/nvim-rvpm/p1-assert.lua`).

Automation notes (not failures of rvpm in interactive use):

- Headless `feedkeys("<C-j>")` does not dispatch lua keymaps; assert invokes the registered
  `<C-j>` callback via `maparg(..., true).callback()` (same code path as the map).
- Headless `startinsert` does not fire `InsertEnter`; assert uses
  `nvim_exec_autocmds("InsertEnter")`.
- `:Ddu` stub deletes itself and replays `:Ddu`; ddu.vim does not define `:Ddu` (only
  `ddu#start`). Assert uses `pcall(vim.cmd, "Ddu")` and checks post-`load_lazy` state only.

## Surprises

| Finding | Plan doc impact |
|---------|-----------------|
| rvpm only auto-detects `denops/<name>/main.{ts,js}` | §2.4 — note ddu/ddc use `app.ts`; scanner gap |
| ddu/ddc autoload registers on `DenopsReady` **or** when server already running **if** `ddu#start` / `ddc#enable` is called; lazy trigger alone only appends rtp | §2.4 — post-trigger denops registration is not automatic for all denops plugins |
| `merge=true` on lazy plugins does not populate `denops_plugins` in `load_lazy` | §2.4 / D7 — merge layout irrelevant to denops registration |
| Generated loader omits `_rvpm_dn_*` for ddu/ddc (empty `{}`) while skkeleton gets `{ "skkeleton", ".../main.ts" }` | confirms generate-time scan is the differentiator |

## Blocked

None (all sub-questions resolved within budget).

## Next

P2 can lay out `config_root` symlink. P4 must:

1. Treat skkeleton as native (no denops hook needed beyond normal rvpm lazy config).
2. Add `after.lua` (or equivalent) for plugins using `denops/*/app.ts` manual registration
   (at minimum ddu, ddc; grep converted tree for `denops#plugin#load` in autoload).
3. Re-run `doc/agents/reports/rvpm-p1-run.sh` after hook changes; expect PASS only when
   after hooks are present for app.ts plugins.

Native-only re-check: temporarily remove the two `after.lua` files, `rvpm generate`, re-run
assert — expect skkeleton PASS, ddu/ddc FAIL.
