# RECORD: nvim config setup on remote host `sp` (KUDPC supercomputer)

Status: **abandoned** — nvim is NOT used on the remote env anymore (2026-08-08).
This doc records what was done and what problems remain, for future reference.

## 1. Environment facts (sp)

| Item | Value |
|---|---|
| Host | `camphor.kudpc.kyoto-u.ac.jp` (ssh alias `sp`, user `b39027`, key `~/.ssh/main`) |
| OS | RHEL 8.10, glibc 2.28 (old — many prebuilt binaries refuse to run) |
| nvim | 0.11.1 AppImage (0.12.4 prebuilt needs glibc 2.33+ → unusable) |
| deno | 2.9.5 via mise (config fallback path `~/.local/share/mise/installs/deno/latest/bin/deno` works) |
| Network | OK (GitHub, crates.io reachable) |

## 2. What was done

### 2.1 Repo sync
- `~/.config/nvim` on sp: branch `temp`, remote switched from SSH to HTTPS
  (sp has no GitHub SSH key).
- Local dirty file `lua/hooks/vim-gin.dpp` was copied via scp; later the same
  change landed in commit `22d91c8` ("Update vim-gin config", user's own push),
  so sp's tree ended up clean.

### 2.2 Toolchain installed on sp (`~/.local/bin`, on PATH)
| Tool | Version | How |
|---|---|---|
| nvim | 0.11.1 | AppImage extracted once to `~/.local/share/nvim-appimage/squashfs-root/usr/bin/nvim`, symlinked at `~/.local/bin/nvim` (avoids per-session `/tmp/.mount_nvim*` churn that broke dpp state files). Original AppImage kept as `~/.local/bin/nvim.bak-0.11.1`. |
| pi | 0.84.1 | GitHub release (required by agentic.nvim) |
| kakehashi | 0.9.0 | **built from source** via cargo (~4.5 min; prebuilt needs glibc 2.29+) |
| tree-sitter | 0.26.11 | cargo install (prebuilt needs newer glibc) |
| deno | 2.9.5 | mise (`[tools] deno = "latest"` in `~/.config/mise/config.toml`) |

### 2.3 Plugin install
- All 114 plugins installed by the bootloader (dpp#make_state + makeStatePost
  flow) into `~/.cache/nvim/dpp/repos`; merged cache at
  `~/.cache/nvim/dpp/nvim/.dpp` (13 lua modules) regenerated.
- `SKK-JISYO.L` (4.5 MB, from local `/usr/share/skk/`) copied to
  `~/.local/share/skk/SKK-JISYO.L` on sp.

### 2.4 Config fixes committed to `temp` (all pushed; sp pulled to `5765f48`)
| Commit | Fix |
|---|---|
| `10e5ef2` | `make_state.lua`: nil-guard `vim.env.MISE_DATA_DIR` (crash when mise not activated) |
| `0cc34ca` | `init.lua`: bypass denops version check on nvim 0.11.x (denops needs 0.11.3+) |
| `38e8701` | `options.lua`: guard `pumborder` option (0.12+) |
| `e16e3fc` | `bootloader/init.lua`: pre-create `filetypedetect` augroup (E216 in dpp startup.vim on 0.11) |
| `87e7015` | headless path: register `Dpp:makeStatePost` handler BEFORE make_state (installer never ran otherwise) |
| `ce8eba7` | `utils.lua` notify wrapper: create log dir + never raise on write failure (was aborting makeState before its plugin-merge step → `.dpp` never populated → load_state deadlock/rebuild loop) |
| `d79008d` | `ft.dpp`: use vimscript `setlocal -=/+=` forms — `vim.opt remove/append` with tables is broken on nvim 0.11 (E539); string-form remove on `set`-type options removes nothing |
| `3226ea3` | skkeleton: prefer `~/.local/share/skk/SKK-JISYO.L` over `/usr/share/skk/SKK-JISYO.L` (XDG_DATA_HOME or `~/.local/share`) |
| `5765f48` | tree-sitter-manager hook: polyfill `vim.list.unique` (`vim.list` is nvim 0.12+) |

### 2.5 Verified working on sp (before abandonment)
- `load_state` succeeds, no rebuild loop, zero ftplugin errors (E539 gone).
- skkeleton converts: `getCandidates("にほん")` → `{ "日本", "二本", "にほん", "２本", "2本" }`
  (via `skkeleton#request("getCandidates", { kana, "okurinasi" })`).

## 3. Problems (unresolved / footguns)

1. **nvim 0.11.1 is too old for the config's plugin set.** Needs shims:
   `vim.list` (0.12+), `pumborder` (0.12+), denops version check, dpp E216.
   The polyfill commit `5765f48` was **never verified on sp** — the state
   rebuild that would embed it into `~/.cache/nvim/dpp/nvim/state.vim` was
   still running when the project was abandoned. sp's state.vim still contains
   the OLD hook (no polyfill) → tree-sitter-manager still errors at VimEnter
   (`util.lua:31: attempt to index field 'list' (a nil value)`).
2. **ddu-ui-filer hook E117 loop**: `lua/hooks/ddu-ui-filer.dpp` registers
   `{ 'TabEnter', 'WinEnter', 'CursorHold', 'FocusGained' }` →
   `ddu#ui#do_action('checkItems')` unconditionally. When ddu is not yet
   sourced (lazy), every CursorHold errors `E117: Unknown function:
   ddu#ui#do_action`. Reproduced in headless sessions on sp; NOT fixed.
   (Local 0.13 may be unaffected because ddu loads eagerly there — unverified.)
3. **Killing a makeState session mid-merge corrupts `.dpp`**: makeState
   deletes `.dpp` first and merges `lua/` LAST. Killing the session between
   delete and merge leaves `.dpp` without `lua/` → next load_state fails →
   rebuild loop. Always let deferred-quit sessions finish
   (`-c "lua vim.defer_fn(function() vim.cmd('qa!') end, N)"`), never
   `pgrep -x nvim | xargs kill`.
4. **`git pull` on sp fails when the working tree is dirty** (merge aborts
   with "Please commit your changes or stash them"). The dirty
   `lua/hooks/vim-gin.dpp` blocked two pulls; workaround: stash → merge →
   stash pop. (Now moot: tree is clean since `22d91c8`.)
5. **tree-sitter-manager parser install**: `get_requires` error also surfaced
   during install; parsers were never confirmed installed on sp.
6. **skkeleton dictionary path**: config change `3226ea3` was verified only
   indirectly; the getCandidates test ran while sp's git state was ambiguous
   (pull had silently failed), so the dictionary source actually used is not
   100% certain. `~/.local/share/skk/SKK-JISYO.L` exists on sp.
7. **kakehashi LSP**: needs `~/.config/kakehashi/kakehashi.toml` on sp
   (never configured).
8. **mise neovim 0.12.4 experiment**: removed; do not reinstall (glibc).

## 4. Verification commands (if revisited)

```bash
# state health
timeout 60 nvim --headless -c "qa!" 2>&1 | grep -cE "Loading state error"   # expect 0
grep -c "state rebuilt" <log>                                                # expect 0 (no rebuild)
ls ~/.cache/nvim/dpp/nvim/.dpp/lua/ | wc -l                                  # expect 13

# skkeleton dictionary
nvim --headless -c "lua vim.defer_fn(function() print(vim.inspect(vim.fn['skkeleton#request']('getCandidates', { 'にほん', 'okurinasi' }))); vim.cmd('qa!') end, 20000)"

# force state rebuild (only if needed; let it finish!)
rm -rf ~/.cache/nvim/dpp/nvim/.dpp
nohup nvim --headless -c "lua vim.defer_fn(function() vim.cmd('qa!') end, 420000)" > /tmp/rebuild.log 2>&1 &
```
