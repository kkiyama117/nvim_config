# Review prompt — deps-docs-auto-gen (pass 2)

**Subject:** [docs/specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md](../specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md)
**Issue:** [docs/issues/2026-07-13-deps-docs-auto-gen.md](../issues/2026-07-13-deps-docs-auto-gen.md)
**Date opened:** 2026-07-13
**Pass:** 2
**Required letters:** A + C + D (same as pass 1 — design touches startup order and plugin loading, per [AGENTS.md](../../AGENTS.md) §4)
**Prior pass:** [pass 1 aggregate](2026-07-13-deps-docs-auto-gen-review-pass1.md) — [A](2026-07-13-deps-docs-auto-gen-review-pass1-A-architecture.md) / [C](2026-07-13-deps-docs-auto-gen-review-pass1-C-plugin-loading.md) / [D](2026-07-13-deps-docs-auto-gen-review-pass1-D-devils-advocate.md)

## Pass-2 scope

Pass 2 is a **regression-and-resolution check**, not a fresh review. Reviewers verify:

1. Each pass-1 **blocking** finding (A1, A2/C2/D1-cross, A3/D8, D1, D4) is RESOLVED in the revised design (see design §8 Revision decisions).
2. The non-blocking findings (A4, A5, A6, A7, C4, C5, C8, D2, D3, D5, D6, D7) are addressed without introducing new issues.
3. No **new** CRITICAL / HIGH findings have emerged from the revision itself (regression check).
4. The slimmed `09-dev-workflow.md` (5 rules: R6, R7, R8, R9, H5) is internally consistent and the deferred-rules boundary is clean.

If all blocking findings are RESOLVED and no new CRITICAL/HIGH findings emerge, the reviewer's verdict is `approve as-is`. If a pass-1 blocking finding is only partially addressed, or a regression appears, the verdict is `approve with revisions` or `block on X` and a new finding is logged with ID `<letter>-pass2-<n>`.

## Pass-1 blocking findings to verify RESOLVED

| ID | Pass-1 fix claimed (design §8) | What to verify |
|----|-------------------------------|----------------|
| **A1** (CRITICAL) | `lua/dpp_min_deps.lua` + `require("dpp_min_deps")` (dot-less). | Every occurrence of the old dotted name is gone from design, `09-dev-workflow.md` §4, and issue. `require("dpp_min_deps")` resolves to `lua/dpp_min_deps.lua` per `:help lua`. The "generated" signal is now in the header comment, not the filename. |
| **A2/C2/D1-cross** (HIGH) | Phase 0 added: hand-edit `dpp_loader.lua` to add `dpp-protocol-http` + reorder to TOML order, smoke-test. Phase 1 generator then produces byte-identical lists. S7 updated to reference Phase 0. | §4 Phase 0 acceptance is concrete (smoke test). S7 wording is consistent with the split. Phase 1 acceptance references post-Phase-0 tables (not "previous hand-maintained"). C4 (denops.vim position) is folded in. |
| **A3/D8** (HIGH/MEDIUM) | In-body `Last updated:` date line dropped from §5.7. G3 removed from `09-dev-workflow.md`. Q6 resolution revised. | §5.7 has no date line. `09-dev-workflow.md` has no G3. Q6 resolution in §7 reflects the drop. No other file carries a stale date-line reference. |
| **D1** (HIGH) | Full generator adopted. Issue body widened to 3 goals. | Issue Problem + Acceptance criteria list goals 2 (human-readable docs) and 3 (generator framework). The check-only alternative is explicitly rejected. |
| **D4** (HIGH) | `09-dev-workflow.md` slimmed to 5 rules (R6, R7, R8, R9, H5). Per-generator rules deferred to design invariants I1–I8. | `09-dev-workflow.md` §3 contains only the 5 rules. The deferred-rules list is complete and matches what the design carries as invariants. No rule is duplicated across both files in a way that could drift. |

## Common output format

Same schema as pass 1 (per [AGENTS.md](../../AGENTS.md) §4.1):

