# Claude review — P1: lazy denops proof

Read `doc/agents/prompts/rvpm/review/README.md` first for the standing rules,
verdicts, and the memory protocol. Then this.

## What P1 was supposed to settle

Under dpp, `denops#plugin#discover()` runs **once** at `DenopsReady` and scans
`runtimepath`. A lazy plugin joins rtp at trigger time — after that scan — so
denops never registers it. That is why skkeleton in `deps/coding.toml` has no
`on_*` trigger today and leans on dpp-ext-lazy's `FuncUndefined` hook instead.

rvpm claims to solve this: at generate time it detects `denops/<name>/main.{ts,js}`
and its `load_lazy` helper calls `denops#plugin#load(name, main_script)` then
`denops#plugin#wait(name, {silent=1})` when the trigger fires. Verified present
in `src/loader.rs` and in the generated loader — see design doc §2.4.

P1 had to show that mechanism works **at runtime**, not just that the code
exists. If it does not, the migration is void and the config stays on dpp.

## Read

1. `doc/agents/reports/rvpm-p1.md`
2. `doc/agents/prompts/rvpm/p1-denops-lazy-proof.md` (what was asked)
3. `~/.config/rvpm/nvim-rvpm/config.toml` (what was actually configured)
4. `~/.cache/rvpm/nvim-rvpm/plugins/loader.lua` (what was actually generated)
5. `doc/agents/reports/rvpm-review-log.md` if it exists

## The traps — check each explicitly

This phase has one question and many ways to appear to answer it.

| # | Trap | How to detect |
|---|---|---|
| 1 | **Asserted the wrong thing.** `_G["rvpm_loaded_<x>"] == true` only proves rvpm ran its own loader. The question is denops registration | The report's post-trigger column must show `denops#plugin#is_loaded("<name>") == 1`. If only the `rvpm_loaded_` flag is shown, the phase proved nothing |
| 2 | **Trigger fired before `DenopsReady`.** Then discovery could have done the registration and rvpm's mechanism is untested | Check the assertion order: server `running` **and** `DenopsReady` fired, *then* pre-checks, *then* trigger |
| 3 | **ddu configured with `on_event = "DenopsReady"`** (copied from the real `deps/ddu.toml`) instead of `on_cmd = ["Ddu"]` | Read the test `config.toml` directly. A `DenopsReady` trigger coincides with discovery and proves nothing |
| 4 | **The plugin was never lazy.** rvpm infers `lazy` from `on_*`; a config error can leave it eager, and eager plugins register via discovery | Grep the generated `loader.lua` for the plugin: it must appear in a trigger registration (phase 7), not in the eager block (phase 6) |
| 5 | **denops never came up.** Then `is_loaded` is 0 everywhere for a boring reason, and a FAIL verdict would be wrong | `denops#server#status()` must be recorded as `running`. Check deno resolves — `command -v deno` or the mise fallback path |
| 6 | **Contaminated environment.** The real `~/.config/rvpm/nvim/` or the real `init.lua` was touched | `git diff init.lua` empty; `ls -la ~/.config/rvpm/nvim/` still just the 75-byte stub |
| 7 | **Fell back to the escape hatch without saying so.** The prompt allowed two fallbacks (`merge = true`, or a hand-written `after.lua` calling `denops#plugin#load`). If fallback 2 was used, rvpm's native mechanism did **not** work | The verdict changes meaning: native support vs. we-have-to-hand-write-a-hook for ~80 denops plugins. Make sure the report distinguishes these |

## Reproduce it yourself

Do not take the report's word. Re-run the assertion script it left behind:

```sh
export RVPM_NO_AUTOUPDATE=1 RVPM_APPNAME=nvim-rvpm
rvpm doctor
# then the report's own nvim invocation, verbatim
```

Then vary one thing to make sure the result is real: pick one of the three
plugins, confirm from `loader.lua` that it is in the lazy path, and check the
pre-trigger `is_loaded` is genuinely `0` in a fresh session. A test that
passes because the plugin was already loaded is not a test.

## Acceptance to confirm

| # | Criterion | Confirmed how |
|---|---|---|
| 1 | denops `running` + `DenopsReady` fired before any trigger | report + re-run |
| 2 | pre-trigger: `rvpm_loaded_` nil **and** `is_loaded == 0`, for all three | re-run |
| 3 | trigger actually fired (not simulated by calling the load function directly) | read the script |
| 4 | post-trigger: `rvpm_loaded_ == true` **and** `is_loaded == 1`, for all three | re-run |
| 5 | skkeleton is lazy via `on_map`, ddu via `on_cmd`, ddc via `on_event` | test `config.toml` + generated `loader.lua` |

Criterion 4 for all three is the gate. Two out of three is a REJECT, not a
partial pass — ddu and ddc represent ~75 plugins each in the real config.

## Write back (memory protocol)

- If P1 passed via rvpm's native mechanism: update design doc §6 to strike D1
  entirely and record the runtime evidence, not just the source-code evidence.
- If P1 passed only via a hand-written `after.lua`: that is a **new
  requirement for P4**, not a footnote. Update design doc §5.2 and
  `p4-hooks.md` to make the hook mandatory for every denops plugin, and
  re-estimate the work.
- If P1 failed: update design doc §1 and §9 to record the migration as
  aborted, with the evidence. Do not leave the plan reading as if it is live.
- Append the review-log row either way.
- Note in the log whether the `nvim-rvpm` test appname should be kept for
  later phases (P5 reuses the same assertions against the real config).
