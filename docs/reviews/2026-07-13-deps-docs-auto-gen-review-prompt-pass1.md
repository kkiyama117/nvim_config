# Review prompt — deps-docs-auto-gen (pass 1)

**Subject:** [docs/specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md](../specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md)
**Issue:** [docs/issues/2026-07-13-deps-docs-auto-gen.md](../issues/2026-07-13-deps-docs-auto-gen.md)
**Date opened:** 2026-07-13
**Pass:** 1
**Required letters:** A + C + D (per [AGENTS.md](../../AGENTS.md) §4 — design touches startup order and plugin loading)

## Common output format

Each per-letter review follows the schema in [AGENTS.md](../../AGENTS.md) §4.1:

```markdown
# Review: deps-docs-auto-gen — Reviewer-<X> <perspective name>

Reviewed: <relative path to design>
Reviewer: <name / model>
Date: 2026-07-13
Status: in-review | addressed | blocked

## Verdict
<1–2 paragraphs. "approve as-is" / "approve with revisions" / "block on X">

## Findings

| ID | Severity | Status | Location | Note |
|----|----------|--------|----------|------|
| <X1> | <CRITICAL|HIGH|MEDIUM|LOW|INFO> | open | §x.y | 1–3 sentences |

## Verified premises (no action needed)
- …

## Open questions back to author
- …
```

- **Severity**: `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` / `INFO` (definitions in [AGENTS.md](../../AGENTS.md) §4.1).
- Findings ID format: `<letter><n>` (e.g. `A1`, `C2`, `D3`). Cross-cutting findings may be tagged like `A4 (cross: C)`.
- Each finding's `Location` must be a section anchor of the design (e.g. `§3.2`, `§5.4`, `I5`).
- Reviewers may read any file in the repo; the per-letter "What to read" list below is the minimum.
- Reviewers must not edit the design or any source file. Read-only.

## Reviewer-A — Architecture

- **Role:** module boundaries / `lua/` responsibility split / invariants of startup order.
- **What to read (minimum):**
  - Subject design §1, §3 (architecture, invariants I1–I8), §5.1 (module layout), §7 resolved Q1/Q2/Q4/Q6/Q7.
  - [lua/dpp_loader.lua](../../lua/dpp_loader.lua) — current minimum_deps/normal_deps usage and `initialize_dpp()` call order.
  - [init.lua](../../init.lua) — `vim.loader.enable()` and `require('dpp_loader')` insertion point.
  - [docs/specifications/09-dev-workflow.md](../specifications/09-dev-workflow.md) — new normative spec this design introduces.
- **Evaluation points:**
  - A-1. Does `lua/dpp_min_deps.generated.lua` as a pure-data `require()`d module preserve startup order (I5)? Trace the call sequence: `init.lua` → `require('dpp_loader')` → `require('dpp_min_deps.generated')` → `initialize_dpp()`. Is there any new side effect, autocmd, or async boundary?
  - A-2. Is the module boundary between `scripts/` (generator) and `lua/` (consumer) clean? Does any invariant leak generator knowledge into `lua/` or vice versa?
  - A-3. Are I1–I8 actually invariants — i.e. would any reasonable change violate them silently? Pay special attention to I2 (idempotency) and I7 (no network at run time given JSR cache pre-population).
  - A-4. Is the classification rule (§3.2 `MINIMUM_REPOS`) encoded in exactly one place, or does it leak into multiple files (design, script, generated Lua, 09-dev-workflow.md)?
  - A-5. Does `09-dev-workflow.md` belong at `docs/specifications/` (normative) or would `docs/references/` (non-normative) be a better fit given there is currently only one generator?
  - A-6. Is the §4 4-phase split architecturally coherent — i.e. is each phase independently revertable as claimed?
- **Expected output:** per schema above; verdict + findings table + verified premises + open questions.

## Reviewer-C — Plugin loading semantics

- **Role:** dpp.vim toml/rtp/depends/lazy, denops startup, `after/` and `ftplugin/` fire order.
- **What to read (minimum):**
  - Subject design §3.2 (classification rule), §5.3–§5.6 (TOML parsing, classification impl, Lua rendering, README rendering), §5.9 (exit codes), I4/I5.
  - [deps/dpp.toml](../../deps/dpp.toml), [deps/denops.toml](../../deps/denops.toml), [deps/neovim.toml](../../deps/neovim.toml), [deps/merge.toml](../../deps/merge.toml) — full plugin set.
  - [lua/dpp_loader.lua](../../lua/dpp_loader.lua) — how `minimum_deps`/`normal_deps` are consumed by `dpp#load_state` / `dpp#make_state`.
  - [docs/references/dpp-hooks-file.md](../references/dpp-hooks-file.md), [docs/references/dpp-config-return.md](../references/dpp-config-return.md), [docs/references/denops-dpp.md](../references/denops-dpp.md), [docs/references/dpp-context-builder.md](../references/dpp-context-builder.md) — dpp/denops semantics referenced by the design.
  - [deps/README.md](../../deps/README.md) — existing sentinel markers.
