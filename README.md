# nvim_test

See [doc](https://github.com/kkiyama117/nvim_config/blob/main/doc/kkiyama117-nvim.jax)
or call |kkiyama117-nvim.txt|

## Install

### Required
TODO: write it down and make `doc` of `Install`

### How to setup

- 1: Fetch

```bash
git clone https://github.com/kkiyama117/nvim_config.git ~/.config/nvim
```

- 2: Run

```bash
# `lua/bootloader` called and install deps of setup.
# bootloader has 3 layers; minimum deps (Layer 1), dpp-ext plugins (Layer 2),
# and whole plugins and configs (Layer 3).
# Each layer run `fallback` if something failed. Installing missing plugins,
# try to run `dpp#make_state`, and run `:restart` to apply configs.
nvim
```

### Others

read the [vimdoc](./doc/kkiyama117-nvim.jax).

