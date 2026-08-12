# PLAN: Discard my_nvim_bootloader, migrate to rvpm

Status: design only (no code written, nothing migrated)
Decision: **the bootloader is discarded, not rewritten** — `init.lua` calls
rvpm's generated `loader.lua` directly
Owner: AI agents
Related: `~/programs/nvim_plugins/my_nvim_bootloader/` (separate repo, to be
archived), `init.lua`, `deps/*.toml`, `lua/hooks/*.dpp`, `denops/dpp.ts`

## 1. Goal

Move plugin management from [dpp.vim](https://github.com/Shougo/dpp.vim)
(denops/deno, in-editor installer) to
[rvpm](https://github.com/yukimemi/rvpm) (Rust CLI, ahead-of-time compiled
`loader.lua`), and **delete `my_nvim_bootloader` entirely**.

rvpm moves installation out of Neovim, so the bootloader's reason to
exist — bootstrap dpp, detect a broken state, clone missing deps, drive
`dpp#make_state`, restart — disappears. There is no shrunken bootloader to
keep: the replacement is four lines in `init.lua`.

## 2. Verified facts

Everything in this section was measured, not assumed.

### 2.1 Current boot chain

```
init.lua
  ├─ minimal &rtp (config, $VIMRUNTIME, after), packpath cleared,
  │  $VIMRUNTIME removed; restored on SourcePre */plugin/* or VimEnter
  ├─ rtp:prepend ~/programs/nvim_plugins/my_nvim_bootloader
  └─ require('my_nvim_bootloader').startup()
        ├─ set g:my_nvim_bootloader#dpp#*  (cache_home / cache_github / denops_script)
        ├─ rtp:prepend dpp.vim, dpp-ext-lazy, denops.vim
        └─ dpp#min#load_state(cache_home)
              ├─ 0        → autocmds (BufWritePost watchers, :DppUpdate, makeStatePost)
              ├─ non-zero → F1: install denops if missing → start denops → make_state
              └─ E117     → F2: fallback → min.rescue_min (git clone) → :restart!
                                 F3: normal deps missing → min.rescue_normal → retry make_state
```

| Module | Lines | Role |
|---|---|---|
| `lua/my_nvim_bootloader/init.lua` | 286 | startup, F1/F2 dispatch, headless make_state |
| `lua/my_nvim_bootloader/dpp/auto_update.lua` | 375 | toml-save / config-save / `:DppUpdate` flows, `ask_restart` |
| `lua/my_nvim_bootloader/autocmds.lua` | 200 | BufWritePost watchers, DenopsReady wiring, `:DppUpdate` |
| `lua/my_nvim_bootloader/dpp/make_state.lua` | 172 | normal-deps rtp load, `dpp#make_state`, F3 |
| `lua/my_nvim_bootloader/min/init.lua` | 108 | rescue clone + restart (F2/F3) |
| `lua/my_nvim_bootloader/fallback.lua` | 73 | `error_number` → rescue routing |
| `lua/my_nvim_bootloader/min/github_installer.lua` | 47 | raw `git clone` |
| `plugin/my_nvim_bootloader.lua` | 1 | empty entry point |
| **total** | **1262** | **all deleted** |

Config surface in this repo: **137 `[[plugins]]`** across 14 `deps/*.toml`,
**35 `hooks_file`** entries pointing at `lua/hooks/*.dpp`.

### 2.2 rvpm behaviour (rvpm 3.44.0, installed at `~/.local/bin/rvpm`)

| Property | Value |
|---|---|
| Install path | CLI-side. `rvpm sync` clones (pure-Rust `gix`, no `git` binary needed) |
| Startup cost | `dofile("<cache_root>/plugins/loader.lua")`, zero runtime glob |
| Loader phase 1 | `vim.go.loadplugins = false` — rvpm disables Neovim auto-sourcing itself |
| Loader phases | 1 loadplugins → 2 `load_lazy` → 3 global `before.lua` → 4 per-plugin `init.lua` → 5 rtp append `merged/` → 6 eager plugins → 7 lazy triggers → 8 `ColorSchemePre` → 9 global `after.lua` |
| rtp layout | `merged/` (eager + `merge=true`) or `views/<host>/<owner>/<repo>/`; never `repos/` |
| denops support | first-class — see §2.4 |
| Lockfile | `<config_root>/rvpm.lock`, meant to be committed |
| Init wiring | `rvpm init` prints `dofile(vim.fn.expand("~/.cache/rvpm/nvim/plugins/loader.lua"))` |
| Env vars | only `RVPM_APPNAME`, `RVPM_NO_AUTOUPDATE`, `RVPM_TIMING`, `RVPM_AI_*` |
| appname | `$RVPM_APPNAME` → `$NVIM_APPNAME` → `"nvim"` |

`rvpm doctor` on this machine: nvim v0.13.0-dev, git 2.55.0, chezmoi 2.72.0,
`$EDITOR` all OK; `loader.lua missing` + `init.lua loader hook missing` as
expected for an untouched setup.

### 2.3 `config_root` cannot relocate `config.toml`

Measured with an isolated `RVPM_APPNAME=rvpm-probe`:

| Setup | `rvpm doctor` plugin count |
|---|---|
| `[[plugins]]` in `<config_root>/config.toml`, `config_root` set in the default-path file | `0/0` — not read |
| `[[plugins]]` in the default-path `~/.config/rvpm/rvpm-probe/config.toml` | `0/1` — read |

`config.toml` is always read from `~/.config/rvpm/<appname>/config.toml`.
`config_root` only relocates what is read *after* the config is parsed
(hooks tree, `rvpm.lock`), and there is no `--config` flag and no
`RVPM_CONFIG_ROOT` env var to bootstrap it. Chicken-and-egg: rvpm must read
`config.toml` to learn where `config.toml` is.

Side effect already applied: running `rvpm init` (print-only mode) created a
stub `~/.config/rvpm/nvim/config.toml` (`[options]`, 75 bytes). `init.lua`
was **not** modified (that needs `--write`).

### 2.4 rvpm handles lazy denops plugins natively — D1 is solved

This was flagged as the risk that could kill the migration. It is handled in
rvpm's own loader generator (`src/loader.rs`, comments in Japanese — written
deliberately for this case).

