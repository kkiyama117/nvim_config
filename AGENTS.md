# AGENTS — nvim_config

New config and documents of `neovim`.

## 0. Top-Level Rules

- Dont Praise and filler. prefaces like "Great question" are not needed. Simple output; like table.

## 1. Project overview

### Main plugins

| Item | description |
|------|-------|
| Plugin manager | [rvpm](https://github.com/yukimemi/rvpm) (Rust CLI, ahead-of-time `loader.lua`) |
| External runtime | [deno](https://deno.land/) (for denops plugins, via mise; not used by the plugin manager) |
| Japanese input | [skkeleton](https://github.com/vim-skk/skkeleton) |


## 2. Hard constraints (do not violate without permission)

| ID | Rule | Rationale |
|----|------|-----------|
| 00 | EVERYTHING only for AI agents are under `doc/agents` | TODO |
| 01 | Write `doc` as vimdoc | TODO |

When a new hard constraint is discovered, append it to this table.

