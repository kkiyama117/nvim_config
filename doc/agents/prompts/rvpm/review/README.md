# Claude review prompts — dpp → rvpm migration

Prompts for Claude to review each omp phase. Written to be usable from a
**cold session**: assume the reviewing Claude has none of the context that
produced the plan, and give it everything it needs to verify independently.

## Usage

```
Review P1: read doc/agents/prompts/rvpm/review/r1-denops-lazy-proof.md and follow it.
```

One review per omp phase, run between phases. Never review two phases at once
— the gate between them is the point.

## Standing rules for the reviewer

**The report is a claim, not evidence.** omp wrote it about its own work. Your
job is to reproduce, not to read sympathetically.

| Rule | Meaning |
|---|---|
| Re-run every acceptance criterion yourself | If a criterion cannot be re-run, that is a finding |
| Read the diff, not the summary of the diff | `git status` + `git diff` before the report |
| Check the negative space | What did the prompt forbid? Verify it did not happen |
| A passing assertion on the wrong thing is a failure | The commonest defect: measuring something adjacent to the actual question |
| Do not fix things silently | Report findings, propose the fix, let the user decide. Small obvious corrections may be applied — say so explicitly |
| Scope creep is a finding | Edits outside the phase's stated scope get reported even if they look like improvements |

## Verdicts

| Verdict | Meaning |
|---|---|
| `ACCEPT` | Criteria met and independently reproduced. Next phase may start |
| `ACCEPT WITH FIXES` | Substance is right; listed corrections must be applied first. Say who applies them |
| `REJECT` | A criterion failed, was faked, or measured the wrong thing. The phase re-runs |
| `BLOCKED` | Cannot verify — missing artifacts, non-reproducible environment. Say what is needed |

## Memory protocol — the part that matters across sessions

Context does not survive between sessions; the repo does. Every review ends by
writing back what was learned, so the next session starts from facts rather
than re-deriving them.

1. **Update `doc/agents/plan-rvpm-bootloader.md`** whenever the phase
   contradicted or refined it. The design doc is the single source of truth
   for the migration — if a fact only lives in a report, it is lost.
   Cite section numbers in the review so the edit is traceable.
2. **Correct the phase prompts** in `doc/agents/prompts/rvpm/` when a prompt
   turned out to be wrong, ambiguous, or to have caused a loop. The next
   phase's prompt inherits the same failure mode otherwise.
3. **Append to `doc/agents/reports/rvpm-review-log.md`** — one row per review:
   date, phase, verdict, the one thing worth remembering. This is the
   migration's memory across sessions; read it first when reviewing.
4. Anything durable about *how the user wants this run* (not about the code)
   goes to Claude's own memory directory, not the repo.

A review that changes nothing on disk has probably not been done properly:
either the design doc needed a correction, or the review log needed a row.

## Shared verification commands

```sh
export RVPM_NO_AUTOUPDATE=1

git -C ~/.config/nvim status --short          # unexpected files?
git -C ~/.config/nvim diff                    # what actually changed
rvpm doctor                                   # static health (add RVPM_APPNAME for phases 1-4)
nvim --headless -c 'qa!' ; echo "exit=$?"     # does Neovim still start
```

`rvpm sync` needs a TTY — `script -qec "rvpm sync" /dev/null`. If a report
claims a sync ran from a non-TTY context without that wrapper, the claim is
false: it fails with `Error: No such device or address (os error 6)`.

## Review report shape

Write the review into the conversation, and the durable parts to disk per the
memory protocol. Structure:

```markdown
## Verdict: ACCEPT | ACCEPT WITH FIXES | REJECT | BLOCKED

## Independently reproduced
| # | criterion | omp claimed | I observed | verdict |

## Findings
| severity | finding | evidence | proposed fix |
severity: CRITICAL (wrong result / data loss) | HIGH (criterion unmet) |
MEDIUM (weak evidence) | LOW (style, docs)

## Negative space
what the prompt forbade, and whether it happened

## Written back
- design doc §X updated: ...
- prompt pN corrected: ...
- review log row appended

## Next
whether the next phase may start, and what it should know
```
