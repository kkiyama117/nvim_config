# kakehashi.nvim: drop the fork, use upstream + kakehashi-lspconfig

Multi-agent handoff. Three phases with review gates:

- **Phase 1a (local audit)** and **Phase 1b (upstream research)** are
  independent — run them in parallel as two agents.
- Review both reports, then paste them into **Phase 2** (planning agent).
- Review the Phase 2 plan before applying anything in the main session.

## Shared context (paste into every agent prompt)

```
Repo: ~/.config/nvim, a personal dpp.vim-based Neovim config.

It currently uses a fork of atusy/kakehashi.nvim
(kkiyama117/kakehashi.nvim, git submodule at plugins/kakehashi.nvim —
the ONLY local plugin; origin points at the fork, no upstream remote is
configured). kakehashi is the sole Neovim LSP client; bridged servers
(denols, emmylua_ls, gopls, pyright, rust_analyzer, tombi, vtsls) run as
its children. Server binaries are installed by mise, NOT mason.nvim.

The fork's own history says it adds three vimrc-specific files on top of
upstream (commit 87d14de "Add vimrc bridge config"):

1. plugin/kakehashi.lua — vim.lsp.config('kakehashi', ...) registration
   (cmd, filetypes, init_options with searchPaths + languages), an
   on_init hook that sets semanticTokensProvider.range = false,
   vim.lsp.enable('kakehashi'), and an LspAttach autocmd that calls
   bridge.inherit and manages the highlighting handoff: on LspTokenUpdate
   kakehashi's semantic tokens take over (syntax OFF + treesitter.stop),
   EXCEPT filetype == 'dpp' where semantic tokens are disabled for that
   buffer and tree-sitter stays in charge.
   init_options.searchPaths includes ~/.local/share/kakehashi,
   $NVIM_CONFIG_HOME/kakehashi (repo-owned queries + custom parser), and
   the plugin's own runtimepath entry.
2. lua/kakehashi/config.lua — bridged_servers list, per-server filetypes
   (used as an EXTENSION: filetypes listed there but absent from the nvim
   LSP config still get bridged, e.g. dpp -> emmylua_ls), and an
   init_options.languages table: host-bridge languages, markdown
   aggregation priorities, pull-only diagnostics (publishDiagnostics
   priorities = {}), and a dpp route with a custom tree-sitter parser at
   $NVIM_CONFIG_HOME/kakehashi/parser/dpp.so whose injected lua is
   bridged to emmylua_ls.
3. lua/kakehashi/bridge.lua — replaces upstream's
   inherit_nvim_lsp_config, adding: vim.fn.exepath() resolution for
   server binaries (mise-installed), root_markers -> workspaceMarkers
   inheritance, passthrough of per-server settings/init_options, sending
   runtime settings under settings.kakehashi (upstream reportedly still
   uses a flat `settings`), and a diagnostics re-pull after the config
   reload (the initial textDocument/diagnostic pull races
   didChangeConfiguration, so with pull-only aggregation the first answer
   can be empty and nvim never re-pulls on its own).

BUT the fork's git log also shows core changes that may or may not be
upstream now: 7a613f5 "perf(captures): coalesce edit bursts into one
in-flight request per buffer", 2d8df33 "feat(kakehashi): can inherit
rootMarkers", 839eb8d "fix". Do not trust the three-file story — verify.

Other repo facts:
- deps/nvim/lsp.toml lines 22-28: the kakehashi [[plugins]] entry uses
  local = true + path (registered via the dpp-ext-local scan in
  denops/dpp.ts), on_source = "nvim-lspconfig", on_event = "FileType",
  external_commands = ["kakehashi"].
- lua/hooks/nvim-lspconfig.dpp holds the per-server vim.lsp.config
  definitions the bridge inherits. It must NOT be touched.
- Repo-owned assets live at $NVIM_CONFIG_HOME/kakehashi/: parser/dpp.so,
  queries/dpp/{highlights,injections}.scm, tree-sitter-dpp/ (grammar
  source). after/ftplugin/dpp.lua starts tree-sitter for *.dpp buffers.
- Background on the dpp filetype design: .agents/issues/dpp-filetype.md.

Goal: drop the fork in favor of unmodified upstream atusy/kakehashi.nvim
+ its companion plugin kakehashi-lspconfig + a small user init, like
atusy's own dotfiles do.
```

## Phase 1a — local divergence audit (read-only, no web needed beyond git fetch)

```
[Shared context above.]

In the submodule at ~/.config/nvim/plugins/kakehashi.nvim:

1. Add upstream and fetch:
     git remote add upstream https://github.com/atusy/kakehashi.nvim
     git fetch upstream
2. Find the merge-base with upstream's default branch and produce the
   full divergence: every commit and every changed file on the fork side
   that is not in upstream, AND anything upstream has since gained that
   might supersede fork commits (search upstream log for captures
   coalescing / rootMarkers inheritance / equivalents of 839eb8d).
3. Classify each fork-side change as:
     (a) vimrc-specific glue (the three files above) — replaceable by
         user config,
     (b) core behavior change with an upstream equivalent (cite the
         upstream commit), or
     (c) core behavior change with NO upstream equivalent — dropping the
         fork silently regresses this. List these prominently.

Do not edit anything. Report: merge-base hash, upstream HEAD hash, the
classified change list with file paths, and the (c) regressions section
(explicitly say "none" if empty).
```

