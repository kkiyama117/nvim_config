# P3 report — deps/*.toml → rvpm/config.toml

STATUS: PASS

## Counts

| | n |
|---|---|
| Input `[[plugins]]` in `deps/*.toml` | 137 |
| Emitted in `rvpm/config.toml` | 129 |
| Dropped (dpp stack) | 8 |
| **Reconciles** | 137 = 129 + 8 |

Unique `hooks_file` paths handed to P4: **35** (37 handoff rows — shared hooks list multiple plugins).

## Field mapping applied

| dpp field | n | rvpm field | notes |
|---|---|---|---|
| `repo` | 137 | `url` | direct |
| `group` | 85 | — | dropped (organisational) |
| `hooks_file` | 32 plugin + 1 file + 2 multiple | — | P4 handoff only |
| `on_event` | 16 | `on_event` | direct |
| `depends` | 15 | `depends` | `gin` → `vim-gin` alias |
| `on_source` | 9 | `on_source` | `on_post_source` merged here; `gin` → `vim-gin` |
| `lazy` | 7 | `lazy` | explicit `false` preserved |
| `on_ft` | 6 | `on_ft` | direct |
| `on_map` | 3 | `on_map` | dict → `[{ lhs, mode }]` |
| `external_commands` | 3 | `cond` | `executable()` AND chain |
| `if` | 2 | `cond` | see Decisions |
| `denops_wait` | 2 | — | dropped (rvpm waits in `load_lazy`) |
| `rtp` | 2 | — | dpp-only, on dropped plugins |
| `on_if` | 1 | `cond` | `exists('$NVIM')` → env check |
| `on_lua` | 1 | `lazy = false` | see Decisions |
| `on_post_source` | 1 | `on_source` | same semantics in rvpm |
| `on_cmd` | 1 | `on_cmd` | direct |
| `name` | 1 | `name` | catppuccin |
| `hook_source` / `lua_source` / `lua_add` / `ftplugin` | 6 plugins | — | inline → P4 |
| `hook_add` / `description` / `extAttrs` | 3 | — | dropped with plugin or no rvpm field |

## Decisions

- **on_lua (agentic.nvim)** → `lazy = false` + keep `cond = "vim.fn.executable('pi') == 1"`. rvpm has no `on_lua`; eager load matches dpp loading the module when hooks run at startup.
- **[[multiple_hooks]] ×2** → P4 converts `lua/hooks/shared/ddc_skkeleton.dpp` (ddc.vim + skkeleton) and `lua/hooks/shared/ddu_gin.dpp` (ddu.vim + vim-gin) into `lua/hooks/shared/*.lua` required from each plugin's rvpm hooks.
- **external_commands ×3**:
  - agentic.nvim: `cond = "vim.fn.executable(\"pi\") == 1"`
  - kakehashi.nvim: `cond = "vim.fn.executable(\"kakehashi\") == 1"`
  - tree-sitter-manager.nvim: `cond = "vim.fn.executable(\"tree-sitter\") == 1"`
- **if ×2**:
  - tree-sitter-manager.nvim: `if = '!has("win32")'` → `cond = "not vim.fn.has('win32')"`
  - ddc-source-mocword: `if = 'exists("$MOCWORD_DATA")'` → `cond = "vim.env.MOCWORD_DATA ~= nil"`
- **on_if** (vim-guise): `on_if = "exists('$NVIM')"` → `cond = "vim.env.NVIM ~= nil"`
- **on_source alias**: dpp `gin` → rvpm `vim-gin` (doctor typo without fix)
- **Inline hooks (P4, not in config.toml)**:
  - thinca/vim-qfreplace, machakann/vim-vimhelplint: `ftplugin` → plugin `before.lua` or ftplugin dir
  - previm/previm, NI57721/skkeleton-henkan-highlight: `hook_source` → `before.lua`
  - romus204/tree-sitter-manager.nvim: `lua_source` → `before.lua`
  - uga-rosa/ddu-source-lsp: `lua_add` → `init.lua`
- **extAttrs** (vimdoc-ja `installerMinCommitDays`): dropped — no rvpm equivalent
- **skkeleton** has no `on_*` in dpp (FuncUndefined via dpp-ext-lazy) → **eager** in rvpm. P4 or a follow-up should add `on_map` for `<C-j>` if lazy load is desired.

## Dropped plugins

