# dpp `ConfigReturn` type reference

Reference of the `ConfigReturn` type exposed by dpp.vim (`Shougo/dpp.vim`, `main` branch). Verified against source on 2026-07-11.

Status: reference (stable).

Related: [`denops-dpp.md`](./denops-dpp.md) (upstream reading list), [`dpp-context-builder.md`](./dpp-context-builder.md) (`ContextBuilder` / `setGlobal`), [`dpp-hooks-file.md`](./dpp-hooks-file.md) (`hooks_file` / `hooksFiles` / file format).

## Source location

| Symbol | File | Note |
|--------|------|------|
| `ConfigReturn` | `denops/dpp/base/config.ts` | Type definition |
| `MultipleHook` | `denops/dpp/base/config.ts` | Helper type used by `ConfigReturn.multipleHooks` |
| `ConfigArguments` | `denops/dpp/base/config.ts` | Argument type of `BaseConfig.config()` that returns `ConfigReturn` |
| `BaseConfig` | `denops/dpp/base/config.ts` | Abstract base; `apiVersion = 2`; `config(): ConfigReturn \| Promise<ConfigReturn>` |
| `Plugin` | `denops/dpp/types.ts` | Element type of `ConfigReturn.plugins` |
| `makeState()` | `denops/dpp/dpp.ts` | Consumer: `(denops, options, basePath, configPath, name, configReturn, extraArgs)` |

## Definition

```ts
export type ConfigReturn = {
  checkFiles?: string[];
  ftplugins?: Record<string, string>;
  groups?: Record<string, Partial<Plugin>>;
  hooksFiles?: string[];
  multipleHooks?: MultipleHook[];
  plugins: Plugin[];
  stateLines?: string[];
};
```

```ts
export type MultipleHook = {
  hook_add?: string;
  hook_post_source?: string;
  hook_source?: string;
  plugins: string[];
};
```

## Field reference

| Field | Type | Required | Meaning | Consumed in `makeState()` |
|-------|------|----------|---------|--------------------------|
| `plugins` | `Plugin[]` | **Yes** | Plugins to register. Each element is the `Plugin` type from `types.ts` | Iterated; `detectPlugin()` is run per plugin, then `groups` and `hooks_file` are merged |
| `ftplugins` | `Record<string, string>` | No | filetype → script map | Merged by `mergeFtplugins()` |
| `groups` | `Record<string, Partial<Plugin>>` | No | Group-common settings referenced by `plugin.group` | Resolved against `convert2List(plugin.group)`; unknown group → `printError` and skip; merged as `{...groups[group], ...plugin}` (group first, plugin overrides) |
| `hooksFiles` | `string[]` | No | Global hooks file paths | Parsed by `parseHooksFile()`; **ftplugin sections only** merged into `ftplugins` (see [`dpp-hooks-file.md`](./dpp-hooks-file.md)) |
| `multipleHooks` | `MultipleHook[]` | No | Hooks applied to multiple plugins at once | Defaulted to `[]`; applied to the plugins listed in `MultipleHook.plugins` |
| `checkFiles` | `string[]` | No | File paths whose existence is checked after state generation | Used in the check phase of `makeState()` |
| `stateLines` | `string[]` | No | Lines appended verbatim to the state file | Written into the generated state |

## Role in the dpp pipeline

1. A config plugin subclasses `BaseConfig` and implements `config(args)` returning `ConfigReturn` (sync or `Promise`).
2. `dpp.vim` calls the config via `app.ts` dispatcher → `makeState()` receives the `ConfigReturn`.
3. `makeState()` (in `denops/dpp/dpp.ts`) processes in this order:
   - `multipleHooks` default → `[]`
   - For each `configReturn.plugins[i]`:
     - `detectPlugin()` (mutates the plugin object)
     - If `groups` set and `plugin.group` present: merge each group's `Partial<Plugin>` first, then the plugin's own fields (plugin wins)
     - If `plugin.hooks_file` set: `parseHooksFile(readHooksFile(...))` merged into the plugin
   - Protocols resolved via `getProtocols()`; `extAttrs`/`protocolAttrs` validated
   - `ftplugins`, `hooksFiles`, `checkFiles`, `stateLines`, `multipleHooks` folded into the state
4. Result becomes the dpp state file loaded by the Vim/Neovim side.

## Local entry point

In this repo, the config implementation is `denops/dpp.ts` (see `denops-dpp.md`). A `ConfigReturn`-returning `config()` must at minimum provide `plugins: Plugin[]`. Example shape:

```ts
import type { ConfigArguments, ConfigReturn } from "jsr:@shougo/dpp-vim@^6.6.0/config";

class Config extends BaseConfig {
  config(_args: ConfigArguments): ConfigReturn {
    return {
      plugins: [
        { name: "Shougo/dpp.vim", lazy: false },
        // …
      ],
      ftplugins: { /* filetype → script */ },
      groups: { /* group name → Partial<Plugin> */ },
    };
  }
}
```

## Merge precedence note

For `groups`: `{ ...groups[group], ...plugin }` — the **plugin's own fields override the group defaults**. This is the only precedence rule embedded in `ConfigReturn` consumption; individual `hooks_file` parsing happens after group merge.

## Caveats

- `plugins` is the only required field; all others are optional and defaulted.
- `MultipleHook.plugins` is a list of **plugin names** (`string[]`), not `Plugin` objects.
- `apiVersion = 2` on `BaseConfig` is the contract version; older `apiVersion = 1` configs (pre-`ConfigReturn`) are not compatible.
- `detectPlugin()` mutates the `Plugin` object in place — do not assume `configReturn.plugins` is immutable after `makeState()` runs.