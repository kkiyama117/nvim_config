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
import * as vars from "@denops/std/variable";

// std
import { basename, join } from "@std/path";

// consts
import { home, nvimCacheHome, nvimConfigHome } from "./consts.ts";
import { gatherGlobs } from "./dpp/utils.ts";

// --------------------------------------------------------------------------
// Config and Cache path
// --------------------------------------------------------------------------
const dppCacheHome = join(nvimCacheHome, "dpp");
const dppCacheLocal = join(dppCacheHome, "local");

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
    const is_debug = await vars.g.get(args.denops, "vimrc#is_debug");
    const hasNvim = args.denops.meta.host === "nvim";
    const hasWindows = await fn.has(args.denops, "win32");

    // ----------------------------------------------------------------------
    // Collect Inline Vimrcs
    // ----------------------------------------------------------------------
    const inlineVimrcs = (await gatherGlobs(
      args.denops,
      [
        "lua/vimrc/*",
        hasNvim ? ["lua/vimrc/nvim/*"] : ["lua/vimrc/vim/*"],
        hasWindows ? ["lua/vimrc/windows/*"] : ["lua/vimrc/unix/*"],
      ].flat(),
      nvimConfigHome,
    )).filter((path: string) => path.match(/\.(?:vim|lua)$/));

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
      // neotest-deno's doc defines the same *neotest.config* tag as
      // nvim-neotest/neotest, which makes :helptags fail with E154.
      // Skip merging its doc (a near-copy of neotest's) into .dpp/doc.
      skipMergeFilenamePattern:
        "^tags(?:-\\w\\w)?$|^package.json$|^neotest-deno\\.txt$",
    });

    const [context, options] = await args.contextBuilder.get(args.denops);
    const protocols = await args.denops.dispatcher.getProtocols() as Record<
      ProtocolName,
      Protocol
    >;

    const recordPlugins: Record<string, Plugin> = {};
    const ftplugins: Record<string, string> = {};
    const hooksFiles: string[] = [];
    let multipleHooks: MultipleHook[] = [];

    // ----------------------------------------------------------------------
    // Collect Plugins defined in Toml
    // ----------------------------------------------------------------------
    // avoid lazy loading
    const noLazyTomls = ["no_lazy.toml"];

    const [tomlExt, tomlOptions, tomlParams]: [
      TomlExt | undefined,
      ExtOptions,
      TomlParams,
    ] = await args.denops.dispatcher.getExt(
      "toml",
    ) as [TomlExt | undefined, ExtOptions, TomlParams];

    if (tomlExt) {
      const tomlGlobs = ["deps/**/*.toml"];
      const tomlPaths = await gatherGlobs(
        args.denops,
        tomlGlobs,
        nvimConfigHome,
      );

      const tomls = await Promise.all(
        tomlPaths
          .filter((tomlPath) => tomlPath.endsWith(".toml"))
          .map((tomlPath) => {
            const isLazy = !noLazyTomls.includes(basename(tomlPath));
            return tomlExt.actions.load.callback({
              denops: args.denops,
              context,
              options,
              protocols,
              extOptions: tomlOptions,
              extParams: tomlParams,
              actionParams: {
                path: tomlPath,
                options: {
                  lazy: isLazy,
                },
              },
            }) as Promise<Toml>;
          }),
      );

      // Merge toml results
      tomls.forEach((toml) => {
        toml.plugins?.forEach((plugin) => {
          recordPlugins[plugin.name] = plugin;
        });

        if (toml.ftplugins) {
          mergeFtplugins(ftplugins, toml.ftplugins);
        }
        if (toml.multiple_hooks) {
          multipleHooks = multipleHooks.concat(toml.multiple_hooks);
        }
        if (toml.hooks_file) {
          // dpp expects a flat string[]; a nested array reaches
          // dpp#util#_expand as a List and fails with E691.
          hooksFiles.push(...[toml.hooks_file].flat());
        }
      });
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

      const localPlugins: Plugin[] = [];
      for (
        const directory of [
          dppCacheLocal,
          join(home, "programs", "nvim_plugins"),
          join(nvimConfigHome, "plugins"),
        ]
      ) {
        const found = await action.callback({
          denops: args.denops,
          context,
          options,
          protocols,
          extOptions: localOptions,
          extParams: localParams,
          actionParams: {
            directory,
            options: {
              merged: false,
            },
            includes: ["*"],
          },
        }) as Plugin[];
        localPlugins.push(...found);
      }

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

    // Call `make_state` if these files are updated
    const checkFiles = await gatherGlobs(args.denops, [
      "init.lua",
      "lua/**/*.lua",
      "lua/hooks/**/*.dpp",
      "deps/**/*.toml",
      "denops/**/*.ts",
      "**/*.vim",
    ], nvimConfigHome);
    const groups = {
      dpp: {
        on_source: "dpp.vim",
      },
      ddc: {
        on_source: "ddc.vim",
      },
      ddt: {
        on_source: "ddt.vim",
      },
      ddu: {
        on_source: "ddu.vim",
      },
      neotest: {
        on_source: "neotest",
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
    if (is_debug == true) {
      console.debug(result);
    }
    return result;
  }
}

