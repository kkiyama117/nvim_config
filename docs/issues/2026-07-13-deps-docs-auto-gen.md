# Dependency docs auto-generation drift

**Date:** 2026-07-13
**Status:** open
**Related:** [design](../specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md), [plan](../plans/2026-07-13-deps-docs-auto-gen-impl.md), [pass-1 review](../reviews/2026-07-13-deps-docs-auto-gen-review-pass1.md), [pass-2 review](../reviews/2026-07-13-deps-docs-auto-gen-review-pass2.md)

## Context

`deps/README.md` declares three open TODOs:

1. "Update `docs` folder to write down this rule"
2. "Write scripts to generate plugin list; under `scripts` folder"
3. "Inject `minimum dpp plugin list` in `lua/dpp_loader.lua`"

`deps/README.md` already reserves sentinel blocks (`AUTO GENERATED PLUGIN LIST … END`) for the generated content, but nothing fills them today.

`lua/dpp_loader.lua` keeps two hand-maintained Lua tables (`minimum_deps`, `normal_deps`) that must mirror entries in `deps/dpp.toml`. They drift silently:

- No verification that every `Shougo/dpp-*` entry in `dpp.toml` appears in the Lua tables.
- No human-readable documentation of the plugin set across `deps/{dpp,denops,neovim,merge}.toml`.

## Problem

The plugin list has two copies of truth (TOML files + `dpp_loader.lua` tables) and no generated docs. Edits to one are not propagated to the other, and contributors cannot see the active plugin set without reading TOML + Lua side by side.

We need a single source of truth (`deps/*.toml`) and generated artifacts (Lua module + markdown docs) that are kept fresh by automation.

**Scope (widened per pass-1 Reviewer-D finding D1, 2026-07-13):** beyond drift detection, this issue explicitly covers three goals:

1. **Fix drift** — eliminate the two-copies-of-truth problem by making `deps/*.toml` the single source and generating the Lua tables.
2. **Generate human-readable plugin docs** — `docs/references/deps-list.md` so contributors can see the active plugin set (per-TOML, with `on_ft`/`on_event`/`if`/`depends` columns) without reading TOML + Lua side by side. (Design S1/S4.)
3. **Establish a generator framework** — `scripts/` directory, `docs/specifications/09-dev-workflow.md` normative spec, and a pre-commit hook pattern reusable by future code-generation tasks (formatter stamping, luarc generation, etc.). (Design S5 + `09-dev-workflow.md`.)

The narrower "check-only" alternative (a ~20-line drift-check script with no generation, sketched in [pass-1 Reviewer-D](../reviews/2026-07-13-deps-docs-auto-gen-review-pass1-D-devils-advocate.md#d1--sketch-of-the-do-not-adopt-alternative)) was considered and rejected: it would solve goal 1 only. The full generator is adopted because all three goals are in scope.

## Acceptance criteria

Carried forward as success criteria S1–S7 in the [design](../specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md) §1.2. The issue closes when the design is `Approved`, the plan is `executed`, and the result-log in `docs/issues/` records that S1–S7 are met.

In summary:

- A script under `scripts/` regenerates the sentinel block in `deps/README.md`, the `lua/dpp_min_deps.lua` module, and `docs/references/deps-list.md` from `deps/*.toml`.
- `lua/dpp_loader.lua` `require()`s the generated module instead of declaring the tables inline; startup order unchanged.
- `docs/references/deps-list.md` provides a human-readable per-plugin table across all four TOMLs (goal 2).
- `docs/specifications/09-dev-workflow.md` codifies the generator framework rules (R/G/H) for future generators (goal 3).
- A pre-commit hook refuses commits with stale generated files.
- No plugin-runtime behavior change (verified by smoke test).

## Notes

- Trigger is a README TODO, not a bug — but raised retroactively as an issue per [00-document-management.md](../specifications/00-document-management.md) §4 lifecycle so the `issue → design → review → plan → result-log → issue (closed)` trail is traceable via the shared `deps-docs-auto-gen` slug.
- Decisions resolved upfront (see design §7 Q1/Q2/Q6/Q7): Deno + JSR `@std/toml` via `scripts/deno.json` import map; no date prefix in `docs/references/deps-list.md` filename; explicit "every `dpp.toml` repo is classified into exactly one bucket" assertion in the script.
- Pass-1 review (2026-07-13) raised 5 blocking + 12 non-blocking findings; all 17 applied in one revision pass. Blocking: A1 (Lua require path → `lua/dpp_min_deps.lua`), D1 (full generator, scope widened above), A2/C2 (Phase 0 pre-refactor drift fix added), A3/D8 (in-body date line dropped), D4 (`09-dev-workflow.md` slimmed to 5 cross-cutting rules).
- Pass-2 review (2026-07-13) with same letters (A + C + D): all 5 pass-1 blocking findings verified RESOLVED, no new CRITICAL/HIGH. 1 MEDIUM (D-pass2-2: deferred-rules mapping inaccuracy in `09-dev-workflow.md`) + 4 polish items, all applied. R1 re-elevated to spec as 6th cross-cutting rule; H4 removed (negated by D7). **Design promoted to `Approved`** — see [design §8a + pass-2 findings table](../specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md). Plan phase may begin.