```markdown
# Review: deps-docs-auto-gen pass 2 — Reviewer-<X> <perspective name>

Reviewed: <relative path to design>
Reviewer: <name / model>
Date: 2026-07-13
Pass: 2
Status: in-review | addressed | blocked

## Verdict
<1–2 paragraphs. "approve as-is" / "approve with revisions" / "block on X".
Explicitly state for each pass-1 blocking finding whether it is RESOLVED.>

## Pass-1 blocking findings — resolution status

| ID | Pass-1 severity | Pass-2 status | Note |
|----|-----------------|---------------|------|
| A1 | CRITICAL | RESOLVED / REGRESSION / INCOMPLETE | 1–3 sentences |
| A2/C2/D1-cross | HIGH | … | … |
| A3/D8 | HIGH/MEDIUM | … | … |
| D1 | HIGH | … | … |
| D4 | HIGH | … | … |

## New findings (pass 2 only)

| ID | Severity | Status | Location | Note |
|----|----------|--------|----------|------|
| <X-pass2-1> | <CRITICAL|HIGH|MEDIUM|LOW|INFO> | open | §x.y | 1–3 sentences |

## Verified premises (no action needed)
- …

## Open questions back to author
- …
```

- New findings use ID format `<letter>-pass2-<n>` (e.g. `A-pass2-1`, `C-pass2-1`).
- Reviewers may read any file in the repo; the per-letter "What to read" list below is the minimum.
- Reviewers must not edit the design or any source file. Read-only.

## Reviewer-A — Architecture (pass 2)

- **Role:** module boundaries / `lua/` responsibility split / invariants of startup order.
- **What to read (minimum):**
  - Revised design §1.2 (S2, S5, S6, S7), §3.1 diagram, §3.3 invariants (I1, I3, I4, I5, I7), §4 (Phase 0–3 split + revert order note), §5.1 (deno.json), §5.5 (Lua rendering), §6 (hook), §8 Revision decisions.
  - [lua/dpp_loader.lua](../../lua/dpp_loader.lua) — confirm `require("dpp_min_deps")` would resolve and the Phase 0 drift fix (add `dpp-protocol-http`, reorder to TOML order) is the right hand-edit.
  - [lua/dpp_min_deps.lua](../../lua/dpp_min_deps.lua) — _does not exist yet_; verify the design's §5.5 sample output matches what Phase 1 will produce.
  - [docs/specifications/09-dev-workflow.md](../specifications/09-dev-workflow.md) — the slimmed 5-rule spec.
- **Evaluation points (pass 2):**
  - A-pass2-1. **A1 regression check:** grep the design + spec + issue for any stale `dpp_min_deps.generated` / `require("dpp_min_deps.generated")` / `lua/dpp_min_deps.generated.lua`. Confirm zero occurrences outside the pass-1 review files (which are historical and must not be edited).
  - A-pass2-2. **A1 positive check:** `require("dpp_min_deps")` resolves to `lua/dpp_min_deps.lua` per `:help lua` (no dot → direct filename match). The header comment `-- AUTO-GENERATED by scripts/gen_deps.ts — do not edit by hand.` carries the generated signal (per R8).
  - A-pass2-3. **A5 revert order:** §4 states phases are *sequentially* revertable (Phase 3 → 2 → 1 → 0) and that Phase 3 hook must be disabled before reverting earlier phases. Is this guidance complete and correct?
  - A-pass2-4. **A6 assert:** §4 Phase 1 includes `assert(deps and deps.minimum_deps and deps.normal_deps, "dpp_min_deps missing fields")`. Is this the right shape? Does it fire early enough to prevent a silent `nil` from reaching `load_plugins`?
  - A-pass2-5. **A7 MINIMUM_REPOS scope:** §3.2 now says "encoded once in code" with prose restatements noted as illustrative. Is the qualifier sufficient to prevent a future reader from treating prose as a second source of truth?
  - A-pass2-6. **D4 spec slim:** `09-dev-workflow.md` carries only R6/R7/R8/R9/H5. The deferred rules (R1–R5, R10, G1–G2, G4, H1–H4) are listed as "carried as invariants I1–I8 in the deps-docs-auto-gen design". Verify this mapping is accurate (no rule is lost, no rule is duplicated in a way that could drift).
  - A-pass2-7. **D7 cache UX:** `--no-remote` dropped from `gen` task and I7. Deno's default HTTP cache is relied upon. Is I7's wording about the generator's deno vs. denops's separate deno process (C5) clear and correct?
  - A-pass2-8. **Phase 0 coherence:** is the Phase 0 hand-edit (add `dpp-protocol-http`, reorder to TOML order) the *minimal* edit that makes Phase 1 mechanical? Or does it include unrelated reordering that should be called out separately?
