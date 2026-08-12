# P1 gate context — lazy denops proof (read-only distillation)

Distilled for the P1 worker agent. No experiments run here.

## Design doc

**§1 Goal.** Migrate plugin management from dpp.vim (denops/deno, in-editor installer) to rvpm (Rust CLI, ahead-of-time `loader.lua`). Delete `my_nvim_bootloader` entirely (~1262 lines); replacement is a guarded `dofile(loader)` in `init.lua`.

**§2 Verified facts.** Current boot chain: `init.lua` → `my_nvim_bootloader.startup()` → dpp rescue paths (F1/F2/F3). Config surface: 137 `[[plugins]]` across 14 `deps/*.toml`, 35 `hooks_file` entries. rvpm 3.44.0: CLI-side install, zero runtime glob, loader phases 1–9, denops first-class (§2.4). `config_root` cannot relocate `config.toml` — always read from `~/.config/rvpm/<appname>/config.toml` (§2.3). Prior art: yukimemi/dotfiles uses 11-line `init.lua`, 251 plugins, but `denops = false` — lazy-denops path not exercised daily by author.

**§2.4 rvpm lazy denops mechanism (quote).** At `rvpm generate`, rvpm scans `denops/<name>/main.{ts,js}` and records `DenopsPlugin { name, main_script }`. Generated `load_lazy` at trigger time:

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

Bypasses `denops#plugin#discover()` timing — explicit registration after lazy rtp append. `denops#plugin#wait` prevents "Not an editor command" on `on_cmd` replay. Unit-tested in `loader.rs`.

**§2.6 rvpm.nvim verified (`RVPM_APPNAME=nvim-rvpm`).**

| Check | Result |
|---|---|
| `rvpm sync` | clones + `loader.lua` + helptags |
| `:Rvpm` subcommands | 18 (sync, generate, clean, add, tune, update, remove, edit, set, config, init, list, browse, doctor, profile, log, completion, self-update) |
| extra command | `:RvpmAddCursor` |
| `require("rvpm")` | table |
| `:checkhealth rvpm` | wraps `rvpm doctor`; resolves `config_root` from `$RVPM_APPNAME` |
| `vim.go.loadplugins` after load | `false` |
| generated `load_lazy` | contains denops block verbatim even with zero denops plugins |

Operational: `rvpm sync` requires TTY — non-TTY fails with `os error 6`; use `script -qec "rvpm sync" /dev/null`.

**§3 Layout.** Symlink `~/.config/rvpm/<appname>` → repo `rvpm/` (chosen). `config_root` via Tera impossible (§2.3). Cache stays outside repo at `~/.cache/rvpm/<appname>`.

**§4 Replacement.** Target `init.lua`: `vim.loader.enable()` + guarded `dofile(loader)`. Delete rtp surgery, packpath clearing, bootloader. Cold start: missing loader → bare nvim, user runs `rvpm sync`. No auto-install, no restart, no boot-path denops dependency. Adopt rvpm.nvim for BufWritePost → generate.

**§5 Config translation.** 137 plugins; field mapping table in doc (repo→url, hooks_file→per-plugin init/before/after.lua, etc.). Gaps: `on_lua` (D2), shared hooks / no `group` (D3). 58 hook sections across 35 `.dpp` files to convert in P4.

**§6 Migration risks.**

| ID | Risk | Mitigation |
|---|---|---|
| ~~D1~~ | Lazy denops never register | **Resolved** in source (§2.4); verify at runtime in P1 |
| D2 | No `on_lua`; `agentic.nvim` | make eager or trigger via `on_cmd`/`on_event` |
| D3 | No `group`, no shared hook file | `require` from `lua/hooks/shared/*.lua` |
| D4 | `.dpp` tooling dead weight | cleanup in P7 |
| D5 | `auto_update = "install"` default | set `"notify"` or `"off"` |
| D6 | `cooldown = "1d"` default | document; `--no-cooldown` for hotfixes |
| D7 | `merge = true` first-wins collisions | check summary after first full sync |
| D8 | 137 denops-heavy plugins vs author's config | P1: skkeleton + one ddu + one ddc before bulk conversion |

**§7 Quint spec.** Bootloader specs deleted, not ported — no state machine after migration.

**§8 Decisions.** Q1: local plugins via `dev = true`. Q2: archive bootloader repo. Q3: adopt rvpm.nvim (verified §2.6).

