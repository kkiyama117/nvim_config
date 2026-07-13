# Review: deps-docs-auto-gen — Reviewer-D Devil's advocate

Reviewed: docs/specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md
Reviewer: composer-2.5-fast (Reviewer-D)
Date: 2026-07-13
Status: in-review

## Verdict

Approve with revisions. The design is internally coherent and the chosen alternative (Deno + generated Lua module, §2 A4/A6) is defensible, but three issues should be resolved before promotion to Approved.

1. **D-8 (correctness, trivial fix):** the in-body `Last updated: YYYY-MM-DD` line (§5.7, justified by G3) violates H5 ("no-op on unchanged inputs") — running the script on consecutive days with identical `deps/*.toml` produces a non-empty diff on `docs/references/deps-list.md` and spurious pre-commit hook failures on unrelated commits. The spec is internally inconsistent (G3 and H5 cannot both hold). Fix is one line: drop the date line.
2. **D-1 (shrink scope, signature finding):** the issue's stated problem ("two copies of truth drift silently") is solvable with a ~20-line drift-check script and zero generated artifacts. The design's extra cost (generated Lua module, sentinel-rewritten README, reference doc, pre-commit hook, 19-rule normative spec, 4-phase split) is justified only by "human-readable docs" and "generator framework" goals that are **not** in the issue's acceptance criteria. The author should either adopt the shrink-scope alternative, or explicitly widen the issue's scope and re-justify the cost.
3. **D-4 (premature generalization):** `09-dev-workflow.md` codifies 19 rules (R1–R10, G1–G4, H1–H5) for a repo with exactly one generator. Per-rule audit below: ~10 earn their keep now (but 8 of those are design invariants that could live in the design doc), ~7 are speculative, and 2 (G3, H5) are in direct tension. Recommend demoting to `docs/references/` or slimming to ~5 genuinely cross-cutting rules.

D-2, D-3, D-5, D-6, D-7 are revision suggestions, not blockers. One cross-cutting concern (cross: C): the current `dpp_loader.lua` `normal_deps` (lines 29–36) is already drifted — `Shougo/dpp-protocol-http` is in `deps/dpp.toml` (line 35) but missing from `normal_deps`. The design's §5.5 sample output silently adds it back, which is a runtime behavior change (`load_plugins(normal_deps)` at `initialize_dpp()` line 99 would clone one more plugin) that S7 ("byte-identical") claims does not happen. This is evidence the drift is real (strengthens the case for *some* solution) but also an S7 inconsistency the author must reconcile.

## Findings

| ID | Severity | Status | Location | Note |
|----|----------|--------|----------|------|
| D1 | HIGH | open | §2, §1.2, §4, §1.3 | The issue's problem statement ("two copies of truth drift silently") is solvable with a ~20-line drift-check script (sketch in §D1 below) and zero generated artifacts; the generator's extra cost is justified only by "human-readable docs" and "generator framework" goals, neither in the issue's acceptance criteria. Author should either adopt the shrink-scope alternative or explicitly widen the issue scope and re-justify the cost. |
| D2 | MEDIUM | open | §4 | 4 phases for a single-file generator is over-engineered; 2 phases (1: generator + Lua rewire, 2: docs + hook) would be sufficient and easier to review. Phase 1's "skeleton that prints JSON" adds a commit whose only value is verifying Q5 — which is itself a non-issue for the current scope (see D6). |
| D3 | MEDIUM | open | §4 Phase 4, §6, 09-dev-workflow.md §5–§6 | For a single-maintainer repo with no other contributors, the pre-commit hook's onboarding cost (`install-hooks.sh`, `deno task cache`, symlink management, 19-rule spec) is disproportionate to its self-discipline value. Recommend deferring Phase 4 to "when a second contributor joins or a second generator is added"; document `deno task gen` as a manual pre-commit step in `deps/README.md` until then. |
| D4 | HIGH | open | 09-dev-workflow.md §3.1–§3.3 | 19 normative rules for one generator is premature generalization. Per-rule audit in §D4 below: ~10 earn their keep now (but 8 are design invariants that could live in the design doc), ~7 are speculative, 2 (G3, H5) are in direct tension. Recommend demoting to `docs/references/dev-workflow.md` (non-normative) or slimming to ~5 genuinely cross-cutting rules. |
| D5 | LOW | open | §5.4 | The Q7 "classified twice" and "every repo classified" assertions are mostly unreachable: the classification predicate (`filter(MINIMUM_REPOS.has)` / `filter(!MINIMUM_REPOS.has)`) are exact complements on the same array, so every `dppEntries` item lands in exactly one bucket by construction. Residual value is only detecting duplicate `[[plugins]]` entries in dpp.toml or `denops.vim` being added to dpp.toml — both narrow scenarios coverable by a 3-line assertion instead of the 20-line block. |
| D6 | LOW | open | §7 Q3, §7 Q5, §5.7 | Q3 (CI) and Q5 (`@std/toml` newline preservation) are both safe to defer. Q5 is a non-issue for the current scope: §5.7 explicitly omits `hook_add`/`hook_source`/`lua_source` from the reference table (only a `✓` marker), so multi-line string round-tripping never affects any generated output. Q5 only matters for a future "render hooks" feature that is out of scope. |
| D7 | MEDIUM | open | 09-dev-workflow.md §6, I7, §6 hook | `deno task cache` as a separate onboarding step is a UX hazard: fresh clone → first `git commit` → hook runs `deno run --no-remote` → "module not found in cache" error; the §6 hint "Fresh clone? Run `deno task cache`" is buried in stderr. Either auto-run `deno cache` on first hook invocation (detect empty cache, allow network once) or drop `--no-remote` and rely on deno's default aggressive HTTP cache — eliminates the separate onboarding step entirely. |
| D8 | MEDIUM | open | §5.7, G3, H5 | The in-body `<!-- Last updated: YYYY-MM-DD -->` line (§5.7, justified by G3) violates H5 ("a generator whose source files are unchanged must produce zero diff"): running the script on day N+1 with `deps/*.toml` unchanged still rewrites the date line from N to N+1, producing a non-empty diff on `docs/references/deps-list.md` and spurious pre-commit hook failures on unrelated commits. The spec is internally inconsistent (G3 and H5 cannot both hold). Fix: drop the date line entirely — `git log docs/references/deps-list.md` already records the last-changed date, and `00-document-management.md` §6.7 (which G3 cites) governs filename prefixes, not in-body dates. |

