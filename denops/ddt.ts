import { BaseConfig, ConfigArguments } from "@shougo/ddt-vim/config";

import * as fn from "@denops/std/function";

import { nvimConfigHome, nvimLuaHome, xdgCacheHome } from "./consts.ts";
import {stdq} from

export class Config extends BaseConfig {
  override async config(args: ConfigArguments): Promise<void> {
    const hasWindows = await fn.has(args.denops, "win32");

    args.contextBuilder.patchGlobal({
      debug: false,
      nvimServer: "$NVIM_CACHE_HOME/server.pipe",
    });
  }
}