At `rvpm generate` time rvpm scans each plugin for `denops/<name>/main.{ts,js}`
and records a `DenopsPlugin { name, main_script }`. The generated `load_lazy`
helper receives that list and, at trigger time:

```lua
local function load_lazy(name, path, plugin_files, ftdetect_files, after_plugin_files, before, after, denops_plugins)
  ...
  vim.opt.rtp:append(path)
  ...
  if denops_plugins and #denops_plugins > 0 and vim.fn.exists("*denops#plugin#load") == 1 then
    for _, dp in ipairs(denops_plugins) do
      local ok = pcall(vim.fn["denops#plugin#load"], dp[1], dp[2])
      if ok then
        pcall(vim.fn["denops#plugin#wait"], dp[1], { silent = 1 })
      end
    end
  end
  vim.api.nvim_exec_autocmds("User", { pattern = "rvpm_loaded_" .. name })
end
```

So the `denops#plugin#discover()` timing problem — discovery runs once at
`DenopsReady`, a lazy plugin joins rtp long after — is bypassed by explicit
registration. The `denops#plugin#wait` call exists specifically so `on_cmd`
replay does not fail with "Not an editor command" for plugins that register
their commands in `DenopsPluginPost`. Covered by unit tests in `loader.rs`
(`test_load_lazy_helper_calls_denops_plugin_load`,
`test_lazy_dep_denops_plugins_propagated_to_trigger_block`,
`test_lazy_colorscheme_handler_passes_denops_plugins`). Dependency chains and
`ColorSchemePre` handlers propagate the denops list too.

