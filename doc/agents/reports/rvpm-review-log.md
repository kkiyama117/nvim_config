# rvpm migration — review log

One row per review. This file is the migration's memory across sessions:
Claude sessions do not persist, but this does. **Read it before reviewing any
phase.**

Keep rows short. The "worth remembering" column is for the fact that would
otherwise be re-derived — a corrected assumption, a trap that fired, a
decision and its reason. Detail belongs in the phase report; conclusions
belong in `doc/agents/plan-rvpm-bootloader.md`.

| Date | Phase | Verdict | Worth remembering |
|---|---|---|---|
| 2026-08-12 | P0 design | ACCEPT | Bootloader discarded rather than rewritten. D1 (lazy denops) resolved from rvpm's `src/loader.rs` before P1 ran: `load_lazy` calls `denops#plugin#load` + `wait`. `config_root` cannot relocate `config.toml` (measured) → symlink. rvpm author's own config gates denops off, so this repo is the first real exerciser of that path |

## Standing corrections

Facts that were wrong at some point and must not come back:

| Wrong | Right | Source |
|---|---|---|
| `config_root` via Tera can keep `config.toml` in the repo | It cannot — rvpm reads `~/.config/rvpm/<appname>/config.toml` first; no `--config` flag, no `RVPM_CONFIG_ROOT` | measured with `RVPM_APPNAME=rvpm-probe`, design doc §2.3 |
| `external_commands` → rvpm `build` | → `cond`. dpp uses it as an `executable()` gate, not a build step | `dpp.vim/autoload/dpp/source.vim:138` |
| Shared hooks are `plugins = [...]` | The construct is `[[multiple_hooks]]` with `plugins` + `hooks_file` | `deps/ddc.toml:154` |
| `rvpm sync` can run headless | Needs a TTY; fails `os error 6`. Wrap: `script -qec "rvpm sync" /dev/null` | observed |
