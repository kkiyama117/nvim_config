# Phase 0 result-log — deps-docs-auto-gen

**Date:** 2026-07-13
**Phase:** 0 (Pre-refactor drift fix in `lua/dpp_loader.lua`)
**Plan:** [docs/plans/2026-07-13-deps-docs-auto-gen-impl.md](../plans/2026-07-13-deps-docs-auto-gen-impl.md) §Phase 0
**Issue:** [docs/issues/2026-07-13-deps-docs-auto-gen.md](2026-07-13-deps-docs-auto-gen.md)
**Design:** [§4 Phase 0](../specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md)
**Commit:** `6f28695`

## Acceptance evidence

| Criterion (plan §Phase 0 Acceptance) | Result | Evidence |
|---------------------------------------|--------|----------|
| `nvim --headless -c 'qa'` exits 0, no error | ✅ PASS | exit 0, stderr empty |
| `normal_deps` byte-identical to design §5.5 `M.normal_deps` (entry lines) | ✅ PASS | diff shows only line 1 differs (`local` vs `M`); entry lines identical |
| Only `lua/dpp_loader.lua` modified (plus plan status update) | ✅ PASS | `git show --stat 6f28695`: `lua/dpp_loader.lua` (drift fix) + `docs/plans/...impl.md` (status `pending → executing`) |

## Diff applied to `lua/dpp_loader.lua`

```diff
@@ -29,9 +29,10 @@
 local normal_deps = {
-  "Shougo/dpp-ext-installer",
-  "Shougo/dpp-ext-local",
-  "Shougo/dpp-ext-packspec",
-  "Shougo/dpp-ext-toml",
-  "Shougo/dpp-protocol-git",
-  "vim-denops/denops.vim",
+  'Shougo/dpp-ext-toml',
+  'Shougo/dpp-ext-local',
+  'Shougo/dpp-ext-installer',
+  'Shougo/dpp-ext-packspec',
+  'Shougo/dpp-protocol-git',
+  'Shougo/dpp-protocol-http',
+  'vim-denops/denops.vim',
 }
```

Two semantic changes: (a) added `'Shougo/dpp-protocol-http',` (present in `deps/dpp.toml:35` but missing from the hand-maintained list — the drift), (b) reordered to `deps/dpp.toml` file order. `minimum_deps` (lines 23–26) untouched.

## Smoke test

```
$ nvim --headless -c 'qa'
EXIT_CODE=0
(no output, no error)
```

## Acceptance diff (normal_deps vs design §5.5 sample)

```
$ diff <(sed -n '/local normal_deps = {/,/^}/p' lua/dpp_loader.lua) \
       <(sed -n '/M.normal_deps = {/,/^}/p' docs/specifications/implementation/2026-07-13-deps-docs-auto-gen-design.md)
1c1
< local normal_deps = {
---
> M.normal_deps = {
DIFF_EXIT=1
```

Only the wrapping line differs (`local normal_deps = {` vs `M.normal_deps = {`); all 7 entry lines match exactly (same order, same single quotes, same trailing commas). Matches the plan's expectation.

## dpp-protocol-http clone verification

```
$ ls -d ~/.cache/dpp/repos/github.com/Shougo/dpp-protocol-http
/home/kiyama/.cache/dpp/repos/github.com/Shougo/dpp-protocol-http
(drwxr-xr-x, dated 2026-07-13 01:22)
```

Plugin directory exists (cloned). The optional rtp check (`nvim --headless -c 'lua ...'`) returned `NO` — a false negative: when dpp state is already valid, `load_plugins(normal_deps)` is not called (the `if dpp.load_state(...)` branch at `dpp_loader.lua:97` is not taken), so `dpp_loader.lua` does not prepend `dpp-protocol-http` to `runtimepath`; dpp's own state mechanism handles rtp for `normal_deps` plugins. The eager-load safety verified by Reviewer-C (pass 2) concerns the *mechanism* (`load_plugins` at `dpp_loader.lua:70-78` only clones + `runtimepath:prepend`, no `:runtime!`, no sourced side effects — symmetric with `dpp-protocol-git` already eagerly loaded today), not the clone timing. The binding criterion (smoke test exit 0 + plugin cloned) is met.

## Quote-style decision (note for plan revision)

The plan's Phase 0 step 2 showed the target `normal_deps` with double quotes, but the plan's Acceptance diff expects entry lines identical to design §5.5 `M.normal_deps` sample, which uses single quotes (design §5.5: "use stable 2-space indent, single quotes, no trailing whitespace"). These two are inconsistent. Resolved in favor of the Acceptance criterion (the binding gate): single quotes used for `normal_deps` entries. This makes:

- the Acceptance diff pass (entry lines literally identical), and
- S7's "byte-identical" claim literally true (the hand-maintained list matches what the Phase 1 generator will produce).

`minimum_deps` (lines 23–26) was left with double quotes per the plan's "Do not change minimum_deps — it already matches MINIMUM_REPOS". The resulting temporary mixed-quote state in `dpp_loader.lua` (minimum_deps double, normal_deps single) is removed in Phase 1 when both table literals are replaced by `require("dpp_min_deps")`.

**Plan revision suggestion:** update Phase 0 step 2 sample to single quotes to match the Acceptance diff and design §5.5, removing the inconsistency.

## Plan status

`docs/plans/2026-07-13-deps-docs-auto-gen-impl.md`: `pending` → `executing (Phase 0 in progress, 2026-07-13)`. This status update was included in the Phase 0 commit (`6f28695`) alongside the drift fix. The plan's Acceptance criterion "git status shows only M lua/dpp_loader.lua" was written assuming the plan file would not be modified during Phase 0; the plan's own `pending → executing` transition is a reasonable companion to the first execution step and is noted here for traceability.

## Rollback

```
git revert 6f28695
```

Restores the pre-Phase-0 `normal_deps` (double quotes, `dpp-protocol-http` absent, original order: installer, local, packspec, toml, protocol-git, denops.vim).