### D1 — sketch of the "do not adopt" alternative

`scripts/check_deps.ts` (~20 lines, Deno + `@std/toml`), no generation, no hook, no spec:

```ts
// Drift checker — no generation. Exits 0 if dpp_loader.lua matches deps/*.toml.
import { parse } from "@std/toml";

const dpp = (parse(await Deno.readTextFile("deps/dpp.toml")).plugins ?? []) as { repo: string }[];
const denops = (parse(await Deno.readTextFile("deps/denops.toml")).plugins ?? []) as { repo: string }[];
const lua = await Deno.readTextFile("lua/dpp_loader.lua");

const MIN = ["Shougo/dpp.vim", "Shougo/dpp-ext-lazy"];
const expectedNormal = [
  ...dpp.map(p => p.repo).filter(r => !MIN.includes(r)),
  ...denops.map(p => p.repo).filter(r => r === "vim-denops/denops.vim"),
].sort();

const grab = (name: string) => {
  const m = lua.match(new RegExp(`local ${name} = \\{([^}]*)\\}`, "s"));
  return m ? [...m[1].matchAll(/"([^"]+)"/g)].map(x => x[1]).sort() : null;
};
const actualMin = grab("minimum_deps");
const actualNorm = grab("normal_deps");

const eq = (a: string[] | null, b: string[]) => a && a.join(",") === b.join(",");
const errors: string[] = [];
if (!eq(actualMin, MIN)) errors.push(`minimum_deps drift: got ${actualMin}, want ${MIN}`);
if (!eq(actualNorm, expectedNormal)) errors.push(`normal_deps drift: got ${actualNorm}, want ${expectedNormal}`);
if (errors.length) { console.error(errors.join("\n")); Deno.exit(1); }
console.log("deps in sync");
```

Cost/benefit vs. the design:

