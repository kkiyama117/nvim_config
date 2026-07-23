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

import type {
  Ext as TomlExt,
  Params as TomlParams,
  Toml,
} from "@shougo/dpp-ext-toml";
import type {
  Ext as LocalExt,
  Params as LocalParams,
} from "@shougo/dpp-ext-local";
import type {
  Ext as PackspecExt,
  Params as PackspecParams,
} from "@shougo/dpp-ext-packspec";
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
const dppCacheHome = join(xdgCacheHome, "dpp");
const dppCacheLocal = join(dppCacheHome, "local");

// --------------------------------------------------------------------------
// Config file/folder path
// --------------------------------------------------------------------------
// Where plugin definition TOMLs live.
const dppTomlDir = join(nvimHome, "deps");

// denops TypeScript files
//const dppTSDir = join(nvimHome, "denops");

// Where inline vimrc fragments live.
// Files under `$nvimHome/lua` is autoloaded by neovim as a default.
const neovimLuaDir = join(nvimHome, "lua");
//const neovimLuaHookDir = join(neovimLuaDir, "hooks");

// --------------------------------------------------------------------------
// Util functions
// --------------------------------------------------------------------------
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
export class Config extends BaseConfig {
  override async config(args: {
    denops: Denops;
    contextBuilder: ContextBuilder;
    basePath: string;
  }): Promise<ConfigReturn> {
    // List up vimrc/lua files
    console.debug("Load Dpp Config");
    // TODO: List up all files under `lua` (but avoid including sub dir like `lua/hooks`)
    const inlineVimrcs = [
      join(neovimLuaDir, "options.lua"),
      join(neovimLuaDir, "commands.lua"),
      join(neovimLuaDir, "mappings.lua"),
      join(neovimLuaDir, "filetype.lua"),
    ];
    const hasNvim = args.denops.meta.host === "nvim";
    const hasWindows = await fn.has(args.denops, "win32");
    // const hasGui = await fn.has(args.denops, "gui_running");
    if (hasNvim) {
      inlineVimrcs.push(join(neovimLuaDir, "specific/neovim.lua"));
    }
    if (hasWindows) {
      inlineVimrcs.push(join(neovimLuaDir, "specific/unix.lua"));
    }

    // Dpp ContextBuilder
    args.contextBuilder.setGlobal({
      inlineVimrcs,
      extParams: {
        installer: {
          checkDiff: true,
          logFilePath: join(dppCacheHome, "installer-log.txt"),
          maxProcesses: 8,
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
    const noLazyTomls = ["merge.toml", "dpp.toml"];

    const [tomlExt, tomlOptions, tomlParams]: [
      TomlExt | undefined,
      ExtOptions,
      TomlParams,
    ] = await args.denops.dispatcher.getExt(
      "toml",
    ) as [TomlExt | undefined, ExtOptions, TomlParams];

    if (tomlExt) {
      const tomls: Toml[] = [];
      // Load Dpp toml files and push into `tomls`
      for (const tomlFile of Deno.readDirSync(dppTomlDir)) {
        if (!tomlFile.isFile || !tomlFile.name.endsWith(".toml")) continue;
        const isLazy = !noLazyTomls.includes(tomlFile.name);
        tomls.push(
          await tomlExt.actions.load.callback({
            denops: args.denops,
            context,
            options,
            protocols,
            extOptions: tomlOptions,
            extParams: tomlParams,
            actionParams: {
              path: join(dppTomlDir, tomlFile.name),
              options: {
                lazy: isLazy,
              },
            },
          }) as Toml,
        );
      }

      // Merge toml results
      for (const toml of tomls) {
        if (!toml) continue;
        if (toml.plugins) {
          for (const plugin of toml.plugins) {
            recordPlugins[plugin.name] = plugin;
          }
        }
        if (toml.ftplugins) {
          mergeFtplugins(ftplugins, toml.ftplugins);
        }
        if (toml.multiple_hooks) {
          multipleHooks = multipleHooks.concat(toml.multiple_hooks);
        }
        if (toml.hooks_file) {
          hooksFiles.push(toml.hooks_file);
        }
      }
    }

    // Local plugins (library)
    const [localExt, localOptions, localParams]: [
      LocalExt | undefined,
      ExtOptions,
      LocalParams,
    ] = await args.denops.dispatcher.getExt(
      "local",
    ) as [LocalExt | undefined, ExtOptions, LocalParams];
    if (localExt) {
      const action = localExt.actions.local;

      const localPlugins = await action.callback({
        denops: args.denops,
        context,
        options,
        protocols,
        extOptions: localOptions,
        extParams: localParams,
        actionParams: {
          directory: dppCacheLocal,
          options: {
            merged: false,
          },
          includes: ["*"],
        },
      }) as Plugin[];

      const gitProtocol = protocols["git"] ?? null;

      for (const plugin of localPlugins) {
        if (plugin.name in recordPlugins) {
          const oldPlugin = recordPlugins[plugin.name];

          // Overwrite url
          const url = gitProtocol
            ? await gitProtocol.protocol.getUrl({
              denops: args.denops,
              plugin: oldPlugin,
              protocolOptions: gitProtocol.options,
              protocolParams: gitProtocol.params,
            })
            : "";

          recordPlugins[plugin.name] = {
            ...oldPlugin,
            ...plugin,
            url: url || plugin.url || oldPlugin.url,
          };
        } else {
          recordPlugins[plugin.name] = plugin;
        }
      }
    }

    const [packspecExt, packspecOptions, packspecParams]: [
      PackspecExt | undefined,
      ExtOptions,
      PackspecParams,
    ] = await args.denops.dispatcher.getExt(
      "packspec",
    ) as [PackspecExt | undefined, ExtOptions, PackspecParams];

    if (packspecExt) {
      const packspecPlugins = await packspecExt.actions.load.callback({
        denops: args.denops,
        context,
        options,
        protocols,
        extOptions: packspecOptions,
        extParams: packspecParams,
        actionParams: {
          basePath: args.basePath,
          plugins: Object.values(recordPlugins),
        },
      }) as Plugin[];

      for (const plugin of packspecPlugins) {
        if (!recordPlugins[plugin.name]) {
          recordPlugins[plugin.name] = plugin;
        }
      }
    }

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
      "deps/*.toml",
      "denops/**/*.ts",
      "**/*.vim",
    ]);
    // TODO: implement
    const groups = {
      ddc: {
        on_source: "ddc.vim",
      },
      ddu: {
        on_source: "ddu.vim",
      },
    };
    const result: ConfigReturn = {
      checkFiles,
      ftplugins,
      hooksFiles,
      multipleHooks,
      groups,
      plugins: lazyResult?.plugins ?? [],
      stateLines: lazyResult?.stateLines ?? [],
    };
    console.debug("Dpp ConfigReturn ==============================");
    console.debug(result);
    console.debug("Dpp ConfigReturn END===========================");
    return result;
  }
}

