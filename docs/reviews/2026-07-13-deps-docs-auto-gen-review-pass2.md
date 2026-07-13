# Review: deps-docs-auto-gen — pass 2 aggregate

**Subject:** [docs/specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md](../specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md)
**Issue:** [docs/issues/2026-07-13-deps-docs-auto-gen.md](../issues/2026-07-13-deps-docs-auto-gen.md)
**Pass:** 2
**Date:** 2026-07-13
**Letters run:** A (Architecture), C (Plugin loading), D (Devil's advocate) — same as pass 1, per [AGENTS.md](../../AGENTS.md) §4.
**Per-letter reviews:**
- [A — Architecture (pass 2)](2026-07-13-deps-docs-auto-gen-review-pass2-A-architecture.md)
- [C — Plugin loading (pass 2)](2026-07-13-deps-docs-auto-gen-review-pass2-C-plugin-loading.md)
- [D — Devil's advocate (pass 2)](2026-07-13-deps-docs-auto-gen-review-pass2-D-devils-advocate.md)

## Aggregate verdict

**Approve with revisions — one MEDIUM documentation-consistency finding (D-pass2-2, corroborated by A-pass2-1 and A-pass2-2) to close before plan execution; all 5 pass-1 blocking findings RESOLVED, no new CRITICAL/HIGH findings, no regression. Promote to `Approved` once D-pass2-2 is addressed.**

All three reviewers agree the revision resolved the 5 pass-1 blocking findings:
- **A1 (CRITICAL)** — RESOLVED. `require("dpp_min_deps")` is dotless throughout design/spec/issue; resolves to `lua/dpp_min_deps.lua` per `:help lua`. Generated signal in header comment per R8. (A, C, D confirm via grep.)
- **A2/C2/D1-cross (HIGH)** — RESOLVED. Phase 0 hand-edit verified correct against `deps/dpp.toml` file order (toml, local, installer, packspec, protocol-git, protocol-http, denops.vim last). Reviewer-C verified eager-loading `dpp-protocol-http` is safe: `load_plugins` (`dpp_loader.lua:70-78`) only clones + `runtimepath:prepend`, no `:runtime!`, no sourced side effects — symmetric with `dpp-protocol-git` already eagerly loaded today. S7 wording consistent across §1.2/§4 Phase 0/Phase 1 acceptance.
- **A3/D8 (HIGH/MEDIUM)** — RESOLVED. In-body date line gone from §5.7. G3 removed from `09-dev-workflow.md` (line 39 records removal). Q6 resolution revised. No stale references. Spec internally consistent (no G3 vs H5 tension).
- **D1 (HIGH)** — RESOLVED. Issue body widened to 3 goals (drift fix + human-readable docs + generator framework), attributed transparently to pass-1 D1. Check-only alternative explicitly rejected. Reviewer-D confirms the widening reads as a deliberate investment decision, not post-hoc rationalization.
- **D4 (HIGH)** — RESOLVED (with boundary gap — D-pass2-2). `09-dev-workflow.md` slimmed from 19 rules to 5 (R6, R7, R8, R9, H5). The 5 retained rules earn their keep (D-pass2-3 confirms H5 survives the "consequence of R6+R7" critique because the hook relies on it as a named contract). The slim itself is not over-aggressive; the gap is in the *mapping prose*, not the *count*.

No new CRITICAL/HIGH findings emerged from the revision (regression check clean). The one MEDIUM finding (D-pass2-2) is a documentation consistency issue, not a design defect.

## The one MEDIUM finding (D-pass2-2, corroborated by A-pass2-1 + A-pass2-2)

| ID | Severity | Cross | Location | Note | Recommended fix |
|----|----------|-------|----------|------|-----------------|
| D-pass2-2 / A-pass2-1 / A-pass2-2 | MEDIUM | A+D | `09-dev-workflow.md` §3 line 41 (deferred-rules note); design §3.3 I1–I8 | The spec's deferred-rules note claims the 13 deferred rules (R1–R5, R10, G1–G2, G4, H1–H4) are "carried as invariants (I1–I8) in the deps-docs-auto-gen design". This mapping is inaccurate for ~10 of the 13. Only G4→I4, H3→I6, R5≈I7 (partial — `--no-remote` was dropped) are genuinely in I1–I8. The rest are scattered: R1 (scripts/ path) is only in §5.1 module layout (de facto, not invariant); R2 in §2 A4; R3/R4 in §5.1; R10 in §5.6/§5.8 (I8 covers missing-sentinel only); G1 in S2; G2 implied by I3; H1 in §6; H2 in §6 + spec §4; **H4 was negated by D7** (hook now may fetch on first run per I7) — so the spec lists H4 as deferred but it is actually dropped. **R1 is the most consequential gap**: "generators live under `scripts/`" is genuinely cross-cutting (every future generator must live under `scripts/`), not per-generator — it belongs in the spec. | (a) Re-elevate **R1** to `09-dev-workflow.md` §3 as a 6th cross-cutting rule (one line: "generators live under `scripts/`"); (b) remove **H4** from the deferred list (D7 negated it) and add a one-line removal note parallel to the G3 note; (c) correct the deferred-rules note to accurately state where each rule lives ("carried as invariants I1–I8, success criteria S2, or design body text §2/§5/§6") so a reader grep'ing for a rule doesn't conclude it was lost. (a)+(b)+(c) together is the cleanest. |

## Non-blocking findings (polish, optional)

| ID | Severity | Location | Note | Apply? |
|----|----------|----------|------|--------|
| A-pass2-3 | LOW | design §3.1 diagram | `require()` arrow points from `dpp_loader.lua` up to the pre-commit hook box, but the actual require target is `lua/dpp_min_deps.lua` (drawn above-left). Visual polish only; prose is correct. | Yes (cheap) — add a one-line caption under the diagram clarifying the require target. |
| C-pass2-1 | INFO | design §3.3 I7 | "cache strategy does not affect denops's deno" — "cache" could be read as "cache directory" (both processes share `DENO_DIR`). Intended frame is "cache strategy / first-run-fetch behavior". | Yes (cheap) — tighten wording to "pre-caching the generator's `@std/toml` does not pre-cache denops's deps; the two deno processes share `DENO_DIR` but have independent dependency surfaces". |
| C-pass2-2 | INFO | design §1.2 S7 | S7 heading "No plugin-runtime behavior change" could be misread as applying to Phase 0 (which *does* change bootstrap behavior by eagerly loading `dpp-protocol-http`). Body text scopes correctly ("as corrected by Phase 0"). | Yes (cheap) — scope heading to "No plugin-runtime behavior change in Phase 1 (refactor)". |
| D-pass2-7 | LOW | design §4 Phase 3 note | "if preferred" wording could be misread as "the hook is optional". Issue Acceptance goal 3 requires the hook. | Yes (cheap) — tighten to "The hook is installed by default per the issue's Acceptance criteria (goal 3); the manual `deno task gen` path is a fallback for environments where hook installation is impractical, not an equal option." |
| D-pass2-1, D-pass2-3, D-pass2-4, D-pass2-5, D-pass2-6, D-pass2-8, D-pass2-9 | INFO | various | All confirm the corresponding revision decisions are sound (D1 widening convincing, H5 earns its keep, date-line drop correct, `--no-remote` drop net improvement, Phase 0 separate commit justified, Q3/Q5 safe to defer, no new "do not adopt" angle worth adopting). | No action — recorded as verified. |

## Verified premises (no action needed)

- **All 5 pass-1 blocking findings RESOLVED** at the design/spec/issue level (verified by grep + cross-reference of §8 Revision decisions against the actual files). (A, C, D agree.)
- **No new CRITICAL/HIGH finding** emerged from the revision (regression check clean).
- **A2/C2 safety verified by Reviewer-C:** `load_plugins` (`dpp_loader.lua:70-78`) only clones + `runtimepath:prepend` (line 76); no `:runtime!`, no sourced side effects. `dpp-protocol-http` eager-load is symmetric with `dpp-protocol-git` (already eagerly loaded today). `dpp.make_state` input (lines 107/119) unchanged — takes `(dpp_cache_home, dpp_denops_script)`, not the Lua lists.
- **A1 grep clean:** zero stale `dpp_min_deps.generated` / `dpp_min_deps/generated` references outside historical pass-1 review files + the pass-2 prompt (which legitimately names the stale string).
- **D5 trim reachability verified by Reviewer-C:** the 3-line Q7 duplicate-detection check (§5.4) IS reachable in the C-7 scenario (`vim-denops/denops.vim` added to `deps/dpp.toml`) — walked through step-by-step, the `Set(all).size !== all.length` check fires.
- **C8 note accuracy verified:** on classification failure at pre-commit, the generator throws inside `classify()` BEFORE the render/write step; outputs on disk untouched; Neovim startup loads the existing valid module unchanged.
- **D4 slim is not over-aggressive:** the 5 retained rules (R6, R7, R8, R9, H5) are genuinely cross-cutting. H5 earns its keep as a named contract the hook relies on, despite being a consequence of R6+R7.
- **D1 widening is transparent:** attributed to pass-1 D1, check-only alternative explicitly rejected, goal 3 named as speculation not hidden.
- **A3/D8 date-line drop is the right trade-off:** idempotency > glance-ability; GitHub file view exposes "History" button so `git log` is one click away without a clone.
- **D7 `--no-remote` drop is a net improvement:** "first commit silently fetches `@std/toml`" is less surprising than pass-1's "module not found in cache" error; network at commit time is not a new dependency class in a denops-using repo.
- **Phase 0 as a separate commit is justified:** makes S7 "byte-identical" literally true; the smoke test is a meaningful checkpoint before the generator is added.
- **`lua/dpp_min_deps.lua` does not exist yet** — consistent with "to be generated in Phase 1" status.
- **`deps/dpp.toml:35` contains `Shougo/dpp-protocol-http`** — the live drift the design addresses is real.

## Open questions back to author

1. **D-pass2-2 (MEDIUM, blocks promotion):** apply (a)+(b)+(c) — re-elevate R1, remove H4, correct the deferred-rules mapping note? (Recommended; surgical.)
2. **A-pass2-3 / C-pass2-1 / C-pass2-2 / D-pass2-7 (polish):** apply the four cheap wording/diagram fixes in the same revision pass? (Recommended; cheap, no semantic change.)

## Recommended revision path

1. Apply D-pass2-2 fix to `09-dev-workflow.md` (re-elevate R1, remove H4, correct mapping note).
2. Apply the 4 polish items (A-pass2-3 diagram caption, C-pass2-1 I7 wording, C-pass2-2 S7 heading, D-pass2-7 Phase 3 note) to the design.
3. Update design `Status: in-review (pass 2 complete) → Approved`.
4. Update issue Notes with pass-2 outcome.
5. Commit. The design is now `Approved`; the plan phase (`docs/plans/2026-07-13-deps-docs-auto-gen-impl.md`) can begin per [00-document-management.md](../specifications/00-document-management.md) §4 lifecycle.

## Status

- Per-letter pass-2 reviews: `in-review` (A, C, D) — all returned `approve as-is` or `approve with revisions` with no new CRITICAL/HIGH.
- Design: `in-review (pass 1 complete, pass 2 requested)` → promote to `Approved` once D-pass2-2 is applied.
- Issue: stays `open` until the plan is `executed` and a result-log records S1–S7 (revised) met.
