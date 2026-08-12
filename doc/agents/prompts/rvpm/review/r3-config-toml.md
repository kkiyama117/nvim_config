# Claude review — P3: deps/*.toml → rvpm/config.toml

Read `doc/agents/prompts/rvpm/review/README.md` first. Then this.

## What P3 was supposed to produce

`rvpm/config.toml` with all 137 plugins from 14 `deps/*.toml` files, a
re-runnable converter script, and an accounting of every dpp field. The
authoritative field mapping is design doc §5.1.

## Read

1. `doc/agents/reports/rvpm-p3.md`
2. `doc/agents/prompts/rvpm/p3-config-toml.md` and design doc §5.1
3. `rvpm/config.toml` and `scripts/dpp2rvpm.*`
4. `doc/agents/reports/rvpm-review-log.md`

## The traps

| # | Trap | How to detect |
|---|---|---|
| 1 | **Counts do not reconcile.** 137 in = emitted + dropped | Count yourself: `grep -c '^\[\[plugins\]\]' deps/*.toml` vs `rvpm/config.toml`. Every drop needs a name and a reason |
| 2 | **`external_commands` → `build`** | The commonest wrong mapping. dpp treats it as a *gate*: not `executable()` means the plugin is not sourced (`dpp.vim/autoload/dpp/source.vim:138`). Correct target is `cond`, e.g. `cond = "vim.fn.executable('tree-sitter') == 1"`. 3 occurrences: `pi`, `tree-sitter`, `kakehashi` |
| 3 | **`if` / `on_if` mapped to `when`** | `when` is compile-time (evaluated at generate, plugin removed entirely). These conditions are runtime → `cond`. `if = 'exists("$MOCWORD_DATA")'` gating on an env var must still work on a machine where the var appears later |
| 4 | **Fields silently dropped** | The report must list `group` (85), `denops_wait` (2), `rtp` (2) as deliberate drops. Anything unlisted that vanished is a finding |
| 5 | **dpp-ext plugins emitted** | grep `rvpm/config.toml` for `dpp`. `Shougo/dpp.vim` and `dpp-ext-*` must be absent — they are being deleted, not migrated |
| 6 | **`on_lua` fudged** | 1 occurrence, `agentic.nvim`. rvpm has no `on_lua`. The report must state the decision (eager / `on_cmd` / `on_event`) and the reasoning, not quietly pick one |
| 7 | **`[[multiple_hooks]]` swallowed** | 2 occurrences (`deps/ddc.toml:154` → ddc.vim + skkeleton; `deps/ddu.toml` → ddu.vim + vim-gin). They must be handed to P4, listed explicitly, not merged into one plugin's hooks |
| 8 | **Converter not deterministic** | Re-run it. Byte-identical output or it is a finding — non-determinism means the conversion cannot be re-done after a fix |
| 9 | **A full `rvpm sync` was run** | The prompt forbade it; cloning 137 plugins is P5's job. Check `~/.cache/rvpm/nvim/plugins/repos/` is still empty |
| 10 | **`depends` names vs urls** | rvpm accepts either display name or url. `rvpm doctor` resolving `N/N` is the check — a `0/15` would mean the dependency graph silently broke |

## Reproduce

```sh
export RVPM_NO_AUTOUPDATE=1
grep -c '^\[\[plugins\]\]' deps/*.toml | awk -F: '{s+=$2} END{print "dpp:", s}'
grep -c '^\[\[plugins\]\]' rvpm/config.toml
rvpm doctor
grep -n 'build =' rvpm/config.toml        # should be empty or justified
grep -n 'when =' rvpm/config.toml         # compile-time — each needs justification
grep -ni 'dpp' rvpm/config.toml           # should be empty
```

Then re-run the converter to a temp path and `diff` against the committed
output.

## Acceptance to confirm

| # | Criterion |
|---|---|
| 1 | `rvpm doctor` reports no config errors |
| 2 | 137 reconciles: emitted + dropped, every drop justified |
| 3 | `depends cycles — none`, `depends references — N/N`, `on_source typos — none`, `duplicates — none` |
| 4 | all 35 `hooks_file` entries in the P4 handoff table |
| 5 | converter re-runs byte-identically |
| 6 | unmapped-field report empty or every entry decided |

## Write back

- Any mapping decision that differs from design doc §5.1 must be written
  **into** §5.1 — the table is the reference P4 and any future re-run uses.
- Record the `on_lua` decision and the two `[[multiple_hooks]]` resolutions in
  §5.1/§6 D2/D3.
- If the converter revealed a dpp field the design doc never listed, add the
  row. §5.1's counts came from a grep and may have missed something inside
  hook bodies.
- Append the review-log row.