| repo | reason |
|------|--------|
| Shougo/dpp.vim | dpp stack deleted |
| Shougo/dpp-ext-lazy | dpp stack deleted |
| Shougo/dpp-ext-toml | dpp stack deleted |
| Shougo/dpp-ext-local | dpp stack deleted |
| Shougo/dpp-ext-installer | dpp stack deleted |
| Shougo/dpp-ext-packspec | dpp stack deleted |
| Shougo/dpp-protocol-git | dpp stack deleted |
| Shougo/dpp-protocol-http | dpp stack deleted |

## Hooks handoff for P4

Regenerate: `python3 scripts/dpp2rvpm.py | jq '.hooks_handoff'`

| plugin url | dpp hooks_file | rvpm hook dir |
|------------|----------------|---------------|
| (global) | lua/hooks/ft.dpp | rvpm/before.lua + rvpm/after.lua |
| carlos-algms/agentic.nvim | lua/hooks/agentic.nvim.dpp | rvpm/plugins/github.com/carlos-algms/agentic.nvim/ |
| stevearc/aerial.nvim | lua/hooks/aerial.nvim.dpp | rvpm/plugins/github.com/stevearc/aerial.nvim/ |
| catppuccin/nvim | lua/hooks/catppuccin.nvim.dpp | rvpm/plugins/github.com/catppuccin/nvim/ |
| Shougo/cmdline.vim | lua/hooks/cmdline.vim.dpp | rvpm/plugins/github.com/Shougo/cmdline.vim/ |
| Shougo/ddc.vim | lua/hooks/ddc.vim.dpp | rvpm/plugins/github.com/Shougo/ddc.vim/ |
| Shougo/ddc.vim | lua/hooks/shared/ddc_skkeleton.dpp | + require lua/hooks/shared/*.lua |
| vim-skk/skkeleton | lua/hooks/skkeleton.dpp | rvpm/plugins/github.com/vim-skk/skkeleton/ |
| vim-skk/skkeleton | lua/hooks/shared/ddc_skkeleton.dpp | + require lua/hooks/shared/*.lua |
| Shougo/ddt.vim | lua/hooks/ddt.vim.dpp | rvpm/plugins/github.com/Shougo/ddt.vim/ |
| Shougo/ddu.vim | lua/hooks/ddu.vim.dpp | rvpm/plugins/github.com/Shougo/ddu.vim/ |
| Shougo/ddu.vim | lua/hooks/shared/ddu_gin.dpp | + require lua/hooks/shared/*.lua |
| lambdalisue/vim-gin | lua/hooks/vim-gin.dpp | rvpm/plugins/github.com/lambdalisue/vim-gin/ |
| lambdalisue/vim-gin | lua/hooks/shared/ddu_gin.dpp | + require lua/hooks/shared/*.lua |
| Shougo/ddu-ui-ff | lua/hooks/ddu-ui-ff.dpp | rvpm/plugins/github.com/Shougo/ddu-ui-ff/ |
| Shougo/ddu-ui-filer | lua/hooks/ddu-ui-filer.dpp | rvpm/plugins/github.com/Shougo/ddu-ui-filer/ |
| vim-denops/denops.vim | lua/hooks/denops.vim.dpp | rvpm/plugins/github.com/vim-denops/denops.vim/ |
| j-hui/fidget.nvim | lua/hooks/fidget.nvim.dpp | rvpm/plugins/github.com/j-hui/fidget.nvim/ |
| lewis6991/gitsigns.nvim | lua/hooks/gitsigns.nvim.dpp | rvpm/plugins/github.com/lewis6991/gitsigns.nvim/ |
| rebelot/heirline.nvim | lua/hooks/heirline.nvim.dpp | rvpm/plugins/github.com/rebelot/heirline.nvim/ |
| atusy/kakehashi.nvim | lua/hooks/kakehashi.nvim.dpp | rvpm/plugins/github.com/atusy/kakehashi.nvim/ |
| cohama/lexima.vim | lua/hooks/lexima.vim.dpp | rvpm/plugins/github.com/cohama/lexima.vim/ |
| williamboman/mason.nvim | lua/hooks/mason.nvim.dpp | rvpm/plugins/github.com/williamboman/mason.nvim/ |
| nvim-neotest/neotest | lua/hooks/neotest.dpp | rvpm/plugins/github.com/nvim-neotest/neotest/ |
| EdenEast/nightfox.nvim | lua/hooks/nightfox.nvim.dpp | rvpm/plugins/github.com/EdenEast/nightfox.nvim/ |
| mfussenegger/nvim-dap | lua/hooks/nvim-dap.dpp | rvpm/plugins/github.com/mfussenegger/nvim-dap/ |
| rcarriga/nvim-dap-ui | lua/hooks/nvim-dap-ui.dpp | rvpm/plugins/github.com/rcarriga/nvim-dap-ui/ |
| theHamsta/nvim-dap-virtual-text | lua/hooks/nvim-dap-virtual-text.dpp | rvpm/plugins/github.com/theHamsta/nvim-dap-virtual-text/ |
| neovim/nvim-lspconfig | lua/hooks/nvim-lspconfig.dpp | rvpm/plugins/github.com/neovim/nvim-lspconfig/ |
| rcarriga/nvim-notify | lua/hooks/nvim-notify.dpp | rvpm/plugins/github.com/rcarriga/nvim-notify/ |
| stevearc/overseer.nvim | lua/hooks/overseer.nvim.dpp | rvpm/plugins/github.com/stevearc/overseer.nvim/ |
| Shougo/pum.vim | lua/hooks/pum.vim.dpp | rvpm/plugins/github.com/Shougo/pum.vim/ |
| mrcjkb/rustaceanvim | lua/hooks/rustaceanvim.dpp | rvpm/plugins/github.com/mrcjkb/rustaceanvim/ |
| folke/tokyonight.nvim | lua/hooks/tokyonight.nvim.dpp | rvpm/plugins/github.com/folke/tokyonight.nvim/ |
| kana/vim-niceblock | lua/hooks/vim-niceblock.dpp | rvpm/plugins/github.com/kana/vim-niceblock/ |
| machakann/vim-sandwich | lua/hooks/vim-sandwich.dpp | rvpm/plugins/github.com/machakann/vim-sandwich/ |
| folke/which-key.nvim | lua/hooks/which-key.nvim.dpp | rvpm/plugins/github.com/folke/which-key.nvim/ |

P1 addendum: ddu/ddc need denops `after.lua` for `app.ts` registration (not in dpp hooks — add during P4).

## Acceptance

| # | check | result |
|---|-------|--------|
| 1 | config parses | PASS — `tomllib.loads(rvpm/config.toml)` OK |
| 2 | count reconciles | PASS — 137 = 129 + 8 |
| 3 | doctor static | PASS — `depends 19/19`, `on_source typos — none`, `duplicates — none`, `cycles — none`; 0 config errors (2 expected warns: init.lua, not cloned) |
| 4 | hooks handoff | PASS — 35 unique hooks_file paths, 37 rows incl. shared |
| 5 | script deterministic | PASS — two runs byte-identical |
| 6 | unmapped accounted | PASS — only `on_lua` → eager decision; inline hooks listed for P4 |

Validation command (scratch appname, no full sync):

```sh
export RVPM_NO_AUTOUPDATE=1
RVPM_APPNAME=p3-test sh scripts/rvpm-link.sh
RVPM_APPNAME=p3-test script -qec "rvpm generate" /dev/null
RVPM_APPNAME=p3-test rvpm doctor
```

## Surprises

| Finding | Plan impact |
|---------|-------------|
| dpp `on_source = "gin"` is shorthand for vim-gin | §5.1 — note display-name aliases in converter |
| skkeleton without `on_*` becomes eager | §6 D8 — may want explicit `on_map` added post-P3 |
| P1/P2 gate text expects P1 PASS | P1 is FAIL (native); conversion proceeded per user |

## Next

P4 (`p4-hooks.md`):

1. Convert 35 `.dpp` files using handoff table above.
2. Convert 6 inline-hook plugins + 2 shared `.dpp` files.
3. Move `ft.dpp` → global `rvpm/before.lua` / `after.lua`.
4. Add denops `after.lua` for `app.ts` plugins (ddu, ddc minimum — P1 finding).
5. Consider adding skkeleton `on_map = [{ lhs = "<C-j>", mode = ["i","c","t","n"] }]` to `config.toml` when hook conversion confirms the binding.

Re-run converter after any manual `config.toml` tweak:

```sh
python3 scripts/dpp2rvpm.py > /tmp/dpp2rvpm-report.json
```