## Phase 1b — upstream + ecosystem research (read-only, web)

```
[Shared context above.]

Research the actual current source (read the repos, not from memory):
  - atusy/kakehashi.nvim, current default branch — record the exact
    commit hash you read.
  - kakehashi-lspconfig — find the repo, confirm the exact org/name.
  - atusy/dotfiles: dot_config/nvim/lua/plugins/lsp/init.lua
    (https://github.com/atusy/dotfiles/blob/main/dot_config/nvim/lua/plugins/lsp/init.lua)
    and any other kakehashi/kakehashi-lspconfig usage in that repo
    (lazy-loading setup, init snippets, queries/parsers).

Answer specifically, each with file + line citations:
  a. Does kakehashi-lspconfig provide the vim.lsp.config('kakehashi',...)
     registration, vim.lsp.enable, and the LspAttach bridge-inherit call,
     so plugin/kakehashi.lua becomes unnecessary? Does it also handle the
     semantic-token highlighting handoff (syntax off / treesitter stop on
     LspTokenUpdate), and can that handoff be disabled per-filetype?
  b. Does the current upstream inherit path (inherit_nvim_lsp_config or
     kakehashi-lspconfig's equivalent):
       - resolve server binaries via exepath (or otherwise work with
         non-mason, PATH-installed binaries)?
       - send runtime settings under settings.kakehashi vs flat settings?
       - inherit root_markers as workspaceMarkers?
       - pass through per-server settings and init_options?
     For each miss: is there a supported hook/option to add it without
     reimplementing the whole function?
  c. Diagnostics: does upstream/kakehashi-lspconfig have a documented way
     to re-pull diagnostics after the didChangeConfiguration reload, or
     is the race a non-issue in their setup (e.g. config is complete
     before attach, or they don't use pull-only aggregation)? How does
     atusy's dotfiles config get diagnostics?
  d. Is there a supported way to extend init_options per user config:
       - languages: route a custom filetype (dpp) with a custom parser
         path to a bridged server (emmylua_ls), keep markdown aggregation
         priorities and pull-only publishDiagnostics sealing;
       - searchPaths: add $NVIM_CONFIG_HOME/kakehashi;
       - filetypes: attach kakehashi to a filetype the nvim LSP configs
         don't list (dpp);
       - the on_init semanticTokensProvider.range = false tweak (still
         needed? default upstream behavior?).

Finish with a two-column summary: covered by upstream +
kakehashi-lspconfig as-is vs. still needs custom Lua in the vimrc.
Do NOT propose the migration diff yet — findings only.
```

## Phase 2 — implementation plan (after reviewing 1a + 1b)

```
[Shared context above.]
[Paste Phase 1a report.]
[Paste Phase 1b report.]

Draft a migration plan (NOT yet applied) replacing the fork submodule
with upstream atusy/kakehashi.nvim + kakehashi-lspconfig:

- Exact deps/nvim/lsp.toml [[plugins]] entries: repo, depends,
  on_source/on_event, external_commands, hooks_file. Both plugins must
  stay lazy on FileType exactly like today (on_source = "nvim-lspconfig",
  on_event = "FileType") — eager-loading breaks dpp's lazy `depends`
  resolution. Replaces the current local = true entry.
- The user init Lua, following this repo's hooks_file convention: a new
  lua/hooks/kakehashi.nvim.dpp (the fork's plugin/kakehashi.lua comment
  says it replaced exactly that file) and/or kakehashi-lspconfig.dpp.
  Full file contents.
- Behavior that must be preserved exactly (flag explicitly if any item
  regresses given the Phase 1 findings):
    * dpp filetype: *.dpp attaches kakehashi, injected lua routes to
      emmylua_ls via the custom parser at
      $NVIM_CONFIG_HOME/kakehashi/parser/dpp.so, tree-sitter keeps
      highlighting (semantic tokens disabled for dpp buffers only);
      every other filetype keeps the kakehashi-owns-highlighting handoff.
    * mise/exepath binary resolution; settings.kakehashi wire shape;
      root_markers/settings/init_options inheritance.
    * init_options.searchPaths including $NVIM_CONFIG_HOME/kakehashi.
    * pull-only diagnostics aggregation + whatever replaces the re-pull
      workaround (per Phase 1b finding c).
    * markdown/quarto/rmd aggregation priorities and host-bridge
      languages from config.lua.
    * any Phase 1a class-(c) fork-only core change — if one exists, the
      plan must say how it's handled (upstream PR, accepted regression,
      or blocker).
- Every file to add/edit/delete with full contents or exact diffs.
  Submodule removal mechanics: git rm plugins/kakehashi.nvim, the
  .gitmodules entry, and .git/modules cleanup. Note whether the
  dpp-ext-local scan in denops/dpp.ts should stay (kakehashi was the
  only local plugin) — recommend, don't silently remove.
- Do NOT touch lua/hooks/nvim-lspconfig.dpp.
- End with a verification checklist: e.g. open a *.dpp file (tree-sitter
  colors, emmylua diagnostics in injected lua), open a lua/python file
  (handoff fires, bridged diagnostics arrive), :checkhealth vim.lsp,
  dpp cache rebuild steps.

Output as a reviewable plan. Do not apply it.
```
