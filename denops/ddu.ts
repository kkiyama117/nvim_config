import {
  type ActionArguments,
  ActionFlags,
  type DduOptions,
} from "@shougo/ddu-vim/types";
import { BaseConfig, type ConfigArguments } from "@shougo/ddu-vim/config";
import type { ActionData as FileAction } from "@shougo/ddu-kind-file";
import type { Params as FfParams } from "@shougo/ddu-ui-ff";
import type { Params as FilerParams } from "@shougo/ddu-ui-filer";

import type { Denops } from "@denops/std";
import * as fn from "@denops/std/function";

type Params = Record<string, unknown>;

type DppAction = {
  path: string;
  __name: string;
};

export class Config extends BaseConfig {
  override config(args: ConfigArguments): Promise<void> {
    // TODO: Check what `setAlias` does
    args.setAlias("_", "source", "file_rg", "file_external");
    args.setAlias("_", "source", "file_git", "file_external");
    args.setAlias(
      "_",
      "filter",
      "matcher_ignore_current_buffer",
      "matcher_ignores",
    );
    args.setAlias("_", "action", "tabopen", "open");

    // Global config of the ddu.vim
    args.contextBuilder.patchGlobal({
      // OPTIONS
      profile: false,
      converterCache: true,
      matcherConcurrency: 4,
      // ACTIONS
      actionOptions: {
        copy: {
          quit: false,
        },
        delete: {
          quit: false,
        },
        link: {
          quit: false,
        },
        move: {
          quit: false,
        },
        narrow: {
          quit: false,
        },
        newDirectory: {
          quit: false,
        },
        newFile: {
          quit: false,
        },
        paste: {
          quit: false,
        },
        rename: {
          quit: false,
        },
        tabopen: {
          quit: false,
        },
        trash: {
          quit: false,
        },
        undo: {
          quit: false,
        },
      },
      actionParams: {
        tabopen: {
          command: "tabedit",
        },
      },
      // UI
      ui: "ff",
      uiOptions: {
        _: {
          // Use `cmdline.vim` for filter input
          filterInputFunc: "cmdline#input",
          filterInputOptsFunc: "cmdline#input_opts",
        },
        ff: {
          actions: {
            kensaku: async (args: {
              denops: Denops;
              options: DduOptions;
            }) => {
              await args.denops.dispatcher.updateOptions(
                args.options.name,
                {
                  sourceOptions: {
                    _: {
                      matchers: ["matcher_kensaku"],
                    },
                  },
                },
              );
              await args.denops.cmd("echomsg 'change to kensaku matcher'");

              return ActionFlags.Persist;
            },
          },
        },
        filer: {
          toggle: true,
        },
      },
      uiParams: {
        ff: {
          autoAction: {
            name: "preview",
          },
          displayTree: false,
          //floatingBorder: "none",
          floatingBorder: "single",
          floatingBlend: 50,
          filterSplitDirection: "floating",
          highlights: {
            filterText: "Statement",
            floating: "Normal",
            floatingBorder: "Special",
          },
          maxHighlightItems: 50,
          onPreview: async (args: {
            denops: Denops;
            previewWinId: number;
          }) => {
            await fn.win_execute(args.denops, args.previewWinId, "normal! zt");
          },
          previewFloating: true,
          previewFloatingBorder: "rounded",
          previewFloatingTitle: "Preview",
          previewSplit: "horizontal",
          //split: "floating",
          updateTime: 0,
          winWidth: 100,
        } as Partial<FfParams>,
        filer: {
          autoAction: {
            name: "preview",
          },
          floatingBlend: 80,
          previewCol: "&columns / 5 + 1",
          previewFloating: true,
          sort: "natural",
          sortTreesFirst: true,
          split: "no",
          //startAutoAction: true,
          toggle: true,
        } as Partial<FilerParams>,
      },
      // KINDS
      kindOptions: {
        action: { defaultAction: "do" },
        ddt_tab: { defaultAction: "switch" },
        ddx: { defaultAction: "open" },
        file: {
          defaultAction: "open",
          actions: {
            grep: {
              description: "Grep from the path.",
              callback: async (args: ActionArguments<Params>) => {
                const action = args.items[0]?.action as FileAction;

                await args.denops.call("ddu#start", {
                  name: args.options.name,
                  push: true,
                  sources: [
                    {
                      name: "rg",
                      params: {
                        path: action.path,
                        input: await fn.input(args.denops, "Pattern: "),
                      },
                    },
                  ],
                });

                return Promise.resolve(ActionFlags.None);
              },
            },
          },
        },
        help: { defaultAction: "open" },
        // TODO: setup `viewer`
        readme_viewer: { defaultAction: "open" },
        source: { defaultAction: "execute" },
        // TODO: setup `xdg-open` alternative for container
        url: { defaultAction: "browse" },
        word: { defaultAction: "append" },
      },
      kindParams: {
        // TODO: find`trash` cli command
      },
      // SOURCES
      sourceOptions: {
        _: {
          ignoreCase: true,
          matchers: ["matcher_substring"],
          smartCase: true,
        },
        command_args: {
          defaultAction: "execute",
        },
        dpp: {
          // TODO: use `zoxide` instead of `cd`
          defaultAction: "cd",
          actions: {
            update: {
              description: "Update the plugins",
              callback: async (args: ActionArguments<Params>) => {
                const names = args.items.map((item) =>
                  (item.action as DppAction).__name
                );
                await args.denops.call(
                  "dpp#async_ext_action",
                  "installer",
                  "update",
                  { names },
                );
                return Promise.resolve(ActionFlags.None);
              },
            },
          },
        },
        file: {
          matchers: [
            "matcher_substring",
            "matcher_hidden",
          ],
          sorters: ["sorter_alpha"],
          converters: ["converter_hl_dir", "converter_devicon"],
        },
        file_git: {
          matchers: [
            "matcher_substring",
            "matcher_hidden",
          ],
          sorters: ["sorter_alpha"],
          converters: ["converter_hl_dir", "converter_devicon"],
        },
        file_old: {
          matchers: [
            "matcher_relative",
            "matcher_substring",
          ],
          converters: ["converter_hl_dir"],
        },
        file_rec: {
          matchers: [
            "matcher_substring",
            "matcher_hidden",
          ],
          sorters: ["sorter_mtime"],
          converters: ["converter_hl_dir", "converter_devicon"],
        },
        input_history: {
          defaultAction: "input",
        },
        markdown: { sorters: [] },
        path_history: {
          defaultAction: "uiCd",
        },
        rg: {
          matchers: [
            "matcher_substring",
            "matcher_files",
          ],
        },
      },
      sourceParams: {
        file_git: {
          cmd: ["git", "ls-files", "-co", "--exclude-standard"],
        },
        file_rg: {
          cmd: [
            "rg",
            "--files",
            "--glob",
            "!.git",
            "--color",
            "never",
            "--no-messages",
          ],
          updateItems: 50000,
        },
        rg: {
          args: [
            "--smart-case",
            "--json",
          ],
          category: true,
          highlights: {
            path: "Directory",
            lineNr: "LineNr",
            word: "Search",
          },
        },
      },
      // FILTERS
      filterOptions: {
        _: {
          parallelSafe: true,
        },
      },
      filterParams: {
        matcher_substring: {
          highlightMatched: "PmenuMatch",
        },
        matcher_ignore_files: {
          ignoreGlobs: ["test_*.vim"],
          ignorePatterns: [],
        },
        converter_hl_dir: {
          hlGroup: ["Directory", "Keyword"],
        },
      },
    });
    return Promise.resolve();
  }
}

