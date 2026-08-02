// std
import { join } from "@std/path";

const config_name = Deno.env.get("NVIM_CONFIG_NAME") ?? "nvim";
// XDG PATHS{{{
const home = Deno.env.get("HOME") ?? "~";
export const xdgConfigHome = Deno.env.get("XDG_CONFIG_HOME") ??
  join(home, ".config");
export const xdgCacheHome = Deno.env.get("XDG_CACHE_HOME") ??
  join(home, ".cache");
// }}}

// Common paths of neovim {{{
export const nvimConfigHome = Deno.env.get("NVIM_CONFIG_HOME") ??
  join(xdgConfigHome, config_name);
export const nvimCacheHome = Deno.env.get("NVIM_CACHE_HOME") ??
  join(xdgCacheHome, config_name);

// Where inline vimrc fragments live.
// Files under `$nvimHome/lua` can be loaded by `require(module name)`
export const nvimLuaHome = join(nvimConfigHome, "lua");
export const nvimLuaHookDir = join(nvimLuaHome, "hooks");

// history files
export const shellHistoryPaths = [
  join(xdgCacheHome, `ddt-shell-history`),
  "~/.local/share/zsh/history",
];

// }}}

