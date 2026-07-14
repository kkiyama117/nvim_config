# Convert CommandlinePre/Post vimscript to Lua in ddc hook

**Date:** 2026-07-14
**Status:** open

## Context

`lua/hooks/ddc.lua` has a partial Lua translation of the old Vim script `CommandlinePre` function
inside the `lua_add` block, but it is incomplete:

- Missing `ddc#custom#set_context_buffer()` call for `:!` completion
- Missing `DDCCmdlineLeave` autocmd wiring to `CommandlinePost`
- Missing `ddc#enable_cmdline_completion()` call
- `CommandlinePost` function not defined at all
- Keymaps are commented out

The original Vim script functions (`CommandlinePre`, `CommandlinePost`) exist only in the old host
config and were never ported to Lua.

## Goal

1. Complete `commandline_pre` and add `commandline_post` as local Lua functions in `lua/hooks/ddc.lua`
2. Uncomment and rewrite the keymaps (`:`, `?`, `;;`, `;`) to call the Lua functions
3. Keep the `lua_source` block (ddc global config) unchanged

## Changes

### `lua/hooks/ddc.lua` — `lua_add` block

| What | Detail |
|------|--------|
| `commandline_pre(mode)` | Complete function: save buffer config, patch source options, set context buffer for `:!`, wire `DDCCmdlineLeave` autocmd, enable cmdline completion |
| `commandline_post()` | New function: restore buffer config from `b:prev_buffer_config` |
| Keymaps | `n:` / `n:?` / `x:` / `n:;;` / `n:;` → `<Nop>` — all calling the Lua functions |

### Files touched

- `lua/hooks/ddc.lua` — functions + keymaps in `lua_add`
- `docs/issues/2026-07-14-commandline-lua-conversion.md` — this issue

## Acceptance

- `nvim --headless -c 'qa'` exits 0 with no errors
- Pressing `:` in normal mode enters command-line mode (no crash)
- Pressing `?` in normal mode enters search mode (no crash)
- Pressing `;;` in normal mode enters command-line mode with cmdline enable
- Pressing `;` in normal mode does nothing (`<Nop>`)
- Visual-mode `:` works the same as normal-mode `:`
