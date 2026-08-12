# Claude review — P6: local bootloader clone removed

Read `doc/agents/prompts/rvpm/review/README.md` first. Then this.

Small phase, irreversible action. The review is almost entirely about whether
the preconditions were genuinely checked before the delete, not after.

## What P6 was supposed to do

Delete `~/programs/nvim_plugins/my_nvim_bootloader` locally, keeping
`git@github.com:kkiyama117/my_nvim_bootloader.git` as the archive.

Established before the phase: the Quint specs were committed and pushed as
`0c93369` and verified present on the remote, so the remote is a complete
archive. Six preconditions were required, the last being rename-and-verify
before any `rm`.

## Read

1. `doc/agents/reports/rvpm-p6.md`
2. `doc/agents/prompts/rvpm/p6-remove-bootloader.md`
3. `doc/agents/reports/rvpm-review-log.md`

## The traps

| # | Trap | How to detect |
|---|---|---|
| 1 | **Preconditions claimed, not shown.** The whole value of this phase | Each of the six needs its command **and its output** in the report. "verified" without output is unmet |
| 2 | **`rm -rf` as the first action.** The prompt required `mv <dir> <dir>.tobedeleted`, verify Neovim starts, *then* remove | If the report shows no rename step, the safety net was skipped even if the outcome happened to be fine — report it, because the next irreversible phase will repeat the habit |
| 3 | **Remote not actually re-verified** | The archive claim is the entire justification. Check it yourself now — a local report cannot prove a remote state |
| 4 | **Leftover references** | `grep -rn "my_nvim_bootloader" ~/.config/nvim --exclude-dir=.git` — only doc hits are acceptable. A live reference means a broken startup on some path not exercised by `--headless` |
| 5 | **Scope creep into P7** | `deps/*.toml`, `lua/hooks/*.dpp`, `denops/dpp.ts`, `~/.cache/nvim/dpp/` must all still exist. Deleting them here removes the rollback early |
| 6 | **The remote was rewritten** | `git push --force` or a history rewrite on the archive is a CRITICAL finding. Check the remote's HEAD is still `0c93369` or a descendant |

## Reproduce

```sh
ls -la ~/programs/nvim_plugins/ 2>&1               # gone? directory now empty?
gh api repos/kkiyama117/my_nvim_bootloader/contents/specs --jq '.[].name'
gh api repos/kkiyama117/my_nvim_bootloader/contents --jq '.[].name'
gh api repos/kkiyama117/my_nvim_bootloader/commits --jq '.[0].sha[0:7], .[0].commit.message' | head -3
grep -rn "my_nvim_bootloader" ~/.config/nvim --exclude-dir=.git
nvim --headless -c 'qa!' ; echo "exit=$?"
ls ~/.cache/nvim/dpp/ >/dev/null && echo "dpp cache intact (expected at this phase)"
```

## Acceptance to confirm

| # | Criterion |
|---|---|
| 1 | six preconditions with real command output |
| 2 | local clone gone |
| 3 | `~/programs/nvim_plugins/` empty, or remaining contents listed |
| 4 | `nvim --headless -c 'qa!'` exits 0 |
| 5 | remote still lists `specs/`, `lua/`, `plugin/`, history intact |
| 6 | remaining grep hits are documentation only |

## Write back

- Design doc §8 Q1: the local-plugins directory is now empty, so `dev = true`
  is a forward-looking policy with no current subject. Say that explicitly so
  a future session does not go looking for local plugins to migrate.
- Design doc §9 P6: mark done, with the date and the archive sha.
- If the rename-and-verify step was skipped, put that in the review log as a
  process finding — P7 is the next irreversible phase and inherits the habit.
- Append the review-log row.
