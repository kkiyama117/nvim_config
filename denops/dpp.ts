import type {
  Context,
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

import type {
  Ext as TomlExt,
  Params as TomlParams,
  Toml,
} from "@shougo/dpp-ext-toml";
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
const dppTomlDir = join(nvimHome, "deps");

// denops TypeScript files
const dppTSDir = join(nvimHome, "denops");

// Where inline vimrc fragments live.
// Files under `$nvimHome/lua` is autoloaded by neovim as a default.
const neovimLuaDir = join(nvimHome, "lua");

// --------------------------------------------------------------------------
// Util functions
// --------------------------------------------------------------------------
async function gatherTomls(
  denops: Denops,
  context: Context,
  options: Awaited<ReturnType<ContextBuilder["get"]>>[1],
  protocols: Record<ProtocolName, Protocol>,
  tomlExt: TomlExt,
  tomlOptions: ExtOptions,
  tomlParams: TomlParams,
  path: string,
  noLazyTomlNames: string[],
): Promise<Toml[]> {
  const tomls: Toml[] = [];

  for (const tomlFile of Deno.readDirSync(path)) {
    if (!tomlFile.isFile || !tomlFile.name.endsWith(".toml")) continue;
    const isLazy = !noLazyTomlNames.includes(tomlFile.name);
    tomls.push(
      await tomlExt.actions.load.callback({
        denops,
        context,
        options,
        protocols,
        extOptions: tomlOptions,
        extParams: tomlParams,
        actionParams: {
          path: join(path, tomlFile.name),
          options: {
            lazy: isLazy,
          },
        },
      }) as Toml,
    );
  }

  return tomls;
}

async function gatherCheckFiles(
  denops: Denops,
  path: string,
  globs: string[],
): Promise<string[]> {
  const checkFiles: string[] = [];
  for (const glob of globs) {
    checkFiles.push(await fn.globpath(denops, path, glob, true, true));
  }

  return checkFiles.flat();
}

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
    // List up vimrc/lua files
    console.debug("Load Dpp Config");
    const hasNvim = args.denops.meta.host === "nvim"
    const hasWindows = await fn.has(args.denops, "win32");
    const hasGui = await fn.has(args.denops, "gui_running");
    const inlineVimrcs = [
      join(neovimLuaDir, "visual.lua"),
    ];

    // Dpp ContextBuilder
    args.contextBuilder.setGlobal({
      inlineVimrcs,
      extParams: {
        installer: {
          checkDiff: true,
          logFilePath: join(dppCacheHome, "installer-log.txt"),
          minCommitDays: 1,
          minTrustScore: 50,
          githubAPIToken: Deno.env.get("GITHUB_API_TOKEN"),
        },
      },
      protocols: ["git"],
      protocolParams: {
        git: { enablePartialClone: true },
      },
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

    // avoid lazy loading 
    const noLazyTomls = ["dpp.toml"];

    const [tomlExt, tomlOptions, tomlParams]: [
      TomlExt | undefined,
      ExtOptions,
      TomlParams,
    ] = await args.denops.dispatcher.getExt(
      "toml",
    ) as [TomlExt | undefined, ExtOptions, TomlParams];

    if (tomlExt) {
      const tomls = await gatherTomls(
        args.denops,
        context,
        options,
        protocols,
        tomlExt,
        tomlOptions,
        tomlParams,
        dppTomlDir,
        noLazyTomls,
      );
      for (const toml of tomls) {
        if (!toml) continue;
        if (toml.plugins) {
          for (const plugin of toml.plugins) {
            recordPlugins[plugin.name] = plugin;
          }
        }
        if (toml.hooks_file) hooksFiles.push(toml.hooks_file);
        if (toml.ftplugins) {
          for (const filetype of Object.keys(toml.ftplugins)) {
            ftplugins[filetype] = ftplugins[filetype]
              ? `${ftplugins[filetype]}\n${toml.ftplugins[filetype]}`
              : toml.ftplugins[filetype];
          }
        }
        if (toml.multiple_hooks) {
          multipleHooks = multipleHooks.concat(toml.multiple_hooks);
        }
      }
    }

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

    const checkFiles = await gatherCheckFiles(args.denops, nvimHome, [
      "lua/**/*.lua",
      "**/*.toml",
      "denops/**/*.ts",
      "**/*.vim",
    ]);
    // TODO: implement
    const groups = undefined;
    const result: ConfigReturn = {
      checkFiles,
      ftplugins,
      hooksFiles,
      multipleHooks,
      groups,
      plugins: lazyResult?.plugins ?? [],
      stateLines: lazyResult?.stateLines ?? [],
    };
    console.debug("Dpp ConfigReturn is");
    console.debug(result);
    return result;
  }
}