This also answers the question the previous agent session spent ~3h on: under
rvpm, a lazy skkeleton does not depend on `denops#plugin#discover()` at all.

### 2.5 Prior art — the rvpm author's own dotfiles

[yukimemi/dotfiles](https://github.com/yukimemi/dotfiles) (`home/.config/`,
managed by his own `yui`). Directly usable as reference.

**`home/.config/nvim/init.lua` — 11 lines, no bootloader:**

```lua
vim.loader.enable()
local loader = vim.fn.expand("~/.cache/rvpm/nvim/plugins/loader.lua")
if vim.uv.fs_stat(loader) then
  dofile(loader)
end
```

No rtp surgery, no `packpath` clearing, no `$VIMRUNTIME` removal — confirming
§4.3. The `fs_stat` guard is the whole cold-start story.

**`home/.config/rvpm/nvim/config.toml` — 251 plugins, 1255 lines**, with
`before.lua` (9.3 KB) / `after.lua` (3.3 KB) as global hooks and per-plugin
hooks under `plugins/github.com/<owner>/<repo>/`.

```toml
[vars]
denops = false

[options]
auto_clean = true
url_style = "full"
concurrency = 16
ai = "agy"
ai_language = "ja"
merge_doc = true
```

**Caveat worth weighing: he turned denops off.** All 15 denops plugins are
gated `when = "{{ vars.denops }}"` with `denops = false`, and between
2026-07-25 and 2026-07-30 he published Lua rewrites of his own denops
plugins (`chronicle.nvim`, `silentsaver.nvim`, `autoreplacer.nvim`,
`ahdr.nvim`, `lumiris.nvim`) that are now the active entries. No ddu / ddc /
skkeleton / dpp / dvpm anywhere in his config. So the lazy-denops code path
in §2.4 is implemented and unit-tested but **not exercised daily by the
author** — this config would be the one exercising it.

Reusable hook patterns from his tree:

| File | Pattern |
|---|---|
| `plugins/…/vim-denops/denops.vim/before.lua` | `vim.g["denops#server#deno_args"] = {...}` — global denops setup at the `before` phase |
| `plugins/…/lambdalisue/vim-gin/after.lua` | denops readiness idiom: if `denops#plugin#is_loaded("gin")` then set up now, else `User DenopsPluginPost:gin` once |
| `plugins/…/yukimemi/ahdr.vim/init.lua` | `vim.g.*` + `nvim_create_user_command` at the pre-rtp phase |

The `vim-gin` readiness idiom is directly applicable when converting our
`lua/hooks/*.dpp` files for ddu / ddc / skkeleton / gin.

### 2.6 rvpm.nvim verified (isolated `RVPM_APPNAME=nvim-rvpm`)

Synced a one-plugin config and loaded it with a scratch `init.lua` following
the §4.1 shape. Results:

| Check | Result |
|---|---|
| `rvpm sync` | clones + `loader.lua` (38 lines) + helptags |
| `:Rvpm` subcommands | `sync generate clean add tune update remove edit set config init list browse doctor profile log completion self-update` (18) |
| extra command | `:RvpmAddCursor` |
| `require("rvpm")` | table |
| `:checkhealth rvpm` | wraps `rvpm doctor`; resolves `config_root` from `$RVPM_APPNAME` correctly; reports chezmoi integration state |
| `vim.go.loadplugins` after load | `false` — confirms §4.3 |

Generated `load_lazy` in `loader.lua` contains the denops block from §2.4
verbatim, even with zero denops plugins configured — it is part of the helper
rvpm always emits.

**Operational finding: `rvpm sync` requires a TTY.** Run from a non-TTY
context it fails immediately with `Error: No such device or address
(os error 6)` — it opens the progress TUI unconditionally. It succeeds under
a pty (`script -qec "rvpm sync" /dev/null`). Relevant for any automation, and
another reason the bootloader must not try to run `sync` from inside Neovim.

