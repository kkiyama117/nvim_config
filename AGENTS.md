# AGENTS — nvim_config

New config and documents of `neovim`.

## 0. Top-Level Rules

- Use `pi-subagents` and run independent processes in parallel.
- Do all in English, but use Japanese to respond to User.
- Dont Praise and filler. prefaces like "Great question" are not needed. Simple output; like table.

## 1. Project overview

| Item | Value |
|------|-------|
| Repository | `https://github.com/kkiyama117/nvim_config.git` |
| Purpose | Manage and update the Neovim config migrated from host `~/.config/nvim` |
| Platform | Neovim (Lua first-class) |

### Main plugins

| Item | description |
|------|-------|
| Plugin manager | [dpp.vim](https://github.com/Shougo/dpp.vim) (Shougo family, denops.vim based) |
| External runtime | [deno](https://deno.land/) (for denops, via mise), [coc.nvim](https://github.com/neoclide/coc.nvim) |
| Japanese input | [skkeleton](https://github.com/vim-skk/skkeleton) |
| Environment | Linux, `LANG=ja_JP.UTF-8` |

### Planned directory layout (per README.md)

```
init.lua                  # Entry point
docs/                     # ← defined in §3 of this file
```

## 2. Hard constraints (do not violate without permission)

| ID | Rule | Rationale |
|----|------|-----------|
| ?? | TODO | TODO |

When a new hard constraint is discovered, append it to this table (consider SOP-ifying after 2 occurrences of the same failure, see §6).

## 3. Document management (docs/)

`issues` / `plans` / `specifications` / `references` (and `reviews`) are managed under `docs/`. The **canonical source** for placement, naming, and lifecycle is `docs/specifications/00-document-management.md` (the `.pi` repository's same-named spec adapted to the nvim_config context).

### 3.1 Directory layout

```
docs/
├── README.md                       # Index only
├── issues/                         # Issues + result-log (GitHub Issues substitute)
├── plans/                          # Implementation plans (-impl)
├── references/                     # External / host-state reference material
├── reviews/                        # Reviews (pass-N / per-letter / aggregate / prompt)
└── specifications/
    ├── 00-document-management.md   # ← canonical source referenced by this section
    └── implementation/             # Per-implementation design draft (YYYY-MM-DD-<slug>-design.md)
```

### 3.2 Document types (naming summary)

| Type | Path | Naming | Role |
|------|------|--------|------|
| `issue` | `docs/issues/` | `YYYY-MM-DD-<slug>.md` | Issue raising |
| `result-log` | `docs/issues/` | `YYYY-MM-DD-<phase>-<topic>.md` | Phase-completion evidence (no-PR environment) |
| `design` | `docs/specifications/implementation/` | `YYYY-MM-DD-<slug>-design.md` | Implementation policy (DRAFT → Approved) |
| `plan` | `docs/plans/` | `YYYY-MM-DD-<slug>-impl.md` | Mechanical checklist after Approved design |
| `review` | `docs/reviews/` | `YYYY-MM-DD-<slug>-review[-passN][-<letter>-<topic>][-prompt].md` | Review / aggregate / prompt |
| `reference` | `docs/references/` | `<topic>.md` | External / host-state reference |
| `spec` | `docs/specifications/` | `NN-<topic>.md` (normative) / `<topic>.md` (feature) | Project-wide normative spec |

- **slug**: lowercase ASCII, `-` separated. The same slug lets `issue → design → plan → review → result-log` be traced via grep.
- **Date**: the leading `YYYY-MM-DD` is the day the document was created. It stays fixed across revisions. Relative dates ("tomorrow", "next week") are forbidden in body text; always use absolute dates.

### 3.3 Lifecycle

```
issue (open) → design (DRAFT) → review pass-N (A–E) → design (Approved) → plan (executing) → result-log → issue (closed)
```

- A design is promoted `DRAFT → in-review → Approved` as it passes review passes.
- **Designs touching startup order, plugin loading, denops, or skkeleton require at least letters A + D** (see §4).
- When a plan finishes, leave **evidence that acceptance was met** as a result-log in `docs/issues/` (there is no PR description).

### 3.4 Status vocabulary

- Document: `DRAFT` / `awaiting reviewers` / `in-review` / `Approved` / `pending` / `executing` / `executed` / `closed` / `superseded`
- Review finding: `open` / `RESOLVED` / `REGRESSION` / `INCOMPLETE` / `addressed` / `blocked`

Details (minimum requirements per document type, templates, severity definitions) are delegated to `docs/specifications/00-document-management.md`.

## 4. Review perspectives — canonical letter set

When creating `docs/reviews/<slug>-review-prompt[-passN].md`, use the letters below. Extend with F, G, … only when a perspective is truly added, and state the reason in the prompt.

| Letter | Role |
|--------|------|
| A | **Architecture** — module boundaries / `lua/` responsibility split / invariants of startup order |
| B | **Backwards compat / Migration** — behavior lost when migrating from host `~/.config/nvim`, filetype-detection regression |
| C | **Plugin loading semantics** — dpp.vim toml/rtp/depends/lazy, denops startup, `after/` and `ftplugin/` fire order |
| D | **Devil's advocate** — alternatives / YAGNI / serious proposal of "do not adopt" options |
| E | **Factual verification** — citation existence, Neovim API behavior, factual check of dpp/denops specs |

**Designs touching startup order or plugin loading require at least A + C + D.**

### 4.1 Review output schema (common)

```markdown
# Review: <subject> — [Reviewer-X perspective name]

Reviewed: <relative path to design / target>
Reviewer: <name / model>
Date: YYYY-MM-DD
Status: in-review | addressed | blocked

## Verdict
<1–2 paragraphs. "approve as-is" / "approve with revisions" / "block on X">

## Findings

| ID | Severity | Status | Location | Note |
|----|----------|--------|----------|------|
| X1 | CRITICAL | open | §x.y | 1–3 sentences |

## Verified premises (no action needed)
- …

## Open questions back to author
- …
```

- **Severity**: `CRITICAL` (cannot start up / secret leak / does not work correctly) / `HIGH` (large redesign needed) / `MEDIUM` (loose ends) / `LOW` (improvement suggestion) / `INFO` (reference)
- **Aggregation**: per-perspective `docs/reviews/<slug>-review-passN-<letter>-<topic>.md`, aggregate `docs/reviews/<slug>-review-passN.md`. Cross-cutting findings may be tagged like `R-A4 (cross: C)`.

## 5. Model / agent usage

Use `pi-subagents` skill to choose agents

## 6. Behavior rules / when the AI is unsure

- **Code comments are forbidden by default.** One line only when the "why" is non-obvious.
- Review findings default to an `ID | Status | Note` table.

When unsure:

1. Grep `docs/issues/` (has it been discussed already?).
2. Check `docs/specifications` for a related design and specfications.
3. If still unclear, **a decision that may conflict with §2 hard constraints must not proceed without permission.** Stop and ask even in auto mode.
- **Revision trigger**: if the same kind of failure is recorded twice (in git log / `docs/issues/` / a session), consider SOP-ifying or revising an existing SOP's constraints. The first occurrence is fine as an issue note.

