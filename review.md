
Review done. Bottom line: the migration is sound — behavior parity with the fork holds, the two fork workarounds were eliminated by design rather than dropped, and post-migration sessions ran with no LSP errors in the log. A few minor items below.

Scope note: main..kakehashi_update carries ~20 commits including older unrelated work (heirline, agentic, the .lua→.dpp hook renames, the mason drop). I reviewed the kakehashi migration — the final state plus commit 9bf9ef5 — in depth.

What checks out

- Config parity is exact. lua/kakehashi/config.lua is the fork's file with only comments changed — same bridged_servers, filetypes collection (including the dpp → kakehashi attach path), pull-only diagnostics sealing, dpp parser route, markdown aggregation priorities, and rmd/quarto bases. searchPaths and the on_init semanticTokensProvider.range = false tweak survive in the hook, and the highlighting handoff (LspTokenUpdate takeover, with the dpp-buffer exception) moved from an LspAttach autocmd to on_attach in vim.lsp.config — equivalent, since on_attach only fires for the kakehashi client anyway.
- The dropped fork workarounds are justified, not regressions. With --config-file, the languageServers are complete when kakehashi spawns, so there's no didChangeConfiguration to race — the diagnostics re-pull polling and the settings.kakehashi wire-shape shim genuinely have nothing left to fix.
- Settings carried over completely. overrides.toml reproduces the denols settings and root markers and the emmylua semanticTokens/LuaJIT/globals settings from nvim-lspconfig.dpp; gopls/pyright/rust_analyzer/tombi had no custom settings to carry. The emmylua on_init defer-toy dead code under the fork(nvim never started emmylua ace.library correctly movedto the generated library.tomerved.- It works in practice. All i-lspconfig and wereconcatenated into the generasp.toml; the deep mergecomposes correctly (fragmentnest.land = false bothpresent). Submodule removal ree clean), and the 01:25sessions after the commit lo.

Findings
                                                                                      1. Fragile load ordering (dekakehashi hook needskakehashi-lspconfig on the rut that's guaranteed only bylisting order among two on_sies. It works today, butdepends = ["kakehashi-lspconntry would make the orderingexplicit instead of position plus no bridged servers.
2. exepath resolution was dropped — a real behavior change. Fragments use bare        commands (["deno", "lsp"]), inherited PATH rather thanvim.fn.exepath() at bridge time. Fine when nvim starts from a mise-activated shell (asit does now), but an nvim laithout mise in PATH wouldfail to spawn the children. olve the cmds into thegenerated toml; otherwise ju3. Nits: library.toml is buidirs of not-yet-sourced lazyplugins are absent from emmyon as the old inlinesettings, inherited not intr/plugins directory remains(harmless; rmdir at will). Aff working doc) is committed
on the branch — decide whethin.

Nothing here blocks merging;d actually make before doing
so.

