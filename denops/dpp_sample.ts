// Sample dpp config. Copy to `dpp.ts` and edit for your environment.
// dpp loads the module named export `Config` (see dpp.vim app.ts: `new mod.Config()`).

import {
  BaseConfig,
  ConfigArguments,
  ConfigReturn,
  ContextBuilder,
  Denops,
  gatherCheckFiles,
  gatherTomls,
  gatherVimrcs,
  join,
  LazyMakeStateResult,
  MultipleHook,
  Plugin,
  Toml,
  vars,
  VimrcSkipRule,
} from "./deps.ts";

const home = Deno.env.get("HOME") ?? "~";
const configHome = Deno.env.get("XDG_CONFIG_HOME") ?? `${home}/.config`;
const nvimHome = Deno.env.get("NVIM_CONFIG_HOME") ?? `${configHome}/nvim`;

// Where plugin definition TOMLs live.
const dppTomlDir = join(configHome, "nvim", "dpp");
// Where inline vimrc fragments live.
const rcDir = join(nvimHome, "lua", "rc");

export class Config extends BaseConfig {
  override async config(args: ConfigArguments): Promise<ConfigReturn> {
    const denops: Denops = args.denops;

    // Inline vimrcs: load everything under rcDir, skipping e.g. neovide.lua
    // when not running inside Neovide.
    const vimrcSkipRules: VimrcSkipRule[] = [
      {
        name: "neovide.lua",
        condition: await vars.globals.get(denops, "neovide") === null,
      },
    ];
    const inlineVimrcs = gatherVimrcs(rcDir, vimrcSkipRules);

    // Global dpp options: which protocols to use + installer params.
    (args.contextBuilder as ContextBuilder).setGlobal({
      inlineVimrcs,
      protocols: ["git"],
      protocolParams: {
        git: { enablePartialClone: true },
      },
      extParams: {
        installer: {
          checkDiff: true,
          githubAPIToken: Deno.env.get("GITHUB_API_TOKEN"),
        },
      },
    });

    const [context, options] = await args.contextBuilder.get(denops);

    // Gather TOML-defined remote plugins and merge.
    const recordPlugins: Record<string, Plugin> = {};
    const ftplugins: Record<string, string> = {};
    const hooksFiles: string[] = [];
    let multipleHooks: MultipleHook[] = [];
    // Tomls in this list are loaded eager (not lazy).
    const noLazyTomls = ["merge.toml", "dpp.toml"];

    const eagerTomls = await gatherTomls(
      dppTomlDir,
      noLazyTomls,
      args,
    ) as Toml[];
    for (const toml of eagerTomls) {
      if (!toml) continue;
      if (toml.plugins) {
        for (const plugin of toml.plugins) recordPlugins[plugin.name] = plugin;
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

    // Local plugins (frozen, not merged) under a local directory.
    const localPlugins = await args.dpp.extAction(
      denops,
      context,
      options,
      "local",
      "local",
      {
        directory: join(home, "programs", "nvim"),
        options: { frozen: true, merged: false },
        includes: [
          "vim*",
          "nvim-*",
          "*.vim",
          "*.nvim",
          "ddc-*",
          "ddu-*",
          "dpp-*",
          "skkeleton",
        ],
      },
    ) as Plugin[] | undefined;
    if (localPlugins) {
      for (const plugin of localPlugins) {
        recordPlugins[plugin.name] = (plugin.name in recordPlugins)
          ? Object.assign(recordPlugins[plugin.name], plugin)
          : plugin;
      }
    }

    // Augment with packspec metadata (lazy load definitions).
    const packSpecPlugins = await args.dpp.extAction(
      denops,
      context,
      options,
      "packspec",
      "load",
      {
        basePath: args.basePath,
        plugins: Object.values(recordPlugins),
      },
    ) as Plugin[] | undefined;
    if (packSpecPlugins) {
      for (const plugin of packSpecPlugins) {
        recordPlugins[plugin.name] = (plugin.name in recordPlugins)
          ? Object.assign(recordPlugins[plugin.name], plugin)
          : plugin;
      }
    }

    // Build lazy load state.
    const lazyResult = await args.dpp.extAction(
      denops,
      context,
      options,
      "lazy",
      "makeState",
      { plugins: Object.values(recordPlugins) },
    ) as LazyMakeStateResult | undefined;

    const checkFiles = await gatherCheckFiles(denops, nvimHome, [
      "**/*.lua",
      "**/*.toml",
      "**/*.ts",
      "**/*.vim",
    ]);

    const result: ConfigReturn = {
      checkFiles,
      ftplugins,
      hooksFiles,
      multipleHooks,
      plugins: lazyResult?.plugins ?? [],
      stateLines: lazyResult?.stateLines ?? [],
    };
    console.debug(result);
    return result;
  }
}