**§9 Phases.** P1 = lazy denops gate; P2 layout; P3 config.toml; P4 hooks; P5 init.lua; P6 delete bootloader; P7 cleanup.

## loader.lua load_lazy

From `~/.cache/rvpm/nvim-rvpm/plugins/loader.lua` (generated):

```lua
local function load_lazy(name, path, plugin_files, ftdetect_files, after_plugin_files, before, after, denops_plugins)
  if _G["rvpm_loaded_" .. name] then return end
  _G["rvpm_loaded_" .. name] = true
  vim.opt.rtp:append(path)
  if before then dofile(before) end
  for _, f in ipairs(plugin_files) do vim.cmd("source " .. f) end
  if #ftdetect_files > 0 then
    vim.cmd("augroup filetypedetect")
    for _, f in ipairs(ftdetect_files) do vim.cmd("source " .. f) end
    vim.cmd("augroup END")
  end
  for _, f in ipairs(after_plugin_files) do vim.cmd("source " .. f) end
  if after then dofile(after) end
  if denops_plugins and #denops_plugins > 0 and vim.fn.exists("*denops#plugin#load") == 1 then
    for _, dp in ipairs(denops_plugins) do
      local ok = pcall(vim.fn["denops#plugin#load"], dp[1], dp[2])
      if ok then
        -- denops#plugin#load() は非同期。DenopsPluginPost を待たずに
        -- on_cmd replay が走ると、`DenopsPluginPost` で command を登録する
        -- 典型的な denops プラグインが "Not an editor command" で失敗する。
        -- silent=1 で daemon 未起動時でもユーザー通知を抑制 (resilience)。
        pcall(vim.fn["denops#plugin#wait"], dp[1], { silent = 1 })
      end
    end
  end
  vim.api.nvim_exec_autocmds("User", { pattern = "rvpm_loaded_" .. name })
end
```

## Review traps (r1)

1. **Asserted the wrong thing.** `_G["rvpm_loaded_<x>"] == true` only proves rvpm ran its loader. Post-trigger column must show `denops#plugin#is_loaded("<name>") == 1`.
2. **Trigger fired before `DenopsReady`.** Discovery could have registered the plugin; rvpm's mechanism untested. Order: server `running` + `DenopsReady` fired → pre-checks → trigger.
3. **ddu configured with `on_event = "DenopsReady"`** instead of `on_cmd = ["Ddu"]`. DenopsReady trigger coincides with discovery and proves nothing.
4. **Plugin was never lazy.** Must appear in loader phase 7 (trigger registration), not phase 6 (eager block).
5. **denops never came up.** Record `denops#server#status()` as `running`; verify deno resolves.
6. **Contaminated environment.** Real `~/.config/rvpm/nvim/` or `init.lua` touched — `git diff init.lua` must be empty; real stub unchanged.
7. **Fell back to escape hatch without saying so.** `merge = true` or hand-written `after.lua` calling `denops#plugin#load` means native mechanism did not work — changes verdict and P4 scope.

Gate: criterion 4 for **all three** plugins (skkeleton, ddu, ddc). Two of three = REJECT.

## Env facts

| Fact | Value |
|---|---|
| rvpm version | `rvpm 3.44.0` (`RVPM_NO_AUTOUPDATE=1`) |
| deno path | `/home/kiyama/.local/share/mise/installs/deno/2.9.5/bin/deno` (also `~/.local/share/mise/installs/deno/latest/bin/deno` exists) |
| nvim version | `NVIM v0.13.0-dev-1192+ga5103c0853` |
| loader.lua | exists: `~/.cache/rvpm/nvim-rvpm/plugins/loader.lua` (1674 bytes) |
| cache dir | exists: `~/.cache/rvpm/nvim-rvpm/` |

`~/.config/rvpm/nvim-rvpm/config.toml`:

```toml
# isolated test config for rvpm.nvim (RVPM_APPNAME=nvim-rvpm)
[options]
auto_update = "off"
concurrency = 8

[[plugins]]
url = "yukimemi/rvpm.nvim"
```

## config.toml now

`~/.config/rvpm/nvim-rvpm/config.toml`:

```toml
# isolated test config for rvpm.nvim (RVPM_APPNAME=nvim-rvpm)
[options]
auto_update = "off"
concurrency = 8

[[plugins]]
url = "yukimemi/rvpm.nvim"
```
