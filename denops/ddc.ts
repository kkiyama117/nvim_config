import { BaseConfig, ConfigArguments } from "@shougo/ddc-vim/config";
import type { Context, DdcItem } from "@shougo/ddc-vim/types";

import type { Denops } from "@denops/std";
import * as fn from "@denops/std/function";

export class Config extends BaseConfig {
  override async config(args: ConfigArguments): Promise<void> {
  }
}
