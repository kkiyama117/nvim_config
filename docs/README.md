# docs/

Index for the nvim_config document set. Rules live in [00-document-management.md](specifications/00-document-management.md), not here.

## Canonical spec

- [specifications/00-document-management.md](specifications/00-document-management.md) — placement, naming, lifecycle, format of all docs.

### Canonical spec files

specifications under `docs/specifications`. Now its draft and should be updated if needed.

### Common rules for managing codes and programs

numbered as 00 to 09.

| Name | Contents |
|-----------|----------|
| `00-document-management.md` | Issues + result-logs (GitHub Issues substitute) |
| `09-dev-workflow.md` | Generators, generated-file discipline, pre-commit hook |


## Directories

| Directory | Contents |
|-----------|----------|
| `issues/` | Issues + result-logs (GitHub Issues substitute) |
| `plans/` | Implementation plans (`*-impl.md`) |
| `references/` | External / host-state reference material |
| `reviews/` | Reviews (pass-N / per-letter / aggregate / prompt) |
| `specifications/` | Project-wide normative specs (`NN-<topic>.md`) |
| `specifications/implementation/` | Per-implementation design drafts (`*-design.md`) |
| `learning` | Learn about `nvim` and its config; Don't need to check this folder when updating config |

See [AGENTS.md](../AGENTS.md) §3 for the summary and §4 for the review letter set.

## Generated references

- [references/deps-list.md](references/deps-list.md) — Auto-generated plugin list across all `deps/**/*.toml`.
