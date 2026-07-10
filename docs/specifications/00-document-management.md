# 00 — Document management spec

Defines the placement, naming, lifecycle, and format of documents in this repository (`/data/nvim_config`). Referenced from [`AGENTS.md`](../../AGENTS.md) §3.

All AI agents and human maintainers follow this spec. `docs/README.md` is an index only; the rules live in this file.

This spec is adapted from `~/.pi/docs/specifications/00-document-management.md` to the nvim_config context: hard constraints are aligned with [AGENTS.md](../../AGENTS.md) §2 (A1–A6), and review letter C is **Plugin loading semantics** (dpp.vim / denops / `after` / `ftplugin` fire order).

## 1. Purpose

- Unify the **placement and shape** of documents that discuss config changes, plugin evaluation, and migration.
- Remove the guesswork of "**where / what name / what format**" when creating a new document.
- Let past documents be read and written in the same shape.

## 2. Directory layout

```
docs/
├── README.md                       # Index only
├── .gitignore                      # Shield docs that contain secrets
├── issues/                         # Issues (GitHub Issues substitute) + result-log
├── plans/                          # Implementation plans (-impl)
├── references/                     # External / host-state reference material
├── reviews/                        # Reviews (pass-N / per-letter / aggregate / prompt)
└── specifications/
    ├── 00-document-management.md   # ← This file
    └── implementation/             # Per-implementation design draft
        └── YYYY-MM-DD-<slug>-design.md
```

## 3. Document types and naming

Every document is one of the 7 types below. Adding a new type requires revising this spec.

| Type | Path | Naming | Role |
|------|------|--------|------|
| `issue` | `docs/issues/` | `YYYY-MM-DD-<slug>.md` | Issue raising |
| `result-log` | `docs/issues/` | `YYYY-MM-DD-<phase>-<topic>.md` | Phase-completion evidence (no-PR environment) |
| `design` | `docs/specifications/implementation/` | `YYYY-MM-DD-<slug>-design.md` | Implementation policy design (DRAFT → Approved) |
| `plan` | `docs/plans/` | `YYYY-MM-DD-<slug>-impl.md` | Mechanical checklist after Approved design |
| `review` | `docs/reviews/` | `YYYY-MM-DD-<slug>-review[-passN][-<letter>-<topic>][-prompt].md` | Review body / aggregate / prompt |
| `reference` | `docs/references/` | Any (`<topic>.md` or `YYYY-MM-DD-<topic>.md`) | External / host-state reference |
| `spec` | `docs/specifications/` | `NN-<topic>.md` (normative) or `<topic>.md` (feature) | Project-wide normative spec |

### 3.1 slug

- Lowercase ASCII, `-` separated, ASCII only.
- Inherit the slug of the related issue. The same slug lets `issue → design → plan → review → result-log` be traced via grep.
- Examples:
  - `docs/issues/2026-07-10-dpp-toml-restructure.md`
  - `docs/specifications/implementation/2026-07-10-dpp-toml-restructure-design.md`
  - `docs/reviews/2026-07-10-dpp-toml-restructure-review-pass1-C-plugin-loading.md`
  - `docs/plans/2026-07-10-dpp-toml-restructure-impl.md`
  - `docs/issues/2026-07-11-phase1-smoke-matrix.md` (result-log)

### 3.2 Date

- The leading `YYYY-MM-DD` is the day the document was created.
- It stays fixed across revisions (for searchability).
- Relative dates ("tomorrow", "next week") are forbidden in body text. Always use absolute dates.

## 4. Lifecycle

```
issue (open)
   │
   ▼
design (DRAFT)
   │
   ▼ review request
review prompt → review pass-N (letter A–E)
   │
   ▼  aggregate → design revise
design (DRAFT / in-review …)
   │
   ▼ all findings RESOLVED / addressed
design (Approved)
   │
   ▼
plan (pending → executing)
   │
   ▼ execution complete
result-log (docs/issues/)
   │
   ▼
issue (closed)
```

- A design is promoted `DRAFT → in-review → Approved` as it passes review passes.
- A design touching **startup order, plugin loading, denops, or skkeleton** requires at least letters A + D (see [AGENTS.md](../../AGENTS.md) §4). Designs touching startup order or plugin loading require at least **A + C + D**.
- When a plan finishes, leave **evidence that acceptance was met** as a result-log in `docs/issues/` (there is no PR description in this environment).

## 5. Status vocabulary

### Document status (design / plan / issue)

