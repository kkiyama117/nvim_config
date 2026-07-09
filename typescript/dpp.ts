import {
  BaseConfig,
  ConfigArguments,
  ConfigReturn,
  ContextBuilder,
  Denops,
  Dpp,
  expandGlob,
  fn,
  gatherCheckFiles,
  gatherTomls,
  gatherVimrcs,
  join,
  LazyMakeStateResult,
  MultipleHook,
  Plugin,
  Toml,
  vars,
  VimrcSkipRule
  //PlotocolOptions
} from "./deps.ts";

const dppCacheDir = join(Deno.env.get("XDG_CACHE_HOME"), "dpp");
const dppTomlDir = join(Deno.env.get("XDG_CONFIG_HOME"), "nvim", "dpp");
const luaDir = join(Deno.env.get("NVIM_CONFIG_HOME"), "lua");
const rcDir = join(Deno.env.get("NVIM_CONFIG_HOME"),"lua", "rc");

export class Config extends BaseConfig {
  override async config(args: ConfigArguments): Promise<ConfigReturn> {
    const denops: Denops = args.denops;
    const hasNvim = args.denops.meta.host === "nvim";
    const hasWindows = await fn.has(args.denops, "win32");

    // Inline local
    const nvimHome = Deno.env.get("NVIM_CONFIG_HOME");
    // Test Neovide skip
    const vimrcSkipRules = [
      {
        name: "neovide.lua",
        condition: await vars.globals.get(denops, "neovide") === null,
      },
    ] as VimrcSkipRule[];

    const inlineVimrcs =
      //gatherVimrcs(luaDir,[{ name: 'dpp_loader.lua', condition: true,},
      //          {name: 'plugins',condition: true,},]).concat(
                gatherVimrcs(rcDir,vimrcSkipRules)
      //);

    args.contextBuilder.setGlobal({
      inlineVimrcs: inlineVimrcs,
      protocols: ["git"],
      //protocolOptions: {
      protocolParams: {
        git: {
          enablePartialClone: true,
        },
      },
      extParams: {
        installer: {
          checkDiff: true,
          logFilePath: join(dppCacheDir,
            `installer_${
              new Date().toLocaleDateString("ja-JP", {
                year: "numeric",
                month: "2-digit",
                day: "2-digit",
              }).replaceAll("/", "")
            }.log`,
          ),
          githubAPIToken: Deno.env.get("GITHUB_API_TOKEN"),
        },
      },
    });

    const [context, options] = await args.contextBuilder.get(args.denops);

    // TOML defined remote plugins
    // Merge toml results
    const recordPlugins: Record<string, Plugin> = {};
    const ftplugins: Record<string, string> = {};
    const hooksFiles: string[] = [];
    let multipleHooks: MultipleHook[] = [];
    const noLazyTomls = ["merge.toml","dpp.toml"];

    const eagerTomls = await gatherTomls(
      dppTomlDir,
      noLazyTomls,
      args,
    ) as Toml[];
      // {
      //   path: hasNvim ? "$BASE_DIR/neovim.toml" : "$BASE_DIR/vim.toml",
      //   lazy: true,
      // },
    eagerTomls.filter((toml)=> {
      console.log(toml);
      return (toml != null)}
    ).map((toml) =>{
      if (toml.plugins){
        //for (const plugin of toml.plugins ?? []) {
        //  recordPlugins[plugin.name] = plugin;
        //}
        // Add plugin to record
        toml.plugins.map((plugin) =>{
          recordPlugins[plugin.name] = plugin;
        });
      }
      if (toml.hooks_file){
        hooksFiles.push(toml.hooks_file);
      }
      if (toml.ftplugins) {
        for (const filetype of Object.keys(toml.ftplugins)) {
          if (ftplugins[filetype]) {
            ftplugins[filetype] += `\n${toml.ftplugins[filetype]}`;
          } else {
            ftplugins[filetype] = toml.ftplugins[filetype];
          }
        }
      }
      if (toml.multiple_hooks) {
        multipleHooks = multipleHooks.concat(toml.multiple_hooks);
      }
      if (toml.hooks_file) {
        hooksFiles.push(toml.hooks_file);
      }
    });

    const localPlugins = await args.dpp.extAction(
      args.denops,
      context,
      options,
      "local",
      "local",
      {
        directory: "~/programs/nvim",
        options: {
          frozen: true,
          merged: false,
        },
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
        if (plugin.name in recordPlugins) {
          recordPlugins[plugin.name] = Object.assign(
            recordPlugins[plugin.name],
            plugin,
          );
        } else {
          recordPlugins[plugin.name] = plugin;
        }
      }
    }

    const packSpecPlugins = await args.dpp.extAction(
      args.denops,
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
        if (plugin.name in recordPlugins) {
          recordPlugins[plugin.name] = Object.assign(
            recordPlugins[plugin.name],
            plugin,
          );
        } else {
          recordPlugins[plugin.name] = plugin;
        }
      }
    }

    const lazyResult = await args.dpp.extAction(
      args.denops,
      context,
      options,
      "lazy",
      "makeState",
      {
        plugins: Object.values(recordPlugins),
      },
    ) as LazyMakeStateResult | undefined;

    const checkFilesPromise = gatherCheckFiles(
      denops,
      `${Deno.env.get("NVIM_CONFIG_HOME")}`,
      [
        //"lua/*.lua",
        //"rc/*",
        "**/*.lua",
        "**/*.toml",
        "**/*.ts",
        "**/*.vim",
      ],
    );

    const result = {
      checkFiles: await checkFilesPromise,
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

