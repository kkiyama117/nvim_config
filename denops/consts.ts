// std
import { join } from "@std/path";

// XDG PATHS{{{
const home = Deno.env.get("HOME") ?? "~";
export const xdgConfigHome = Deno.env.get("XDG_CONFIG_HOME") ??
  join(home, ".config");
export const xdgCacheHome = Deno.env.get("XDG_CACHE_HOME") ??
  join(home, ".cache");
// }}}

// Common paths of neovim {{{
export const nvimConfigHome = Deno.env.get("NVIM_CONFIG_HOME") ??
  join(xdgConfigHome, "nvim");
export const nvimCacheHome = Deno.env.get("NVIM_CONFIG_HOME") ??
  join(xdgConfigHome, "nvim");

// Where inline vimrc fragments live.
// Files under `$nvimHome/lua` can be loaded by `require(module name)`
export const nvimLuaHome = join(nvimConfigHome, "lua");
export const neovimLuaHookDir = join(nvimLuaHome, "hooks");
// }}}