## 3. Layout decision

Requirement: `config.toml`, `rvpm.lock`, and hooks must be version-controlled
in this repo, and `$NVIM_APPNAME` isolation must survive.

**Recommendation — symlink the whole config root:**

```
~/.config/rvpm/nvim  ->  ~/.config/nvim/rvpm/
                          ├── config.toml     (137 plugins)
                          ├── rvpm.lock       (committed)
                          ├── before.lua      (global, phase 3)
                          ├── after.lua       (global, phase 9)
                          └── plugins/github.com/<owner>/<repo>/{init,before,after}.lua
```

| Option | Verdict |
|---|---|
| Symlink `~/.config/rvpm/<appname>` → repo `rvpm/` | **Chosen.** `config_root` stays unset (rvpm's own recommendation), everything is git-managed, appname isolation kept |
| `config_root` via Tera | Impossible — §2.3 |
| `options.chezmoi = true` | Viable alternative; chezmoi 2.72.0 is installed and already holds `tree-sitter-dpp`. Rejected as default because it splits nvim config across two repos. Note the author himself left chezmoi in April 2026 |
| Leave at default, unmanaged | Rejected — cloning this repo would not reproduce the plugin set |

`<cache_root>` (`~/.cache/rvpm/<appname>`) stays outside the repo — clones,
`merged/`, `views/`, and the generated `loader.lua` are all reproducible from
`config.toml` + `rvpm.lock`.

With no bootloader, the symlink is created by a documented bootstrap step
(`scripts/` helper + README), not by Neovim.

## 4. The replacement

### 4.1 `init.lua`

Target shape, following §2.5:

```lua
vim.loader.enable()
local loader = vim.fn.expand("~/.cache/rvpm/nvim/plugins/loader.lua")
if vim.uv.fs_stat(loader) then
  dofile(loader)
end
```

What the current `init.lua` does today, and where each part goes:

| Current | Fate |
|---|---|
| `NVIM_CONFIG_HOME` / `NVIM_CACHE_HOME` env, `vimrc#is_debug`, `vimrc#augroup` | keep in `init.lua` (needed before plugins load) |
| minimal `&rtp` list | delete |
| deno fallback (`g:denops#deno` when `deno` is off PATH) | move to `plugins/…/vim-denops/denops.vim/before.lua` |
| `rtp:prepend my_nvim_bootloader` + `startup()` | delete → guarded `dofile` |
| `packpath = ''`, `rtp:remove($VIMRUNTIME)`, `SourcePre`/`VimEnter` restore | **delete** — see §4.3 |
| `filetype plugin indent on`, `syntax on` | keep |

Setup that must run before plugins but does not belong in `init.lua` goes to
rvpm's global `before.lua` (phase 3, before every per-plugin `init.lua`).

### 4.2 Cold start and failure modes

No recovery logic lives in Neovim any more.

| Condition | Behaviour |
|---|---|
| `loader.lua` missing (fresh machine, wiped cache) | `fs_stat` guard skips the `dofile`; Neovim starts bare. User runs `rvpm sync` |
| `rvpm` not on `PATH` | shell-level problem; install via `cargo install rvpm` or a release binary |
| `loader.lua` stale / errors | `rvpm generate` (no git) |
| `config.toml` missing | `rvpm init` |
| headless / embedded session (kakehashi host, subagent nvim) | nothing special — no session ever writes to the cache |

The install story in `README.md` changes from "run `nvim`" to
"`rvpm sync`, then `nvim`". That is the trade for deleting 1262 lines.

Three behaviours disappear with the bootloader:

- **No auto-install.** Plugins are never cloned from inside Neovim.
- **No restart.** `:restart!`, `ask_restart`, the restart budget, and the
  headless-restart guard are all gone.
- **No boot-path denops dependency.** deno is still required by ddc / ddu /
  skkeleton / gin as plugins, but a broken deno no longer breaks loading.

### 4.3 Why the rtp surgery goes

The block at the bottom of `init.lua` (clear `packpath`, remove
`$VIMRUNTIME`, restore on `SourcePre */plugin/*` or `VimEnter`) exists to
stop default plugins loading before dpp decides. **rvpm's loader phase 1 sets
`vim.go.loadplugins = false`, which is exactly that guarantee**, so the
surgery is redundant — and risky, because the loader sources Lua files with
`dofile()`, which does not fire `SourcePre`, so the restore can land at an
unintended point. The author's own `init.lua` has none of it.

Confirm with `rvpm profile` that startup does not regress and that built-in
runtime plugins still behave.

### 4.4 Config-edit workflow

`BufWritePost` → `dpp#make_state` → install → ask restart is replaced by
`rvpm generate` on write. [rvpm.nvim](https://github.com/yukimemi/rvpm.nvim)
ships exactly that autocmd plus `:Rvpm <sub>`, completion over `config.toml`
plugin names, and `:checkhealth rvpm`; the author lists it first in his own
config. Adopt it rather than hand-writing the autocmd.

## 5. Config translation reference

### 5.1 Plugin fields

Counts are occurrences across `deps/*.toml`.

| dpp | n | rvpm | Note |
|---|---|---|---|
| `repo` | 137 | `url` | same `owner/repo` shorthand (author uses `url_style = "full"`) |
| `group` | 85 | — | no equivalent; organisational only, plus shared `hooks_file` (D3) |
| `hooks_file` | 35 | `plugins/<host>/<owner>/<repo>/{init,before,after}.lua` | 1 file → up to 3 (§5.2) |
| `on_event` | 16 | `on_event` | `User Foo` shorthand on both sides |
| `depends` | 15 | `depends` | direct |
| `on_source` | 9 | `on_source` | rvpm fires `rvpm_loaded_<name>` |
| `lazy` | 7 | `lazy` | rvpm infers `true` from any `on_*` |
| `on_ft` | 6 | `on_ft` | direct |
| `on_map` | 3 | `on_map` | rvpm additionally supports `{lhs, mode, desc}` and `/^<Plug>\(…/` regex |
| `external_commands` | 3 | `cond` | **not `build`.** dpp skips sourcing when the command is not `executable()` (`autoload/dpp/source.vim:138`) → `cond = "vim.fn.executable('tree-sitter') == 1"` |
| `if` | 2 | `cond` (runtime) or `when` (compile-time) | `if = 'exists("$MOCWORD_DATA")'` is runtime → `cond` |
| `denops_wait` | 2 | — | unnecessary; `load_lazy` calls `denops#plugin#wait` itself (§2.4) |
| `[[multiple_hooks]]` | 2 | — | dpp-ext-toml construct, `plugins = [...]` + `hooks_file`: one hook file shared by several plugins (`deps/ddc.toml:154` → `ddc.vim` + `skkeleton`; `deps/ddu.toml` → `ddu.vim` + `vim-gin`); see D3 |
| `rtp = ""` | 2 | — | dpp-only (dpp.vim itself); gone with dpp |
| `on_if` | 1 | `cond` | runtime Lua expression |
| `on_lua` | 1 | — | **gap.** rvpm has no `on_lua`; see D2 |
| `on_post_source` | 1 | `on_source` | rvpm's `on_source` already means "after the target loaded" |
| `on_cmd` | 1 | `on_cmd` | direct; rvpm also accepts `/^Regex/` |
| `name` | 1 | `name` | direct |

### 5.2 Hooks

dpp packs every hook for a plugin into one `.dpp` file with fold-marker
sections (`-- lua_add {{{ … }}}`). rvpm uses separate files per plugin:

| dpp section | rvpm file | Timing |
|---|---|---|
| `hook_add` / `lua_add` | `plugins/<host>/<owner>/<repo>/init.lua` | phase 4, before rtp is touched |
| `hook_source` / `lua_source` | `…/before.lua` | after rtp append, before `plugin/*` |
| `hook_post_source` / `lua_post_source` | `…/after.lua` | after `plugin/*`; plugin APIs callable |
| `hook_post_update` | `build` / `build_lua` | at clone/update time, CLI-side |
| file-level `hooks_file` (e.g. `ft.dpp` in `no_lazy.toml`) | global `before.lua` / `after.lua` | phases 3 / 9 |

Surveyed section counts across all 35 `.dpp` files — **58 sections total**:

| Section | n | Format | Target |
|---|---|---|---|
| `lua_source` | 29 | Lua | `before.lua` |
| `lua_add` | 26 | Lua | `init.lua` |
| `hook_source` | 2 | Vim script with `lua << EOF` heredocs | `before.lua` |
| `hook_add` | 1 | Vim script with `lua << EOF` heredocs | `init.lua` |

There are **no** `post_source` sections, so `after.lua` is needed only where a
block demonstrably requires `plugin/*` to have been sourced. The three
Vim-script sections live in exactly two files — `lua/hooks/shared/ddc_skkeleton.dpp`
and `lua/hooks/shared/ddu_gin.dpp` — which are also the two
`[[multiple_hooks]]` entries, so the Vim-script parsing and the shared-hook
problem (D3) are the same two files.

`lua_source` → `before.lua` is 1:1 in timing: dpp appends the rtp entry, runs
`hook_source`, then sources `plugin/`; rvpm's `before.lua` sits at the same
point. Mechanical, but needs a conversion script, not hand editing.

For denops plugins whose hooks call plugin functions, use the `vim-gin`
readiness idiom from §2.5 rather than assuming the plugin is live.

## 6. Migration risks

| ID | Risk | Impact | Mitigation |
|---|---|---|---|
| ~~D1~~ | ~~Lazy denops plugins never register~~ | — | **Resolved** — rvpm emits `denops#plugin#load` + `wait` per lazy plugin (§2.4). Still verify once in P1, since the author's own config no longer exercises it |
| D2 | rvpm has no `on_lua`; `agentic.nvim` uses `on_lua = "agentic"` | 1 plugin | make eager, or trigger via `on_cmd` / `on_event` |
| D3 | No `group`, and no way to share one hook file across plugins (`plugins = ["ddc.vim","skkeleton"]`) | `lua/hooks/shared/*.dpp` (2 files) | move shared logic to `lua/hooks/shared/*.lua` and `require` it from each generated hook |
| D4 | `.dpp` tooling becomes dead weight: `after/ftplugin/dpp.lua`, `after/queries/dpp/*`, the kakehashi `tree-sitter-dpp` bridge, `doc/agents/plan-dpp-viml-emmylua-bridge.md` | editor tooling only | separate cleanup after cutover; that plan doc gets obsoleted, not implemented |
| D5 | `options.auto_update` defaults to `"install"` — every rvpm invocation may silently download and swap the rvpm binary | supply chain | set `auto_update = "notify"` (or `"off"`) explicitly |
| D6 | `options.cooldown` defaults to `"1d"`; `rvpm update` holds back newer commits | surprising "no updates" | document it; `--no-cooldown` for hotfixes |
| D7 | `merge = true` hard-links files into one rtp entry; first-wins on path collisions | silent wrong file | check the `first-wins` summary after the first full `rvpm sync` |
| D8 | 137 plugins vs the author's 251 — but ours are ddu/ddc-heavy denops plugins he no longer runs | unknown-unknowns in the denops path | P1 prototype covers skkeleton; extend to one ddu and one ddc plugin before the bulk conversion |

## 7. The Quint spec is deleted, not ported

`specs/bootloader.qnt` + `specs/bootloader_test.qnt` model the boot state
machine: `Booting/Loaded/Failed`, `F1/F2/F3` recovery, restart bounds, the
headless guard, and the auto_update flows. Every one of those behaviours is
being deleted.

What replaces it is `if vim.uv.fs_stat(loader) then dofile(loader) end` —
one branch, no state, nothing to verify. Porting the spec would mean
inventing behaviour to justify the spec.

The invariants that mattered (`headlessNeverRestarts`, `restartBounded`,
`restartOnlyAfterUpdate`) are satisfied vacuously: there is no restart, no
install, and no rebuild in the Neovim process at all.

Action: the spec files are currently untracked (`?? specs/`). Commit them
first so the archived bootloader repo carries its own history, then archive
the repo. Do not port them into this repo.

## 8. Decisions

All open questions are now resolved.

| # | Question | Decision |
|---|---|---|
| Q1 | Local plugins under `~/programs/nvim_plugins/` | **`dev = true`** entries in `config.toml` (with `dst` pointing at the real path). Replaces `dpp-ext-local`, which scans that directory at `denops/dpp.ts:194`. Note: after P6 the directory is empty — `my_nvim_bootloader` was its only entry — so this is a policy for future local plugins, not a migration item |
| Q2 | Fate of the `my_nvim_bootloader` repo | **Delete the local clone, keep `git@github.com:kkiyama117/my_nvim_bootloader.git`** as the archive. Preconditions in §9 P6 |
| Q3 | Adopt `rvpm.nvim`? | **Yes** — verified working in §2.6; also the author's own first plugin entry |

Settled earlier by the decision and by §2.4 / §2.5: the bootloader is
discarded, D1 is solved, the symlink is a `scripts/` bootstrap step, and
`init.lua` follows the author's 11-line pattern.

## 9. Phases (none executed)

Each phase is run as one omp session against a prompt in
`doc/agents/prompts/rvpm/`, with Claude reviewing the report between phases.
See that directory's `README.md` for the flow and the shared rules.

| P | Work | Gate |
|---|---|---|
| P0 | This document reviewed | — |
| P1 | Prototype under `NVIM_APPNAME=nvim-rvpm`: skkeleton + one ddu + one ddc plugin, lazy, denops live | D1/D8 confirmed in practice |
| P2 | Layout bootstrap: repo `rvpm/` dir, symlink script, `.gitignore`, `[options]` policy (`auto_update`, `cooldown`) | — |
| P3 | Conversion script `deps/*.toml` → `config.toml` (137 entries), reporting every unmapped field | §5.1 |
| P4 | Hook conversion: 35 `.dpp` → per-plugin Lua files + `lua/hooks/shared/*.lua` | — |
| P5 | New `init.lua`; delete the rtp surgery; measure with `rvpm profile` vs current `--startuptime` | P3, P4 |
| P6 | Delete the local bootloader clone. Precondition (a) **done**: `specs/*.qnt` committed and pushed as `0c93369`, verified present on `kkiyama117/my_nvim_bootloader`; the remote is now a complete archive. Precondition (b) still open: `init.lua` must have dropped `require('my_nvim_bootloader').startup()` first, or Neovim loads zero plugins | P5 |
| P7 | Cutover cleanup: delete `deps/*.toml`, `denops/dpp.ts`, `lua/hooks/*.dpp`; update docs; `.dpp` editor tooling removed (D4) | P5 |

## Migration completed (2026-08-13)

dpp.vim → rvpm migration finished on branch `temp`.

| Metric | Value |
|--------|-------|
| Plugins migrated | 137 dpp entries → 129 rvpm (`rvpm/config.toml`) |
| Startup (dpp baseline) | 81.6 ms (`nvim --headless --startuptime`) |
| Startup (rvpm) | 64.7 ms |
| rvpm profile | 37.6 ms total |
| Phases | P1–P7 complete |
| Bootloader | local clone deleted (P6); GitHub archive kept |
| dpp cache | `~/.cache/nvim/dpp/` retained per user request (P7) |

Rollback path (`deps/`, hooks, `denops/dpp.ts`) removed in P7 except the
external dpp plugin cache above.

