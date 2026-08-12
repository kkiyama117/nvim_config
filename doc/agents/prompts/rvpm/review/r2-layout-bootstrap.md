# Claude review — P2: layout bootstrap

Read `doc/agents/prompts/rvpm/review/README.md` first. Then this.

## What P2 was supposed to produce

The repo-side rvpm config root plus an idempotent symlink bootstrap, so later
phases have somewhere to write. Background: `config_root` **cannot** relocate
`config.toml` — rvpm always reads `~/.config/rvpm/<appname>/config.toml`, and
there is no `--config` flag or `RVPM_CONFIG_ROOT` env var. Measured, design
doc §2.3. The symlink is the workaround.

## Read

1. `doc/agents/reports/rvpm-p2.md`
2. `doc/agents/prompts/rvpm/p2-layout-bootstrap.md`
3. `rvpm/config.toml`, `rvpm/before.lua`, `rvpm/after.lua`, `scripts/rvpm-link.sh`
4. `doc/agents/reports/rvpm-review-log.md`

## The traps

| # | Trap | How to detect |
|---|---|---|
| 1 | **`config_root` or `cache_root` set in `config.toml`** | grep. Both must be absent — setting them breaks appname isolation and cannot relocate `config.toml` anyway |
| 2 | **`rvpm.lock` gitignored** | `git check-ignore -v rvpm/rvpm.lock`. It must be committable — it is the reproducibility record |
| 3 | **`auto_update` left at default** | grep `config.toml`. Default `"install"` silently downloads and swaps the rvpm binary on every invocation (design doc D5). Must be explicit |
| 4 | **The link script can destroy data** | Read it line by line. A real directory in the target path must cause a refusal, never a delete. `rm -rf`, `rm -r`, or `ln -sf` over a directory are all findings |
| 5 | **Not idempotent** | Run it twice yourself. Second run must exit 0 and change nothing |
| 6 | **Appname resolution wrong** | Must be `$RVPM_APPNAME` → `$NVIM_APPNAME` → `nvim`, in that order. Test with each set |
| 7 | **Test case 3 was exercised against the real path** | The prompt required a scratch path. If `~/.config/rvpm/nvim/` was damaged or its 75-byte stub deleted without asking, that is a CRITICAL finding |
| 8 | **The stub blocker was silently removed** | `~/.config/rvpm/nvim/config.toml` (75 bytes, `[options]` only) predates this work. The script should report it, not delete it |

## Reproduce

```sh
export RVPM_NO_AUTOUPDATE=1
sh scripts/rvpm-link.sh ; echo "exit=$?"     # twice
RVPM_APPNAME=nvim-rvpm sh scripts/rvpm-link.sh ; echo "exit=$?"
ls -la ~/.config/rvpm/
```

Then a destructive-safety check in a scratch dir: create a real directory
where the link would go, point the script at it via `RVPM_APPNAME`, and
confirm it refuses with a non-zero exit and leaves the directory intact.

## Acceptance to confirm

| # | Criterion |
|---|---|
| 1 | first run links, exit 0 |
| 2 | second run no-ops, exit 0 |
| 3 | real directory in the way → refuses, non-zero, explains, destroys nothing |
| 4 | `RVPM_APPNAME=nvim-rvpm` targets `~/.config/rvpm/nvim-rvpm` |
| 5 | `rvpm doctor` finds `rvpm/config.toml` through the link, `0/0` plugins, no error |

## Write back

- Record the final `[options]` policy in design doc §3 — the actual values
  chosen, not the recommendation. Later phases and any second machine depend
  on them.
- If `auto_clean` was enabled, note the consequence in §6 (D-series): every
  sync deletes plugin dirs no longer in `config.toml`, which makes a
  mid-migration partial `config.toml` destructive.
- Append the review-log row.
