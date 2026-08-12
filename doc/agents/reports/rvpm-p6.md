# P6 report — local bootloader clone removed

STATUS: PASS

## Preconditions

| # | check | command | output | pass? |
|---|-------|---------|--------|-------|
| 1 | clean working tree | `git -C ~/programs/nvim_plugins/my_nvim_bootloader status --porcelain` | *(empty)* | yes |
| 2 | no unpushed commits | `git -C … log --oneline @{u}..HEAD` | *(empty)* | yes |
| 3 | main == origin/main | `git -C … status -sb` | `## main...origin/main` | yes |
| 4 | remote archive complete | `gh api repos/kkiyama117/my_nvim_bootloader/contents/specs --jq '.[].name'` | `bootloader.qnt`, `bootloader_test.qnt` | yes |
| | | `gh api …/contents --jq '.[].name'` | `.gitignore`, `LICENSE`, `README.md`, `autoload`, `doc`, `lua`, `plugin`, `specs` | yes |
| | | `gh api '…/commits?per_page=1' --jq '.[0].sha[0:7], .[0].commit.message'` | `0c93369` / `docs(specs): add Quint model…` | yes |
| 5 | no live references | `grep -rn my_nvim_bootloader ~/.config/nvim --exclude-dir=.git` on `*.{lua,ts,toml,vim,dpp}` | no matches | yes |
| 6 | nvim without clone | `mv …/my_nvim_bootloader{,.tobedeleted}` then `nvim --headless -c 'qa!'` | exit 0, stderr empty | yes |

Precondition 6 procedure: rename first, verify, then `rm -rf …/my_nvim_bootloader.tobedeleted`.

## What was deleted

| Field | Value |
|-------|-------|
| Path | `~/programs/nvim_plugins/my_nvim_bootloader` |
| Size | 676K |
| Last commit | `0c93369ebf0ddb798b602ea5a0b64575ffec5d81` — `docs(specs): add Quint model of the boot/recovery and auto_update flows` |
| Remote kept | `git@github.com:kkiyama117/my_nvim_bootloader.git` |

`~/programs/nvim_plugins/` is now **empty** (bootloader was its only entry). Future local plugins: rvpm `dev = true` with explicit `dst` (plan §8 Q1). `denops/dpp.ts:194` still scans this directory until P7 removes it — harmless while empty.

## Remote archive

```
specs/:     bootloader.qnt, bootloader_test.qnt
root dirs:  autoload, doc, lua, plugin, specs
HEAD:       0c93369 — Quint specs archive commit
```

## Acceptance

| # | check | result |
|---|-------|--------|
| 1 | preconditions recorded | **PASS** |
| 2 | clone gone | **PASS** — `~/programs/nvim_plugins/my_nvim_bootloader` does not exist |
| 3 | nvim_plugins empty | **PASS** — directory contains only `.` and `..` |
| 4 | headless nvim | **PASS** — exit 0 after delete |
| 5 | remote intact | **PASS** — specs, lua, plugin present on GitHub |
| 6 | grep doc-only | **PASS** — no hits outside `doc/agents/**`; `README.md` updated to `rvpm sync` flow |

## Remaining references

All hits are documentation or agent context (expected):

| Location | Expected? |
|----------|-----------|
| `doc/agents/**` | yes — migration plan, prompts, prior reports |
| `p1-context.md` | yes — agent scratch (not loaded by Neovim) |
| `README.md` | updated — no longer mentions bootloader; now `rvpm sync` + `nvim` |

No references in `init.lua`, `lua/`, `denops/`, `deps/`, or `rvpm/`.

## Also done

- `README.md` install section: bootloader story → `rvpm sync`, then `nvim` (design doc §4.2).

## Next

**P7:** delete dpp rollback artifacts — `deps/*.toml`, `lua/hooks/*.dpp`, `denops/dpp.ts`, `~/.cache/nvim/dpp/`; mark obsolete planning docs; record migration completion in plan.
