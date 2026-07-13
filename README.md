# nvim_config

Neovim configuration migrated from host `~/.config/nvim`.

## Structure

- `init.lua` - Entry point
- `denops/` - TypeScript denops related configurations
- `deps/` - Plugin list; `Toml` file that loaded by `dpp-ext-toml`
- `docs/` - issues, specs, plans, and references
- `lua/` - Lua modules; `dpp_loader` and each config files
- `scripts/` - Deno scripts; Auto generation of Vim deps list from `dpp` toml files etc.

## Installation and manage

Fetch this repository as `~/.config/nvim` and load it.
`lua/dpp_loader.lua` install minimum deps (`dpp` plugins) at the first run of `nvim`. 
Then you must restart nvim or run `:call dpp#min#load_state("~/.cache/dpp")` to load and enable installed plugins.

```bash
git clone https://github.com/kkiyama117/nvim_config.git ~/.config/nvim
nvim
```

### Update deps list

In this nvim config, we manage vim plugins by `dpp.vim` and `dpp-ext-toml`.
If you want to check or add plugins, check `deps` folder and its toml files.

We have scripts to update documents and `installed plugin list`.
It also update check `minimum dependencies` (`dpp.vim` and `dpp-ext` plugins)

```bash
# Run auto-generator of documents
deno run gen
```

For a detail, see `docs/specifications/09-dev-workflow.md`.
