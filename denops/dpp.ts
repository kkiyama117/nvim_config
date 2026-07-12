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
import type {
  Ext as LazyExt,
  LazyMakeStateResult,
  Params as LazyParams,
} from "@shougo/dpp-ext-lazy";

// Denops
import type { Denops } from "@denops/std";
import * as fn from "@denops/std/function";

// std
import { expandGlob } from "@std/fs";
import { join } from "@std/path";

// --------------------------------------------------------------------------
// consts
// --------------------------------------------------------------------------
// TODO: define in the other file to use in multiple files
const home = Deno.env.get("HOME") ?? "~";
const xdgConfigHome = Deno.env.get("XDG_CONFIG_HOME") ?? `${home}/.config`;
const xdgCacheHome = Deno.env.get("XDG_CACHE_HOME") ?? `${home}/.cache`;
const nvimHome = Deno.env.get("NVIM_CONFIG_HOME") ?? `${xdgConfigHome}/nvim`;
const dppCacheHome= join(xdgCacheHome, "dpp");

// --------------------------------------------------------------------------
// Config file/folder path
// --------------------------------------------------------------------------
// Where plugin definition TOMLs live.
const dppTomlDir = join(nvimHome, "deps", "dpp");

// denops TypeScript files
const dppTSDir = join(nvimHome, "denops");

// Where inline vimrc fragments live.
// Files under `$nvimHome/lua` is autoloaded by neovim as a default.
const neovimLuaDir = join(nvimHome, "lua");

// --------------------------------------------------------------------------
// Dpp Config
// --------------------------------------------------------------------------
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
    const inlineLuaFiles = [
      join(neovimLuaDir, "visual.lua")
    ];
    args.contextBuilder.setGlobal({
      inlineVimrcs: inlineLuaFiles,
      extParams: {
        installer: {
          checkDiff: true,
          logFilePath: join(dppCacheHome, "installer-log.txt"),
          minCommitDays: 1,
          minTrustScore: 50,
          githubAPIToken: Deno.env.get("GITHUB_API_TOKEN"),
        },
      },
      protocols: [
        // TODO: setup `git` and `http`
      ],
    });

    const [context, options] = await args.contextBuilder.get(args.denops);
    const protocols = await args.denops.dispatcher.getProtocols() as Record<
      ProtocolName,
      Protocol
    >;
    
    // TODO: implement
    const recordPlugins: Record<string, Plugin> = {};
    // TODO: implement
    const ftplugins: Record<string, string> = {};
    // TODO: implement
    const hooksFiles: string[] = [];
    // TODO: implement
    let multipleHooks: MultipleHook[] = [];

    // Toml config
    //const [tomlExt, tomlOptions, tomlParams]: [
    //  TomlExt | undefined,
    //  ExtOptions,
    //  TomlParams,
    //] = await args.denops.dispatcher.getExt(
    //  "toml",
    //) as [TomlExt | undefined, ExtOptions, TomlParams];
    //if (tomlExt){
    //  // TODO: implement
    //}

    // Local plugins
    //const [localExt, localOptions, localParams]: [
    //  LocalExt | undefined,
    //  ExtOptions,
    //  LocalParams,
    //] = await args.denops.dispatcher.getExt(
    //  "local",
    //) as [LocalExt | undefined, ExtOptions, LocalParams];

    // TODO: search what is `packspec`
    //const [packspecExt, packspecOptions, packspecParams]: [
    //  PackspecExt | undefined,
    //  ExtOptions,
    //  PackspecParams,
    //] = await args.denops.dispatcher.getExt(
    //  "packspec",
    //) as [PackspecExt | undefined, ExtOptions, PackspecParams];

    const [lazyExt, lazyOptions, lazyParams]: [
      LazyExt | undefined,
      ExtOptions,
      LazyParams,
    ] = await args.denops.dispatcher.getExt(
      "lazy",
    ) as [LazyExt | undefined, ExtOptions, LazyParams];
    let lazyResult: LazyMakeStateResult | undefined = undefined;
    if (lazyExt) {
      const action = lazyExt.actions.makeState;

      lazyResult = await action.callback({
        denops: args.denops,
        context,
        options,
        protocols,
        extOptions: lazyOptions,
        extParams: lazyParams,
        actionParams: {
          plugins: Object.values(recordPlugins),
        },
      });
    }

    // check if config files are updated
    const checkFiles = [];
    checkFiles.push(await expandGlob(`${join(nvimHome, "init.lua")}`));
    for await (const file of expandGlob(`${dppTomlDir}/*`)) {
      checkFiles.push(file.path);
    }
    for await (const file of expandGlob(`${dppTSDir}/*`)) {
      checkFiles.push(file.path);
    }
    for await (const file of expandGlob(`${neovimLuaDir}/*`)) {
      checkFiles.push(file.path);
    }
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
    console.debug("Dpp ConfigReturn is");
    console.debug(result);
    return result;
  }
}