| Aspect | Generator (design) | Check-only (D1) |
|--------|--------------------|-----------------|
| Catches drift (issue's core problem) | yes (auto-fixes) | yes (manual fix after detection) |
| Single source of truth | yes | no (Lua stays hand-maintained, verified) |
| Human-readable plugin docs (S1/S4) | yes | no |
| Generated Lua module (S2/S3) | yes | no |
| Pre-commit hook (S5) | yes | optional (check-only hook, ~5 lines) |
| `09-dev-workflow.md` (19 rules) | yes | no |
| 4-phase split | yes | no (single commit) |
| New onboarding (`install-hooks.sh`, `deno task cache`) | yes | no |
| Catches the live `dpp-protocol-http` drift today | yes (auto-adds) | yes (detects, manual fix) |

The current `lua/dpp_loader.lua` `normal_deps` (lines 29–36) is already drifted: `Shougo/dpp-protocol-http` is in `deps/dpp.toml` (line 35) but missing from `normal_deps`. Both approaches catch this; the design's §5.5 sample output shows the corrected list (with `dpp-protocol-http`), which is a runtime behavior change (one more plugin cloned at `load_plugins(normal_deps)` in `initialize_dpp()` line 99) that the design does not explicitly call out against S7's "byte-identical" claim. Cross-cutting with Reviewer-C (C should confirm whether this is a correct drift-fix or an S7 violation).

What is lost by adopting D1: human-readable plugin docs, single-source-of-truth (the Lua tables stay hand-maintained, just verified), and the generator foundation for future work. What is saved: the generated Lua module, sentinel rewriting in `deps/README.md`, `docs/references/deps-list.md`, the pre-commit hook installer, `09-dev-workflow.md` (19 rules), and the 4-phase split. The author's decision hinges on whether "generate human-readable docs" and "establish a generator framework" are in-scope goals — they are not in the issue body today.

### D4 — per-rule audit of 09-dev-workflow.md

| Rule | Earns its keep now? | Note |
|------|---------------------|------|
| R1 (generators under `scripts/`) | yes (trivially) | could be a one-line convention in `scripts/README.md` |
| R2 (Deno/TS only) | **speculative** | one generator; locks out future Python/Lua generators without a design |
| R3 (`deno task <name>` entrypoint) | yes | — |
| R4 (JSR via `deno.json` imports) | **speculative** | one generator, one dep (`@std/toml`) — could be inline |
| R5 (`--no-remote` + `deno task cache`) | yes (but UX hazard, see D7) | — |
| R6 (idempotent) | yes | could be a design invariant (I2), not a normative rule |
| R7 (never read prior output) | yes | could be a design invariant (I1) |
| R8 (marker header) | yes | could be a design invariant (I3) |
| R9 (documented exit codes) | yes | could be a design invariant (§5.9) |
| R10 (sentinel or whole-file, no regex-edit) | yes | could be a design invariant |
| G1 (git-tracked) | yes | could be a design success criterion (S2) |
| G2 (no hand-edits) | yes | could be a design invariant |
| G3 (in-body `Last updated` line) | **speculative AND harmful** | violates H5, see D8 |
| G4 (pure-data Lua module) | yes | could be a design invariant (I4) |
| H1 (symlinked pre-commit hook) | yes (but YAGNI for solo repo, see D3) | — |
| H2 (hook runs every gen task + diff) | **speculative** | "every generator in the registry" — there is one |
| H3 (no auto-stage) | yes | — |
| H4 (no network in hook) | yes (consequence of R5) | — |
| H5 (no-op on unchanged inputs) | yes (and violated by G3, see D8) | the one rule that genuinely cross-cuts — but the design breaks it |

Tally: 10 "earns its keep now" (but 8 are design invariants that could live in the design doc), 7 "speculative," 2 "in direct tension." At most 5 rules (the R6/R7/R8/R9 cluster + H5) genuinely cross-cut multiple generators and deserve normative status. The rest should be deferred until a second generator is added, or moved into the design's invariants section.

## Verified premises (no action needed)

- The chosen alternative (Deno + `@std/toml`, §2 A4/A6) is sound: deno is already a host dep for denops, no new runtime introduced.
- I5 (startup order unchanged) holds: a pure-data `require()`d module is synchronous and side-effect-free; `vim.loader` is already enabled in `init.lua`.
- I7 (no network at run time) is achievable with `--no-remote` + pre-populated JSR cache (subject to the D7 UX hazard).
- The 4-phase split's "independently revertable" claim (§4) holds for all four phases.
- The live drift (`dpp-protocol-http` missing from `normal_deps`) confirms the issue's premise that drift is real and undetected today — both the design and the D1 alternative address it.

## Open questions back to author

- D1: is the issue's scope "fix drift" (→ check-only suffices, adopt D1) or "fix drift + generate human-readable docs + establish generator framework" (→ design justified, but widen the issue body and re-justify the cost)?
- D8: confirm whether the `Last updated` line should be dropped (preferred — one-line fix) or made conditional on content change (more code). If dropped, G3 must be removed from `09-dev-workflow.md` and §5.7 / Q6 resolution updated.
- D4: is `09-dev-workflow.md` intended as a normative spec (→ keep at `specifications/`, slim to ~5 rules) or a reference for the current single generator (→ demote to `references/`)?
- D1 (cross: C): the design's §5.5 sample output adds `Shougo/dpp-protocol-http` to `normal_deps` (currently missing from `dpp_loader.lua` lines 29–36). Is this an intentional drift-fix (→ document it as a behavior change against S7 in §1.2 or §3.3) or an oversight in the sample? Either way, S7's "byte-identical" claim needs a footnote.
