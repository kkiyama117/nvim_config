# denops / dpp — reading list

Reference of upstream docs/pages to read when working on the dpp denops config (`denops/deps.ts`, `denops/helper.ts`, `denops/dpp.ts`). All URLs verified reachable on 2026-07-11.
And We should check [`Shougo`'s vim settings](https://github.com/Shougo/shougo-s-github/blob/master/vim/rc/dpp.ts) to get latest "official" dpp usage

Status: reference (stable).

## Priority map

| P | What | Why needed for this project |
|---|------|------------------------------|
| P0 | dpp.vim help + README config example | Defines `BaseConfig`/`config()` contract and the Vim-side `dpp#*` API the loader calls |
| P0 | dpp.vim `denops/dpp/` source + jsr exports | Required to rewrite `deps.ts` imports and the `dpp.ts` config entry |
| P0 | denops.vim help (`:h denops`) | Startup order, `DenopsReady`, `g:denops#deno` — all used by `lua/dpp_loader.lua` |
| P1 | dpp ext/protocol help | `dpp-ext-toml`/`-lazy`/`-installer`/`-local`/`-packspec`, `dpp-protocol-git`/`-http` — referenced by `helper.ts` `extAction` calls |
| P1 | denops std (`@denops/std`) API | `Denops`, `fn`, `vars`, `Entrypoint` used in `deps.ts` and `dpp.ts` |
| P2 | denops documentation site | Conceptual background (entrypoint, dispatcher, dependencies) |
| P2 | Deno runtime manual | `deno check`, import maps / `deno.json`, jsr specifiers |

## dpp.vim (Shougo/dpp.vim)

| Page | URL | Note |
|------|-----|------|
| README (Install / Config example / Extensions / Protocols) | https://github.com/Shougo/dpp.vim/blob/main/README.md | Config example is Vim script; use as the contract reference |
| Vim help | repo `doc/dpp.txt` → `:h dpp` | Authoritative. FAQ explains Deno/"dark powered" |
| jsr package | https://jsr.io/@shougo/dpp-vim | Latest `6.6.0`; package page + doc |
| jsr doc (symbol browser) | https://jsr.io/@shougo/dpp-vim/doc | Per-symbol docs |
| Source — denops entry | repo `denops/dpp/app.ts` | `main: Entrypoint`, dispatcher methods (`makeState`, `registerPath`, …) |
| Source — config base | repo `denops/dpp/base/config.ts` | `BaseConfig`, `ConfigArguments`, `ConfigReturn`, `MultipleHook` |
| Source — dpp base | repo `denops/dpp/base/dpp.ts` | `Dpp` interface |
| Source — types | repo `denops/dpp/types.ts` | `Context`, `ContextBuilder`, `DppOptions`, `Plugin`, `BaseParams` |
| Source — utils | repo `denops/dpp/utils.ts` | `getLazyPlugins`, `mergeFtplugins`, `parseHooksFile`, … |
| Package exports map | repo `denops/dpp/deno.json` | `exports`: `./config`, `./dpp`, `./ext`, `./protocol`, `./types`, `./utils` |
| Workspace root | repo `deno.jsonc` | workspace + tasks (`deno check denops/**/*.ts`) |

### dpp extensions (Shougo/dpp-ext-*)

| Ext | Repo help | jsr |
|-----|-----------|-----|
| toml (toml loader) | `doc/dpp-ext-toml.txt` in https://github.com/Shougo/dpp-ext-toml | `@shougo/dpp-ext-toml` |
| lazy (lazy load) | `doc/dpp-ext-lazy.txt` in https://github.com/Shougo/dpp-ext-lazy | `@shougo/dpp-ext-lazy` |
| installer (git/http install) | `doc/dpp-ext-installer.txt` in https://github.com/Shougo/dpp-ext-installer | `@shougo/dpp-ext-installer` |
| local (local plugins) | `doc/dpp-ext-local.txt` in https://github.com/Shougo/dpp-ext-local | `@shougo/dpp-ext-local` |
| packspec (packspec.toml) | `doc/dpp-ext-packspec.txt` in https://github.com/Shougo/dpp-ext-packspec | `@shougo/dpp-ext-packspec` |

### dpp protocols (Shougo/dpp-protocol-*)

| Protocol | Repo help | jsr |
|----------|-----------|-----|
| git | `doc/dpp-protocol-git.txt` in https://github.com/Shougo/dpp-protocol-git | `@shougo/dpp-protocol-git` |
| http | `doc/dpp-protocol-http.txt` in https://github.com/Shougo/dpp-protocol-http | `@shougo/dpp-protocol-http` |

## denops.vim (vim-denops/denops.vim)

| Page | URL | Note |
|------|-----|------|
| README (For users / Confirm denops) | https://github.com/vim-denops/denops.vim/blob/main/README.md | `g:denops#deno`, install, `DenopsHello` |
| Vim help | repo `doc/denops.txt` → `:h denops` | Startup, `DenopsReady`, server lifecycle |

### denops std (`@denops/std`, vim-denops/deno-denops-std)

| Page | URL | Note |
|------|-----|------|
| jsr package | https://jsr.io/@denops/std | Latest `8.2.0` |
| jsr doc | https://jsr.io/@denops/std/doc | Symbol-level docs |
| GitHub repo | https://github.com/vim-denops/deno-denops-std | Per-module dirs (`function/`, `variable/`, `autocmd/`, `batch/`, `argument/`, …) |

### denops documentation site (mdBook)

| Page | URL |
|------|-----|
| Top | https://vim-denops.github.io/denops-documentation/ |
| Introduction | https://vim-denops.github.io/denops-documentation/introduction.html |
| Install | https://vim-denops.github.io/denops-documentation/install.html |
| Getting Started | https://vim-denops.github.io/denops-documentation/getting-started/README.html |
| Tutorial: Hello world — minimal Denops plugin | https://vim-denops.github.io/denops-documentation/tutorial/helloworld/creating-a-minimal-denops-plugin.html |
| Tutorial: Managing dependencies | https://vim-denops.github.io/denops-documentation/tutorial/helloworld/managing-dependencies.html |
| API Reference | https://vim-denops.github.io/denops-documentation/api-reference.html |
| FAQ | https://vim-denops.github.io/denops-documentation/faq.html |

Source of the site's structure: repo `vim-denops/denops-documentation` `src/SUMMARY.md`.

## Deno runtime / jsr

| Page | URL | Note |
|------|-----|------|
| Install Deno | https://docs.deno.com/runtime/getting_started/installation/ | `g:denops#deno` path source |
| jsr (registry) | https://jsr.io/ | How `jsr:@scope/name@ver/subpath` resolves |
| Deno config / import maps | https://docs.deno.com/runtime/fundamentals/configuration/ | `deno.json` `imports`/`exports` |

## Reading order for the dpp config migration

1. dpp.vim README "Config example" + `:h dpp` — understand the Vim→denops contract (`dpp#make_state`, base path, check files).
2. dpp.vim `denops/dpp/app.ts` + `deno.json` exports — map dispatcher methods and package subpaths.
3. dpp.vim `denops/dpp/base/config.ts` + `types.ts` — confirm `ConfigArguments`/`ConfigReturn`/`Plugin` shape for `dpp.ts` and `helper.ts`.
4. `:h dpp-ext-toml` and `:h dpp-ext-lazy` — `helper.ts` calls `extAction(..., "toml", "load", ...)` and lazy make-state.
5. denops.vim `:h denops` — verify `DenopsReady` autocmd and boot sequence used in `lua/dpp_loader.lua`.
6. `@denops/std` doc — `fn.globpath`, `vars`, `Denops`, `Entrypoint` signatures.
