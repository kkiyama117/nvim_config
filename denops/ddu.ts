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
    // TODO: Now it has minimal config to test.
    // Add the config like https://github.com/Shougo/shougo-s-github/blob/master/vim/rc/ddu.vim does.
    args.contextBuilder.patchGlobal({
	// OPTIONS
	profile: false,
	converterCache: true,
	matcherConcurrency: 4,
	// ACTIONS
	actionOptions:{},
	actionParams:{},
	// UI
	ui: "ff",
	uiOptions: {
	  //filterInputFunc: "cmdline#input",
	  //filterInputOptFunc: "cmdline#input_opts",
	},
	uiParams: {
	},
	// KINDS 
	kindOptions: {
	  // TODO: this is the `TEST` config
	  file: {
	    defaultAction: "open",
	  },
	},
	kindParams:{},
	// SOURCES
	sourceOptions:{
	  _: {
	    ignoreCase: true,
	    matchers: ["matcher_substring"],
	    smartCase: true,
	  },
	  // Add others ...
	  file_rec: {
	    matchers:[
	      "matcher_substring",
	      //"matcher_hidden",
	    ],
	    //sorters: ["sorter_alpha"],
            //converters: ["converter_hl_dir"],
	  },
	  // Add others ...
	},
	sourceParams: {
	},
	// FILTERS
	filterOptions:{
	  _: {
	    parallelSafe: true,
	  }
	},
	filterParams:{
          matcher_substring: {
            highlightMatched: "PmenuMatch",
          },
	  // TODO: add others
	},
    });
    return Promise.resolve();
  }
}
