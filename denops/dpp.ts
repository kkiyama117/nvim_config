import type {
  ContextBuilder,
  ExtOptions,
  Plugin,
  ProtocolName,
} from "@shougo/dpp-vim/types";

import {
  BaseConfig,
  type ConfigReturn,
  type MultipleHook,
} from "@shougo/dpp-vim/config";
import { Protocol } from "@shougo/dpp-vim/protocol";
import { mergeFtplugins } from "@shougo/dpp-vim/utils";

//import type {
//  Ext as TomlExt,
//  Params as TomlParams,
//} from "@shougo/dpp-ext-toml";
//import type {
//  Ext as LocalExt,
//  Params as LocalParams,
//} from "@shougo/dpp-ext-local";
//import type {
//  Ext as PackspecExt,
//  Params as PackspecParams,
//} from "@shougo/dpp-ext-packspec";
//import type {
//  Ext as LazyExt,
//  LazyMakeStateResult,
//  Params as LazyParams,
//} from "@shougo/dpp-ext-lazy";

// Denops
import type { Denops } from "@denops/std";
import * as fn from "@denops/std/function";

// std
import { expandGlob } from "@std/fs";
import { join } from "@std/path";

// consts
// TODO: define in the other file to use in multiple files
const home = Deno.env.get("HOME") ?? "~";
const configHome = Deno.env.get("XDG_CONFIG_HOME") ?? `${home}/.config`;
const nvimHome = Deno.env.get("NVIM_CONFIG_HOME") ?? `${configHome}/nvim`;

// Where plugin definition TOMLs live.
const dppTomlDir = join(configHome, "nvim", "dpp");

// Where inline vimrc fragments live.
// Files under `$nvimHome/lua` is autoloaded by neovim as a default.
const neovimLuaDir = join(nvimHome, "lua");

// dpp loads the module named export `Config` (see dpp.vim app.ts: `new mod.Config()`).
export class Config extends BaseConfig{
  override async config(args:{
    denops: Denops;
    contextBuilder: ContextBuilder;
    basePath: string;
  }):Promise<ConfigReturn>{
    console.debug("Load Dpp Config");
    const hasNvim = args.denops.meta.host === "nvim"
    const hasWindows = await fn.has(args.denops, "win32");
    const hasGui = await fn.has(args.denops, "gui_running");
    // TODO: inline lua
    const inlineVimrcs = [];
    // TODO: implement
    const checkFiles = undefined;
    // TODO: implement
    const ftplugins = undefined;
    // TODO: implement
    const hooksFiles = undefined;
    // TODO: implement
    const multipleHooks = [];
    // TODO: implement
    const groups = undefined;
    // TODO: implement
    const plugins = [];
    // TODO: implement
    const stateLines = [];
    
    // Return `ConfigReturn`
    // TODO: ONLY IF DEBUG
    const result: ConfigReturn = {
      checkFiles,
      ftplugins,
      hooksFiles,
      multipleHooks,
      groups,
      plugins: plugins ?? [],
      stateLines: stateLines ?? [],
    };
    console.log("Dpp ConfigReturn is");
    console.log(result);
    return result;
  }
}