- **Evaluation points:**
  - C-1. Is the `minimum_deps` = `{Shougo/dpp.vim, Shougo/dpp-ext-lazy}` / `normal_deps` = rest-of-dpp.toml + `vim-denops/denops.vim` split (§3.2) actually correct vs. how `dpp_loader.lua` currently uses these two lists to bootstrap dpp before denops is up?
  - C-2. Does the generated Lua module change what dpp.vim receives as input (S7)? I.e. is `dpp#make_state`'s input byte-identical before and after the refactor — same repos, same order, same `rtp`/`depends`/`on_*` fields? (Note: the generated module only carries repo strings, not the full plugin entries. Confirm `dpp_loader.lua` only consumes repo strings from these lists and reads full entries from TOML at `make_state` time.)
  - C-3. Are all `dpp-ext-*` plugins in `deps/dpp.toml` correctly classified? In particular, does `rtp = ''` on `dpp.vim` and `dpp-ext-lazy` matter for the minimum/normal split, or is it orthogonal?
  - C-4. The `denops.vim` injection into `normal_deps` from a different TOML (`deps/denops.toml`) — does this match the current hand-maintained behavior in `dpp_loader.lua` exactly (same position, same list)?
  - C-5. Does `--no-remote` + JSR cache approach interact with denops's own deno invocation (a separate deno process spawned by `denops.vim`)? Are there two deno caches / two deno binaries in play, and does the design account for that?
  - C-6. Sentinel block rewrite in `deps/README.md` — could it interfere with the `dpp-ext-toml` `CursorHold */rc/*.toml` syntax hook (note: the path glob is `rc/*.toml`, not `deps/*.toml`)? Any other autocmd that touches `deps/README.md` or `deps/*.toml` at startup?
  - C-7. The §5.4 Q7 assertion rejects a `dpp.toml` repo that appears in `denops.toml` as `denops.vim` and is also classified. Is there a real scenario where a future maintainer adds `vim-denops/denops.vim` to `dpp.toml` (e.g. for eager load), and would the assertion's "classified twice" error correctly catch it?
  - C-8. Exit code 6 (classification inconsistency) — is this the right severity, or should a classification failure be CRITICAL (startup-breaking) rather than a runtime script error?
- **Expected output:** per schema above. Verify each evaluation point against the actual `dpp_loader.lua` source and dpp reference docs; cite line numbers where relevant.

## Reviewer-D — Devil's advocate

- **Role:** alternatives / YAGNI / serious proposal of "do not adopt" options.
- **What to read (minimum):**
  - Subject design §2 (alternatives A1–A8), §4 (4-phase split), §7 (Q3/Q5 still open), §1.3 (out of scope).
  - [docs/specifications/09-dev-workflow.md](../specifications/09-dev-workflow.md) — the new normative spec with R1–R10, G1–G4, H1–H5.
  - [deps/README.md](../../deps/README.md) — the actual size of the problem (3 TODOs, ~10 plugins in dpp.toml).
- **Evaluation points:**
  - D-1. Is the whole generator worth building at all? Seriously propose the "do not adopt" option: keep `dpp_loader.lua` hand-maintained, add a `make check` target that diffs the Lua tables against `deps/dpp.toml` via a 20-line script. What is lost? What is saved?
  - D-2. Is the 4-phase split (§4) over-engineered for a single-file generator? Could it be 1 or 2 phases?
  - D-3. Is the pre-commit hook worth the onboarding cost (`scripts/install-hooks.sh`, `deno task cache`, symlink management) vs. just running `deno task gen` manually before commit + a CI check later?
  - D-4. Is `09-dev-workflow.md` (a normative spec with 19 rules R/G/H) premature when there is currently exactly one generator? YAGNI: which rules would survive a 6-month freeze on new generators and which are speculative?
  - D-5. Is the Q7 assertion (§5.4) belt-and-suspenders when the classification predicate (`filter(!MINIMUM_REPOS.has)`) already covers the "every repo classified" property? Is the "classified twice" check reachable at all given the predicate structure?
  - D-6. Are Q3 (CI) and Q5 (`@std/toml` newline preservation) safe to defer to Phase 1, or should either block design approval?
  - D-7. Is `deno task cache` as a separate onboarding step a UX hazard (fresh clone → first commit fails with a confusing "module not found in cache" error)?
  - D-8. Is the in-body `Last updated: YYYY-MM-DD` line (§5.7, G3) going to cause noisy diffs on every regeneration, undermining the "no-op when inputs unchanged" property (H5)? Specifically: does the date change even when `deps/*.toml` is unchanged, because the script runs on a different day?
- **Expected output:** per schema above. At least one finding must seriously propose a "do not adopt" or "shrink scope" option with a concrete alternative.

## Aggregation

After A, C, D complete, the design author (or an aggregator agent) writes [docs/reviews/2026-07-13-deps-docs-auto-gen-review-pass1.md](2026-07-13-deps-docs-auto-gen-review-pass1.md) integrating the three per-letter reviews into the final view used for the next design revision.
