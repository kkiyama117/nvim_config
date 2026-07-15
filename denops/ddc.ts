import { BaseConfig, ConfigArguments } from "@shougo/ddc-vim/config";
import type { Context, DdcItem } from "@shougo/ddc-vim/types";

import type { Denops } from "@denops/std";
import * as fn from "@denops/std/function";

export class Config extends BaseConfig {
  override async config(args: ConfigArguments): Promise<void> {
    const hasNvim = args.denops.meta.host === "nvim";
    const hasWindows = await fn.has(args.denops, "win32");
    
    const mocWord = Deno.env.get("MOCWORD_DATA") ? ["mocword"] : [];
    
    // DDC Sources that always loaded
    const commonSources = [
      "around",    //[A]
      "file",      //[F]
      "register",  //[R]
    ];
    args.contextBuilder.patchGlobal({
      matcherConcurrency: 4,
      // UI
      ui: "pum",
      dynamicUi: async (denops: Denops, args: Record<string, unknown>) => {
        const uiArgs = args as {
          items: DdcItem[];
        };
        const mode = await fn.mode(denops);
        return Promise.resolve(
          mode !== "t" && uiArgs.items.length == 1 ? "inline" : "pum",);
      },
      // Sources
      dynamicSources: async (denops: Denops, args: Record<string, unknown>) => {
	const sourceArgs = args as {
          context: Context;
          sources: string[];
        };
        const mode = await fn.mode(denops);
        return Promise.resolve(
          mode === "c" && await fn.getcmdtype(denops) === ":"
            ? ["shell_native", ...sourceArgs.sources]
            : null,
        );
      },
      sources: commonSources,
      cmdlineSources: {
	 ":": [
          "cmdline",
          "cmdline_history",
          "around",
          "register",
        ],
        "@": [
          "input",
          "cmdline_history",
          "file",
          "around",
        ],
        ">": [
          "input",
          "cmdline_history",
          "file",
          "around",
        ],
        "/": [
          "around",
          "line",
        ],
        "?": [
          "around",
          "line",
        ],
        "-": [
          "around",
          "line",
        ],
        "=": [
          "input",
        ],
      },
      autoCompleteEvents: [
        "CmdlineEnter",
        "CmdlineChanged",
        "InsertEnter",
        "TextChangedI",
        "TextChangedP",
        "TextChangedT",
      ],
      // SourcesOptions
      sourceOptions: {
	// default options
	_: {
          ignoreCase: true,
          matchers: [
            "matcher_head",
            "matcher_prefix",
            "matcher_length",
          ],
          sorters: [
            "sorter_rank",
          ],
          converters: [
            "converter_remove_overlap",
          ],
          timeout: 1000,
        },
        around: {
          mark: "[A]",
        },
	//buffer:{},
	cmdline: {
          isVolatile: true,
          mark: "[CMD]",
          matchers: [
            "matcher_length",
          ],
          sorters: [
            "sorter_cmdline_history",
          ],
          forceCompletionPattern: String.raw`\S/\S*|\.\w*`,
        },
        cmdline_history: {
          mark: "[CMD_HIST]",
          sorters: [],
        },
        file: {
          mark: "[F]",
          isVolatile: true,
          volatilePattern: "/",
          minAutoCompleteLength: 500,
          forceCompletionPattern: String.raw`\S/\S*`,
        },
	input: {
          mark: "[I]",
          forceCompletionPattern: String.raw`\S/\S*`,
          isVolatile: true,
          sorters: [
            "sorter_cmdline_history",
          ],
        },
        line: {
          mark: "[LINE]",
        },
	lsp: {
          mark: "[LSP]",
          forceCompletionPattern: String.raw`\.\w*|::\w*|->\w*`,
          dup: "force",
        },
	mocword: {
          mark: "[moc]",
          minAutoCompleteLength: 4,
          isVolatile: true,
        },
	register: {
	  mark: "[R]"
	},
	// shell: {
          //   mark: "[SHELL]",
          //   isVolatile: true,
          //   forceCompletionPattern: String.raw`\S/\S*`,
          //   minAutoCompleteLength: 3,
          //   sorters: ["sorter_shell_history"],
          // },
        shell_history: {
          mark: "[HIST]",
          sorters: [],
        },
        shell_native: {
          mark: "[SHELL]",
          forceCompletionPattern: String.raw`\S/\S*`,
          minAutoCompleteLength: 3,
          sorters: ["sorter_shell_history"],
          isVolatile: true,
        },
      },
      sourceParams:{
	 file: {
          filenameChars: "[:keyword:].",
        },
        lsp: {
          enableAdditionalTextEdit: true,
          enableDisplayDetail: true,
          enableMatchLabel: true,
          enableResolveItem: true,
        },
        register: {
          registers: '0123456789"#:',
          extractWords: true,
        },
        shell_history: {
          paths: [
            "~/.cache/ddt-shell-history",
            "~/.zsh-history",
          ],
        },
        shell_native: {
          shell: "zsh",
        },
      },
      // FILTER
      filterOptions: {
	_: {
          parallelSafe: true,
        },
      },
      filterParams: {
        sorter_shell_history: {
          paths: [
            "~/.cache/ddt-shell-history",
            "~/.zsh-history",
          ],
        },
      },
      postFilters: [
        "sorter_head",
      ],
    });

    // Text files
    for (
      const filetype of [
        "markdown",
        "markdown_inline",
        "gitcommit",
        "comment",
      ]
    ) {
      args.contextBuilder.patchFiletype(filetype, {
        sources: [...commonSources, "line", ...mocWord],
      });
    }
    
    // Shell sources
    const shellSourceOptions = {
      specialBufferCompletion: true,
      sourceOptions: {
        _: {
          keywordPattern: "[0-9a-zA-Z_./#:-]*",
        },
      },
      sources: [
        hasWindows ? "shell" : "shell_native",
        "shell_history",
        "around",
      ],
    };
    for (
      const filetype of [
        "zsh",
        "sh",
        "bash",
        "ddt-shell",
        "ddt-terminal",
      ]
    ) {
      args.contextBuilder.patchFiletype(filetype, shellSourceOptions);
    }
     // Use "#" as TypeScript keywordPattern
    for (const filetype of ["typescript"]) {
      args.contextBuilder.patchFiletype(filetype, {
        sourceOptions: {
          _: {
            keywordPattern: "#?[a-zA-Z_][0-9a-zA-Z_]*",
          },
        },
      });
    }

    if (hasNvim) {
      for (
        const filetype of [
          //"css",
          "go",
          //"graphql",
          //"html",
          "lua",
          "python",
          "rust",
          "tsx",
          "typescript",
          "typescriptreact",
        ]
      ) {
        args.contextBuilder.patchFiletype(filetype, {
          sources: ["lsp", ...commonSources],
        });
      }
    }

    args.contextBuilder.patchFiletype("vim", {
      // Enable specialBufferCompletion for cmdwin.
      specialBufferCompletion: true,
      sources: ["vim", "cmdline", ...commonSources],
    });
  }
}