- **Expected output:** per schema above. Verdict must explicitly state A1 / A2-C2 / A3-D8 / D1 / D4 resolution status + any new findings.

## Reviewer-C — Plugin loading semantics (pass 2)

- **Role:** dpp.vim toml/rtp/depends/lazy, denops startup, `after/` and `ftplugin/` fire order.
- **What to read (minimum):**
  - Revised design §3.2 (classification), §4 Phase 0 + Phase 1 acceptance, §5.3–§5.5 (TOML parsing, classification, Lua rendering), §5.9 (exit codes + C8 note), I4/I5/I7.
  - [deps/dpp.toml](../../deps/dpp.toml) (line 35: `dpp-protocol-http`), [deps/denops.toml](../../deps/denops.toml), [lua/dpp_loader.lua](../../lua/dpp_loader.lua) (lines 29-36 current `normal_deps`, line 99 `load_plugins(normal_deps)`, line 100 `ensure_denops_plugin()`, lines 107/119 `dpp.make_state`).
  - [docs/references/dpp-hooks-file.md](../references/dpp-hooks-file.md), [docs/references/dpp-config-return.md](../references/dpp-config-return.md), [docs/references/denops-dpp.md](../references/denops-dpp.md).
- **Evaluation points (pass 2):**
  - C-pass2-1. **A2/C2 resolution:** Phase 0 hand-edits `dpp_loader.lua` to add `dpp-protocol-http` and reorder to TOML order. Is this hand-edit *correct* — i.e. does the post-Phase-0 `normal_deps` list exactly match what §5.5's generated sample shows (toml, local, installer, packspec, protocol-git, protocol-http, denops.vim)? Confirm against `deps/dpp.toml` file order.
  - C-pass2-2. **A2/C2 safety:** is eagerly loading `dpp-protocol-http` at bootstrap (via `load_plugins(normal_deps)`) safe? `dpp-protocol-http` is an http fetch protocol for dpp-ext-installer; does loading it before `dpp.make_state` have any side effect vs. the current lazy behavior? (Note: today it is *not* in `normal_deps` at all, so it is not eagerly loaded today. Phase 0 changes that.)
  - C-pass2-3. **C4 fold-in:** denops.vim stays last in `normal_deps` (Phase 0 + §5.5 agree). `ensure_denops_plugin()` at `dpp_loader.lua:100` needs denops.vim on rtp immediately after `load_plugins(normal_deps)`. Confirm Phase 0 preserves this.
  - C-pass2-4. **C5 scope:** I7 now notes `--no-remote` (now dropped) applied only to the generator's deno, not denops's separate deno. With `--no-remote` dropped entirely, is the C5 note still accurate? It should now read as "the generator's deno uses the default HTTP cache; denops's deno is a separate process with its own deps and cache". Verify the wording.
  - C-pass2-5. **C8 note:** §5.9 now notes exits 4 and 6 are generation-time guards. Is the claim "the existing generated module on disk continues to be `require()`d at the top of `dpp_loader.lua` and Neovim starts unchanged" accurate when a classification failure happens at pre-commit time?
  - C-pass2-6. **D5 trim:** §5.4 Q7 assertion trimmed from 20 lines to 3 (only duplicate detection). Is the trimmed assertion still reachable in the scenario where `vim-denops/denops.vim` is added to `deps/dpp.toml` (the C-7 scenario from pass 1)? Walk through the code.
  - C-pass2-7. **S7 wording:** S7 now says "byte-identical to the hand-maintained lists **as corrected by Phase 0**". Is this internally consistent with §4 Phase 0 acceptance and Phase 1 acceptance?
