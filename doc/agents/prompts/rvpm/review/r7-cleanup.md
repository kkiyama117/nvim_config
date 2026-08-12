# Claude review — P7: dpp removed

Read `doc/agents/prompts/rvpm/review/README.md` first. Then this.

Final phase. It burns the rollback path, so the first question is not "was it
done correctly" but **"should it have been done yet"**.

## What P7 was supposed to do

Delete every dpp artifact — `deps/*.toml` (14), `lua/hooks/*.dpp` (35),
`denops/dpp.ts`, the `.dpp` editor tooling — and update the docs that still
describe the dpp architecture. Design doc §9 P7, §6 D4.

## Read

1. `doc/agents/reports/rvpm-p7.md`
2. `git status` and `git diff` — deletions are the bulk of this phase
3. `doc/agents/reports/rvpm-review-log.md` — how long has rvpm actually been
   in daily use?

## The traps

| # | Trap | How to detect |
|---|---|---|
| 1 | **Run too early.** The prompt said not to start until the user had been running on rvpm long enough to be confident | Check the review log dates. If P5 was yesterday, the rollback was destroyed after one day of use. That is a finding regardless of execution quality |
| 2 | **`~/.cache/nvim/dpp/` deleted without asking** | The prompt required asking the user — it is 100+ clones outside the repo. Check whether it is gone and whether approval is recorded |
| 3 | **The old plan doc deleted** | `doc/agents/plan-dpp-viml-emmylua-bridge.md` must be **marked obsolete**, not removed. Planning history has value |
| 4 | **kakehashi / chezmoi touched** | Explicitly out of scope. `git -C ~/.local/share/chezmoi status` and the kakehashi config must be untouched; the report should only *describe* what would be needed |
| 5 | **Shared hook modules deleted** | P4 put shared logic in `lua/hooks/shared/*.lua`. Those are **live**, unlike the `.dpp` files next to them. A glob-based delete takes both |
| 6 | **`denops/deno.json` removed while still needed** | Check whether anything else under `denops/` survives and needs it |
| 7 | **Unjustified grep hits** | `grep -rni dpp` will still match `ddp`-like substrings and doc history. Every remaining hit needs a line in the report, not a summary count |
| 8 | **Docs half-updated** | `AGENTS.md` plugin-manager row must say rvpm; `README.md` install must say `rvpm sync` then `nvim`; vimdoc under `doc/` must stay vimdoc per AGENTS.md rule 01 |

## Reproduce

```sh
export RVPM_NO_AUTOUPDATE=1
git status --short
grep -rni "dpp" ~/.config/nvim --exclude-dir=.git | grep -v '^doc/agents/'
ls lua/hooks/ deps/ denops/ 2>&1
ls lua/hooks/shared/ 2>&1                       # shared modules must survive
rvpm doctor
nvim --headless -c 'qa!' ; echo "exit=$?"
nvim --headless -c 'e lua/vimrc/options.lua' -c 'e denops/consts.ts' -c 'e README.md' -c 'qa!' ; echo "exit=$?"
grep -n 'Plugin manager' AGENTS.md
ls ~/.cache/nvim/dpp/ 2>&1                      # gone? approved?
```

## Acceptance to confirm

| # | Criterion |
|---|---|
| 1 | remaining `dpp` hits all justified line by line |
| 2 | `nvim --headless -c 'qa!'` exits 0 |
| 3 | `rvpm doctor` clean |
| 4 | Lua / TypeScript / Markdown buffers open without error |
| 5 | `AGENTS.md` says rvpm |
| 6 | `git status` shows only expected deletions and doc edits |

## Write back — this is the last chance

After this phase the migration is over and the working context disappears.
Make the repo carry it:

- Design doc: add the closing section — plugins migrated, startup before and
  after, phases run, dates, and **what is still owed** (kakehashi
  `tree-sitter-dpp` bridge, anything deferred).
- Mark every phase in §9 done, with dates.
- The prompt set in `doc/agents/prompts/rvpm/` describes work that no longer
  exists. Either mark the directory historical with a one-line header in its
  `README.md`, or note in the design doc that it is retained as the record of
  how the migration was run. Do not delete it — it is the only description of
  the process.
- Final review-log row, with the overall verdict on the migration.
