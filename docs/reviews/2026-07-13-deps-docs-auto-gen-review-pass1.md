# Review: deps-docs-auto-gen — pass 1 aggregate

**Subject:** [docs/specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md](../specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md)
**Issue:** [docs/issues/2026-07-13-deps-docs-auto-gen.md](../issues/2026-07-13-deps-docs-auto-gen.md)
**Pass:** 1
**Date:** 2026-07-13
**Letters run:** A (Architecture), C (Plugin loading), D (Devil's advocate) — per [AGENTS.md](../../AGENTS.md) §4 requirement for designs touching startup order + plugin loading.
**Per-letter reviews:**
- [A — Architecture](2026-07-13-deps-docs-auto-gen-review-pass1-A-architecture.md)
- [C — Plugin loading](2026-07-13-deps-docs-auto-gen-review-pass1-C-plugin-loading.md)
- [D — Devil's advocate](2026-07-13-deps-docs-auto-gen-review-pass1-D-devils-advocate.md)

## Aggregate verdict

**Block on 4 findings (A1, A2/C2/D1-cross, A3/D8, D1-or-widen-scope, D4); approve with revisions on the rest.**

The architectural shape (single TOML source of truth → pure-data generated Lua module → `require()` in `dpp_loader.lua` → pre-commit freshness hook) is sound and the module boundary between `scripts/` and `lua/` is clean. Reviewer-C verified the strict claim that `dpp#make_state`'s input is byte-identical before and after (it consumes only `(dpp_cache_home, dpp_denops_script)`, not the Lua lists). Reviewer-A confirmed `09-dev-workflow.md` belongs at `docs/specifications/` (normative), not `references/`. Reviewer-D confirmed the chosen alternative (Deno + `@std/toml`) is defensible.

However, four issues must be resolved before promotion to `Approved`. Two are CRITICAL/HIGH correctness bugs in the design as written (A1, A2); one is a scope/justification challenge that requires an author decision (D1); one is a spec-prematureness challenge that requires an author decision (D4). A3/D8 (the `Last updated` date line) is a trivial fix but blocks because it makes the spec internally inconsistent (G3 vs H5).

## Blocking findings (must address before Approved)

| ID | Severity | Cross | Location | Note | Recommended fix |
|----|----------|-------|----------|------|-----------------|
| A1 | CRITICAL | — | §5.5, §3.1, §4 Phase 2, I4/I5, S2; `09-dev-workflow.md` §4 | `require("dpp_min_deps.generated")` resolves to `lua/dpp_min_deps/generated.lua` (Neovim treats `.` as a directory separator), not `lua/dpp_min_deps.generated.lua` as the design places it. `init.lua:41` calls `require('dpp_loader')` unprotected, so the error aborts init before `filetype indent plugin on` / `syntax on` (`init.lua:43-44`). I5 is false as written. | Pick one: (a) move file to `lua/dpp_min_deps/generated.lua`, keep dotted require; (b) rename module to `dpp_min_deps_generated` (underscore), file at `lua/dpp_min_deps_generated.lua`. Update S2, S5, §3.1, §5.1, §5.5, §6, `09-dev-workflow.md` §4 in lockstep. (b) is fewer moving parts. |
| A2 / C2 / D1-cross | HIGH | A+C+D | §1.2 S7, §4 Phase 2 Acceptance, §5.5; `deps/dpp.toml:35`; `lua/dpp_loader.lua:29-36,99` | Generated `normal_deps` (§5.5) reconciles live drift: adds `Shougo/dpp-protocol-http` (in `dpp.toml:35`, missing from `dpp_loader.lua:29-36`) and reorders to TOML order. `load_plugins(normal_deps)` (`dpp_loader.lua:99`) will clone + rtp-prepend one more plugin in a different order than today. S7's heading "No plugin-runtime behavior change" is false; Phase 2 Acceptance "prints the same two lists as the previous hand-maintained tables" cannot pass. **The strict sub-claim ("`dpp#make_state` input byte-identical") IS true** (C verified: `dpp#make_state` takes `(dpp_cache_home, dpp_denops_script)`, not the Lua lists; the Lua lists only feed `load_plugins` for clone+rtp-prepend). | Pick one: (i) split into a pre-refactor commit that hand-fixes `dpp_loader.lua` drift (add `dpp-protocol-http`, reorder to TOML order, smoke-test), then the refactor is mechanical and S7 holds literally; (ii) keep as one commit but revise S7 + Phase 2 Acceptance to explicitly acknowledge the drift fix and require Reviewer-C sign-off that eagerly loading `dpp-protocol-http` at bootstrap is safe. (i) is cleaner; (ii) is fewer commits. |
| A3 / D8 | HIGH/MEDIUM | A+D | §5.7, I2, `09-dev-workflow.md` G3+H5 | `Last updated: YYYY-MM-DD` from `new Date().toISOString().slice(0,10)` breaks I2/H5 idempotency: running the script on day N+1 with `deps/*.toml` unchanged rewrites the date line → `git diff --exit-code` non-zero → pre-commit hook blocks unrelated commits. `09-dev-workflow.md` is internally inconsistent (G3 mandates the date line, H5 mandates no-op on unchanged inputs — they cannot both hold). | Drop the in-body `Last updated:` line entirely (D8's recommendation, one-line fix). `git log docs/references/deps-list.md` already records the last-changed date. Remove G3 from `09-dev-workflow.md`; update §5.7 and the Q6 resolution in §7 to match. (Alternative: derive date from max mtime of source TOMLs, or preserve existing date when non-date content is unchanged — both are more code for little gain.) |
| D1 | HIGH | — | §2, §1.2, §4, §1.3; issue body | The issue's stated problem ("two copies of truth drift silently") is solvable with a ~20-line drift-check script (sketched in [D review](2026-07-13-deps-docs-auto-gen-review-pass1-D-devils-advocate.md#d1--sketch-of-the-do-not-adopt-alternative)) and zero generated artifacts. The design's extra cost (generated Lua module, sentinel-rewritten README, reference doc, pre-commit hook, 19-rule normative spec, 4-phase split) is justified only by "human-readable docs" and "generator framework" goals that are **not** in the issue's acceptance criteria. | Author decision: either (a) adopt the D1 shrink-scope alternative (check-only script, no generation); or (b) explicitly widen the issue body to include "generate human-readable plugin docs (S1/S4)" and "establish a generator framework for future scripts" as goals, and re-justify the cost. The current issue body frames the problem as drift only. |
| D4 | HIGH | — | `09-dev-workflow.md` §3.1–§3.3 | 19 normative rules (R1–R10, G1–G4, H1–H5) for a repo with exactly one generator is premature generalization. Per D's per-rule audit: ~10 earn their keep now (but 8 are design invariants that could live in the design doc), ~7 are speculative, 2 (G3, H5) are in direct tension (see A3/D8). | Author decision: either (a) demote to `docs/references/dev-workflow.md` (non-normative, descriptive of the current single generator); or (b) keep at `specifications/` but slim to ~5 genuinely cross-cutting rules (R6/R7/R8/R9 cluster + H5), moving the rest into the design's invariants section. Defer R2/R4/H1/H2 etc. until a second generator is added. |

## Non-blocking findings (should address in revision)

| ID | Severity | Location | Note |
|----|----------|----------|------|
| A4 | MEDIUM | §3.3 I1 vs §5.6 | I1 ("never reads `deps/README.md`") is contradicted by the §5.6 sentinel-rewrite (which reads `deps/README.md` to locate markers). Scope I1 to "never reads as a *source of plugin data*; reads to locate sentinel markers only are permitted". |
| A5 | MEDIUM | §4 | "Each phase independently revertable" is too strong. Phase 4 hook would block every commit if Phase 2/3 are reverted (gen task fails or regenerates untracked files → `git diff` non-zero). State explicitly: phases are *sequentially* revertable (revert Phase 4 first, then 3 → 2 → 1). |
| D2 | MEDIUM | §4 | 4 phases for a single-file generator is over-engineered; 2 phases (1: generator + Lua rewire, 2: docs + hook) would suffice. Phase 1's "skeleton that prints JSON" exists only to verify Q5, which D6 argues is a non-issue for the current scope (hooks are omitted from the reference table, so multi-line string round-tripping never affects output). |
| D3 | MEDIUM | §4 Phase 4, §6, `09-dev-workflow.md` §5–§6 | For a solo-maintainer repo, the pre-commit hook's onboarding cost is disproportionate to its self-discipline value. Consider deferring Phase 4 to "when a 2nd contributor joins or a 2nd generator is added"; document `deno task gen` as a manual pre-commit step in `deps/README.md` until then. |
| D7 | MEDIUM | `09-dev-workflow.md` §6, I7, §6 hook | `deno task cache` as a separate onboarding step is a UX hazard: fresh clone → first commit → hook runs `deno run --no-remote` → "module not found in cache" error; the §6 hint is buried in stderr. Either auto-run `deno cache` on first hook invocation (detect empty cache, allow network once) or drop `--no-remote` and rely on deno's default HTTP cache. |
| A6 | LOW | §5.5, §4 Phase 2, `09-dev-workflow.md` G4 | Field-name contract (`minimum_deps` / `normal_deps`) across the Lua/TS boundary is implicit. If either side renames, `dpp_loader.lua` silently gets `nil` and `load_plugins(nil)` errors at startup. Add `assert(deps and deps.minimum_deps and deps.normal_deps, ...)` in `dpp_loader.lua` after the require, or pin field names in G4, or both. |
| C4 | MEDIUM | §5.4, §5.5, `dpp_loader.lua:29-36` | `denops.vim` injection position (last) is correct — `ensure_denops_plugin()` (`dpp_loader.lua:100`) needs denops.vim on rtp immediately after `load_plugins(normal_deps)`. The surrounding dpp.toml order differs from current (part of the A2/C2 byte-identity gap); fold this into the A2/C2 fix. |
| C5 | LOW | §3.3 I7, §5.1 | `--no-remote` + `deno task cache` only makes the **generator's** deno offline. denops.vim spawns its own deno (`dpp_loader.lua:82`) with separate deps (`@shougo/dpp-vim`, `@denops/std`, `@std/path`, `@shougo/dpp-ext-toml`, `@shougo/dpp-ext-lazy`) NOT pre-cached by `deno task cache`. Add one sentence to I7/§5.1 noting the scope limit so a reader doesn't conclude `--no-remote` makes Neovim startup offline. |
| C8 | LOW | §5.9 | Exit code 6 is the right severity (not CRITICAL). Add one sentence noting exits 4 and 6 are generation-time guards whose purpose is to prevent classification failures from reaching runtime (and thus from becoming CRITICAL startup-breaking outcomes). |
| A7 | LOW | §3.2, §5.4, §5.5 | `MINIMUM_REPOS` "encoded once" claim is true in *code* but restated in prose at §1.1, §3.2, §5.4, §5.5. Scope the claim to "in code"; add a note that prose restatements are illustrative. |
| D5 | LOW | §5.4 | Q7 "classified twice" / "every repo classified" assertions are mostly unreachable given the complementary predicate structure. Residual value is narrow (duplicate `[[plugins]]` entries in dpp.toml, or `denops.vim` being added to dpp.toml). Coverable by a 3-line assertion instead of the 20-line block. |
| D6 | LOW | §7 Q3, §7 Q5 | Q3 (CI) and Q5 (`@std/toml` newline preservation) are both safe to defer. Q5 is a non-issue for the current scope: §5.7 omits `hook_add`/`hook_source`/`lua_source` from the reference table (only a `✓` marker), so multi-line string round-tripping never affects any generated output. Q5 only matters for a future "render hooks" feature that is out of scope. |

## Verified premises (no action needed)

- **C-2 strict sub-claim holds.** `dpp_loader.lua` consumes ONLY repo strings from `minimum_deps` / `normal_deps` (lines 23-36 are arrays of bare strings; `load_plugins` at lines 70-78 uses each element solely as a plugin-name string for `dest_path`/`is_plugin_ready`/`install_github_plugin`/`runtimepath:prepend`). The lists are NOT passed to `dpp.load_state` (line 97) or `dpp.make_state` (lines 107, 119) — those take `(dpp_cache_home, dpp_denops_script)`. `dpp#make_state`'s actual input is the `ConfigReturn` built by `denops/dpp.ts` from the TOML files, which the refactor does not touch. Therefore a generated module carrying only repo strings is exactly the right shape, and `dpp#make_state`'s input is byte-identical before and after. (A2/C2 above is about the `load_plugins` bootstrap behavior change, not `dpp#make_state` input.)
- **C-1 split is correct.** `minimum_deps = {dpp.vim, dpp-ext-lazy}` is exactly what `dpp_loader.lua` needs before `dpp.load_state` (line 97); `normal_deps = rest of dpp.toml + denops.vim` is what `load_plugins(normal_deps)` (line 99) clones + rtp-prepends so the dpp-ext-* / dpp-protocol-* / denops.vim are available before `dpp.make_state` (line 107) and `ensure_denops_plugin()` (line 100).
- **C-3 `rtp = ''` is orthogonal.** The classification predicate uses only `repo ∈ MINIMUM_REPOS`; `rtp` is never consulted. `rtp = ''` on `dpp.vim` / `dpp-ext-lazy` is a dpp-ext-toml directive (don't add to rtp when loading from TOML because they're already on rtp via the bootstrap loader).
- **C-6 no autocmd interference.** The `dpp-ext-toml` `CursorHold */rc/*.toml` hook is (a) guarded by `if !has('nvim')` (Vim-only) and (b) the glob is `rc/*.toml` not `deps/*.toml`. No `after/` or `ftplugin/` directory exists at the repo root. The sentinel block rewrite is a one-shot operation by the generator script, outside Neovim.
- **C-7 "classified twice" check is reachable.** If a future maintainer adds `vim-denops/denops.vim` to `deps/dpp.toml`, the `seen`-Map loop in §5.4 would correctly throw `repo classified twice`.
- **I4 / I5 mechanism (modulo A1).** A pure-data `require()`d module is synchronous and side-effect-free; `vim.loader` is enabled at `init.lua:5` before `require('dpp_loader')` at `init.lua:41`. No new autocmds / `User` events. Only the A1 dot-resolution defect breaks this.
- **I3 / I6 / I8 hold.** Marker headers present; §6 hook does not `git add`; missing sentinel yields exit code 3.
- **I7 holds given the documented precondition.** `--no-remote --no-npm` + pre-populated JSR cache (subject to the D7 UX hazard and the C5 scope limit).
- **09-dev-workflow.md placement is correct** (per `00-document-management.md` §3, normative specs belong at `specifications/NN-<topic>.md`; whether it is *premature* is D4's YAGNI angle, not a placement question).
- **Chosen alternative (Deno + `@std/toml`) is sound** — deno is already a host dep for denops, no new runtime introduced.
- **Live drift confirms the issue's premise.** `dpp-protocol-http` is in `deps/dpp.toml:35` but missing from `dpp_loader.lua:29-36` — drift is real and undetected today. Both the design and the D1 check-only alternative address it.

## Open questions back to author

1. **A1 fix preference:** `lua/dpp_min_deps/generated.lua` (dotted require, one-file directory) or `lua/dpp_min_deps_generated.lua` (`require("dpp_min_deps_generated")`, underscore, no new directory)? Reviewer-A leans toward the latter (fewer moving parts). Whichever is chosen, update S2/S5, §3.1, §5.1, §5.5, §6, `09-dev-workflow.md` §4 in lockstep.
2. **A2/C2/D1-cross fix strategy:** split the drift fix into a pre-refactor commit (hand-edit `dpp_loader.lua` to add `dpp-protocol-http` + reorder to TOML order, smoke-test, then the refactor is mechanical and S7 holds literally), or keep as one commit and revise S7 + Phase 2 Acceptance to acknowledge the drift fix (with Reviewer-C sign-off that eagerly loading `dpp-protocol-http` at bootstrap is safe)?
3. **A3/D8 fix:** drop the `Last updated:` line entirely (preferred), or make it conditional on content change? If dropped, remove G3 from `09-dev-workflow.md` and update §5.7 + Q6 resolution.
4. **D1 scope decision:** is the issue scope "fix drift" (→ adopt the ~20-line check-only alternative) or "fix drift + generate human-readable docs + establish generator framework" (→ widen the issue body and re-justify the cost)?
5. **D4 spec decision:** keep `09-dev-workflow.md` normative but slim to ~5 genuinely cross-cutting rules, or demote to `docs/references/dev-workflow.md` (non-normative) until a second generator is added?
6. **A6 field-name contract:** pin in `09-dev-workflow.md` G4, enforce via `assert` in `dpp_loader.lua`, or both?
7. **D2/D3 phasing:** 4 phases or 2? Defer Phase 4 (pre-commit hook) until a 2nd contributor/generator, or keep?
8. **D7 cache UX:** auto-run `deno cache` on first hook invocation (detect empty cache, allow network once) or drop `--no-remote` and rely on deno's default HTTP cache?

## Recommended revision path

1. **Author decides D1** (scope: check-only vs. full generator). This is the highest-leverage decision — if check-only, most of the design and all of `09-dev-workflow.md` is moot.
2. **If proceeding with the full generator:** author decides A1 (path), A2/C2 (split or acknowledge), A3/D8 (drop date line), D4 (slim or demote spec). These four are the blocking set.
3. Apply non-blocking findings (A4/A5/A6/A7/C4/C5/C8/D2/D3/D5/D6/D7) in the same revision pass.
4. Update design `Status: DRAFT → in-review → <revised> → request pass 2` (or `Approved` if all blocking findings are RESOLVED/addressed and no new CRITICAL/HIGH findings emerge).
5. Update the issue body if D1 decision is "widen scope" (add "generate human-readable plugin docs" and "establish generator framework" to Acceptance criteria).
6. After revision, request pass 2 with the same letters (A + C + D) focused on whether the blocking findings are RESOLVED without regression.

## Status

- Per-letter reviews: `in-review` (A, C, D).
- Design: should move `DRAFT → in-review` upon receipt of this aggregate.
- Issue: stays `open` until the design is `Approved`, plan is `executed`, and a result-log records S1–S7 (revised) met.