- **Expected output:** per schema above. Verdict must explicitly state A2/C2 resolution status (with the safety check on eager `dpp-protocol-http` loading) + any new findings.

## Reviewer-D — Devil's advocate (pass 2)

- **Role:** alternatives / YAGNI / serious proposal of "do not adopt" options. In pass 2, also check whether the revision over-corrected (e.g. slimming the spec too far, dropping a rule that was actually needed).
- **What to read (minimum):**
  - Revised design §2 (alternatives — unchanged), §4 (4 phases), §7 (Q3/Q5 still open), §8 Revision decisions (all 5 blocking + 12 non-blocking applied).
  - [docs/specifications/09-dev-workflow.md](../specifications/09-dev-workflow.md) — the slimmed 5-rule spec.
  - [docs/issues/2026-07-13-deps-docs-auto-gen.md](../issues/2026-07-13-deps-docs-auto-gen.md) — widened scope.
- **Evaluation points (pass 2):**
  - D-pass2-1. **D1 resolution:** issue body widened to 3 goals. Is the justification for the full generator now *convincing* (i.e. does the widened scope actually re-justify the cost), or does it read as a post-hoc rationalization? Would a future reader accept it?
  - D-pass2-2. **D4 resolution — over-slim?** `09-dev-workflow.md` went from 19 rules to 5. Is the spec now *too* thin — i.e. are any of the deferred rules (R1–R5, R10, G1–G2, G4, H1–H4) actually cross-cutting in a way the design missed? Specifically: is R1 (generators live under `scripts/`) genuinely per-generator, or is it a cross-cutting invariant that belongs in the spec?
  - D-pass2-3. **D4 resolution — under-slim?** Conversely, do the 5 remaining rules (R6, R7, R8, R9, H5) actually earn their keep, or is this still premature for a one-generator repo? (D-pass1 argued 8 of 10 "earn their keep" rules were design invariants; does H5 survive that critique?)
  - D-pass2-4. **A3/D8 resolution:** dropping the date line entirely. Is `git log docs/references/deps-list.md` actually a sufficient substitute for an in-doc "when was this regenerated" signal? Consider a reader who has the doc open in a browser/GitHub UI and no local clone.
  - D-pass2-5. **D7 resolution:** dropping `--no-remote`. Does this introduce a *new* UX hazard — a pre-commit hook that silently fetches from JSR on first run (network dependency at commit time)? Is that better or worse than the pass-1 "module not found in cache" error?
  - D-pass2-6. **D2 resolution:** phases went from 5 to 4 (Phase 0 + 1–3). Is Phase 0 (hand-edit drift fix) actually a separate commit's worth of work, or could it fold into Phase 1?
  - D-pass2-7. **D3 resolution:** Phase 3 hook note says it can be disabled for solo maintainer. Is this note strong enough, or does the issue Acceptance criteria (goal 3: generator framework) *require* the hook to be installed, making the note contradictory?
  - D-pass2-8. **Open questions Q3/Q5:** still open. Are they safe to defer to plan/execution, or should either block design approval now?
  - D-pass2-9. **New scope challenge (optional):** with the issue widened to 3 goals, is there a *new* "do not adopt" angle — e.g. "the generator framework goal is speculative; adopt the generator for goals 1+2 but defer 09-dev-workflow.md entirely until a second generator is real"? Argue both sides briefly.
- **Expected output:** per schema above. At least one finding must either (a) confirm D1/D4 resolution is sound, or (b) seriously propose the revision over-corrected (slimmed too far / dropped a needed rule / widened scope unjustifiably).

## Aggregation

After A, C, D complete, the design author (or an aggregator agent) writes [docs/reviews/2026-07-13-deps-docs-auto-gen-review-pass2.md](2026-07-13-deps-docs-auto-gen-review-pass2.md) integrating the three per-letter pass-2 reviews. If all blocking findings are RESOLVED and no new CRITICAL/HIGH findings emerge, the design is promoted `in-review → Approved` and the plan phase begins.
