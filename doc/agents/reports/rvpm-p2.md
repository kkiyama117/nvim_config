# P2 report — layout bootstrap

STATUS: PASS

## What was created

| Path | Purpose |
|------|---------|
| `rvpm/config.toml` | `[options]` only; P3 adds `[[plugins]]` |
| `rvpm/before.lua` | Global hook stub (loader phase 3) |
| `rvpm/after.lua` | Global hook stub (loader phase 9) |
| `scripts/rvpm-link.sh` | Idempotent symlink bootstrap |
| `doc/agents/reports/rvpm-p2.md` | This report |

P1 note: `rvpm-p1.md` has `STATUS: FAIL` (native-only gate). User directed P2 after
settling that migration proceeds with P4 denops hooks for `app.ts` plugins.

## [options] choices

| Key | Value | Reason |
|-----|-------|--------|
| `auto_update` | `"notify"` | D5 — avoid silent binary self-update on every invocation |
| `cooldown` | `"1d"` | D6 — default; documents why updates may look stalled |
| `concurrency` | `16` | Matches yukimemi/rvpm author config |
| `auto_clean` | `false` | Config is empty until P3; avoid deleting clones during partial syncs |

`config_root` and `cache_root` are unset (§2.3, §3).

## scripts/rvpm-link.sh

Appname resolution: `$RVPM_APPNAME` → `$NVIM_APPNAME` → `nvim`.

| State before | Action | Exit |
|--------------|--------|------|
| Target missing | `ln -s <repo>/rvpm` → `~/.config/rvpm/<appname>` | 0 |
| Correct symlink already | Print "already linked", no change | 0 |
| Symlink to wrong target | Refuse, print expected vs actual | 1 |
| Real directory (incl. rvpm init stub) | Refuse, print `rm -rf` hint for stub | 1 |
| Other file at target | Refuse | 1 |
| Repo `rvpm/` missing | Refuse | 1 |

## Acceptance

| # | check | result |
|---|-------|--------|
| 1 | first run creates symlink | PASS — `RVPM_APPNAME=p2-link-test sh scripts/rvpm-link.sh` → `~/.config/rvpm/p2-link-test -> ~/.config/nvim/rvpm` |
| 2 | second run no-op | PASS — same command prints "already linked", exit 0 |
| 3 | refuses real directory (scratch) | PASS — `p2-refuse-test` mkdir + script → REFUSE exit 1 |
| 4 | `RVPM_APPNAME=nvim-rvpm` path isolation | PASS — refuses `~/.config/rvpm/nvim-rvpm` (P1 real dir intact); path not `nvim` |
| 5 | `rvpm doctor` via symlink | PASS — after `rvpm generate`: `0/0` plugins, 0 errors (1 warn: init.lua hook, expected pre-P5) |

Production link for default appname is **blocked** until the user removes the rvpm init stub:

```sh
rm -rf ~/.config/rvpm/nvim   # 75-byte stub; script refuses to clobber
sh scripts/rvpm-link.sh
```

Do **not** remove `~/.config/rvpm/nvim-rvpm/` — P1 test appname stays isolated.

## Surprises

| Finding | Impact |
|---------|--------|
| `~/.config/rvpm/nvim/` is a real directory (75-byte stub), not a symlink | Expected per prompt; script detects and refuses |
| `rvpm doctor` exit 2 with only init.lua warn is normal pre-P5 | Not a layout failure |
| P2 prompt gate says P1 `STATUS: PASS`; P1 is `FAIL` (native) | Overridden by user; gate question already settled |

## Next

P3 (`p3-config-toml.md`):

1. User runs `rm -rf ~/.config/rvpm/nvim && sh scripts/rvpm-link.sh` when ready (or keep using scratch appname until then).
2. Convert `deps/*.toml` (137 plugins) into `rvpm/config.toml` via converter script.
3. Record all 35 `hooks_file` entries in P4 handoff table; do not convert hooks yet.
4. Run `script -qec "rvpm sync" /dev/null` after plugins are added; commit `rvpm.lock`.
5. Carry P1 finding: P4 must add denops `after.lua` for `app.ts`-style plugins (ddu, ddc, …).