`DRAFT` / `awaiting reviewers` / `in-review` / `Approved` / `pending` / `executing` / `executed` / `closed` / `superseded`

### Review finding status (same as [AGENTS.md](../../AGENTS.md) §4)

`open` / `RESOLVED` / `REGRESSION` / `INCOMPLETE` / `addressed` / `blocked`

## 6. Minimum requirements per document type

### 6.1 issue

```markdown
# <Title>

**Date:** YYYY-MM-DD
**Status:** open | in-progress | closed
**Related:** [design](...), [plan](...), [reviews](...)

## Context
<Observed facts>

## Problem
<The question to solve>

## Acceptance criteria
<What must be satisfied to close>

## Notes
<Reference notes>
```

### 6.2 design (`specifications/implementation/*-design.md`)

```markdown
# <Title> — Design

**Status:** DRAFT | in-review | Approved | superseded
**Date opened:** YYYY-MM-DD
**Issue:** [...]
**Author:** kkiyama

## §1 Context & success criteria (S1, S2, …)
## §2 Alternatives considered
## §3 Architecture / Invariants (I1, I2, …)
## §4 Scope / staging breakdown
## §5–§N Implementation detail
## §N+1 Open questions (Q1, Q2, …)
```

- Always label success criteria with `S<n>`, invariants with `I<n>`, and open questions with `Q<n>` (so reviewers can reference them).
- A `superseded` design must state the successor design's path at the top.

### 6.3 review prompt (`reviews/*-review-prompt[-passN].md`)

Minimum structure:

- Relative path of the subject
- Common output format (may reference [AGENTS.md](../../AGENTS.md) §4)
- For each Reviewer-X: **role / what to read / evaluation points / expected output format**

### 6.4 review (`reviews/*-review[-passN][-<letter>-<topic>].md`)

Follow the schema in [AGENTS.md](../../AGENTS.md) §4: header + Verdict + Findings table + Verified premises + Open questions.

An aggregate review (`*-review-passN.md`, no letter suffix) integrates per-letter reviews into the final view the design author uses for the next revision.

### 6.5 plan (`plans/*-impl.md`)

```markdown
# <Title> — Implementation Plan

**Status:** pending | executing | executed
**Spec:** [...]
**Parent issue:** [...]
**Review trail:** [...]

## Phases

### Phase N — <Name>
1. step
2. step

**Acceptance**: <Verification procedure>
**Rollback**: <Rollback procedure>
```

- Each Phase is **one commit** in principle.
- When a Phase's Acceptance is met, write a result-log in `docs/issues/`.

### 6.6 result-log (`issues/<phase>-<topic>.md`)

Attach the evidence that the corresponding plan's Acceptance was met, as a table or log.

### 6.7 reference

Free format. However:

- For external resource citations: **URL and retrieval date**.
- For host-state snapshots: **retrieval method and retrieval date**.
- If the content changes over time, prefix the filename with `YYYY-MM-DD-`.

## 7. Link conventions

- Always use **repository-relative paths** as `[label](relative/path.md)`.
- Absolute paths, `~/`, and `file://` are forbidden.
- When a deleted doc was referenced, update the referencing side in the same delete commit.
- Deep links to section numbers include an anchor: `[§3.2](...#32-...)`.

## 8. What does NOT go in docs

- Non-persistent work memos → session scratchpad.
- Reusable lessons → memory.
- Secrets / tokens / contents of `rc/secrets.vim` → forbidden even inside a spec.
- Host personal paths (`/home/kiyama/...`) → use `~/` notation or environment variables.

## 9. Existing documents — gradual convergence

As of this spec's creation (2026-07-10), the repository is in a "Full scratch" state and `docs/` is empty. Therefore:

1. `docs/README.md` is an index only. The rule body lives in this file.
2. New docs comply with this spec **100%**.
3. There are no existing docs to converge. If a future migration imports material from host `~/.config/nvim`, place it under `docs/references/` with a retrieval-date prefix and do not rewrite it destructively.
4. If duplicate / stale docs are found later, downgrade them to `superseded` and add a link to the successor at the top.

## 10. Revision procedure

This spec itself is one spec. When revising:

1. Raise the revision reason as an issue in `docs/issues/`.
2. If necessary, go through a design (`docs/specifications/implementation/<slug>-doc-mgmt-rev-design.md`).
3. Edit this file directly, and include the issue path in the commit log.
4. Sync affected templates (`AGENTS.md` etc.) in the same commit.