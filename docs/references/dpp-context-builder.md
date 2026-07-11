# dpp `ContextBuilder` / `setGlobal` reference

Reference of the `ContextBuilder` interface and its `setGlobal` / `patchGlobal` / `get` methods exposed by dpp.vim (`Shougo/dpp.vim`, `main` branch). Verified against source on 2026-07-11.

Status: reference (stable).

Related: [`dpp-config-return.md`](./dpp-config-return.md) (`ConfigReturn`), [`denops-dpp.md`](./denops-dpp.md) (upstream reading list).

## Source location

| Symbol | File | Note |
|--------|------|------|
| `ContextBuilder` (interface) | `denops/dpp/types.ts` | Public contract |
| `Context` | `denops/dpp/types.ts` | Currently a placeholder (`{}`) |
| `DppOptions` | `denops/dpp/types.ts` | The options object the builder produces |
| `ContextBuilderImpl` (class) | `denops/dpp/context.ts` | Concrete implementation |
| `Custom` (class, private) | `denops/dpp/context.ts` | Holds the global override layer |
| `defaultDppOptions` / `mergeDppOptions` / `patchDppOptions` | `denops/dpp/context.ts` | Merge primitives |
| `ConfigArguments.contextBuilder` | `denops/dpp/base/config.ts` | Where a config plugin receives the builder |
| Built & injected | `denops/dpp/app.ts` (`main`) | `new ContextBuilderImpl()`, passed to `Config()` |

## Interface (`denops/dpp/types.ts`)

```ts
export interface ContextBuilder {
  get(denops: Denops): Promise<[Context, DppOptions]>;
  getGlobal(): Partial<DppOptions>;
  setGlobal(options: Partial<DppOptions>): void;
  patchGlobal(options: Partial<DppOptions>): void;
}
```

## Implementation (`denops/dpp/context.ts`)

```ts
class Custom {
  global: Partial<DppOptions> = {};

  get(): DppOptions {
    return foldMerge(mergeDppOptions, defaultDppOptions, [this.global]);
  }
  setGlobal(options: Partial<DppOptions>): Custom {
    this.global = options;                              // replace, not merge
    return this;
  }
  patchGlobal(options: Partial<DppOptions>): Custom {
    this.global = patchDppOptions(this.global, options); // merge
    return this;
  }
}

export class ContextBuilderImpl implements ContextBuilder {
  #custom: Custom = new Custom();

  async get(denops: Denops): Promise<[Context, DppOptions]> {
    const userOptions = this.#custom.get();
    await this.#validate(denops, "options", userOptions, defaultDppOptions());
    return [{ ...defaultContext() }, userOptions];
  }

  getGlobal(): Partial<DppOptions> { return this.#custom.global; }
  setGlobal(options: Partial<DppOptions>) { this.#custom.setGlobal(options); }
  patchGlobal(options: Partial<DppOptions>) { this.#custom.patchGlobal(options); }
}
```

## Method reference

| Method | Signature | Behavior |
|--------|-----------|----------|
| `setGlobal(options)` | `(Partial<DppOptions>) => void` | **Replaces** the internal global override layer (`this.global = options`). Not a merge. |
| `patchGlobal(options)` | `(Partial<DppOptions>) => void` | **Merges** `options` into the current global layer via `patchDppOptions`. Use this to add fields incrementally. |
| `getGlobal()` | `() => Partial<DppOptions>` | Returns the current global override layer as-is (no defaults applied). |
| `get(denops)` | `(Denops) => Promise<[Context, DppOptions]>` | Materializes `DppOptions` by `foldMerge(mergeDppOptions, defaultDppOptions, [this.global])`; validates keys; returns `[Context, DppOptions]`. |

### Return-type caveat

- `Custom.setGlobal` returns `Custom` (builder-style chaining) **internally**, but the public `ContextBuilder.setGlobal` interface declares `void`. Callers of `args.contextBuilder.setGlobal(...)` cannot chain.
- `patchGlobal` has the same void-interface contract.

## `DppOptions` shape

```ts
export type DppOptions = {
  extOptions: Record<ExtName, Partial<ExtOptions>>;
  extParams: Record<ExtName, Partial<BaseParams>>;
  hooksFileMarker: string;
  inlineVimrcs: string[];
  protocolOptions: Record<ProtocolName, Partial<ExtOptions>>;
  protocolParams: Record<ProtocolName, Partial<BaseParams>>;
  protocols: ProtocolName[];
  skipMergeFilenamePattern: string;
};
```

Defaults (`defaultDppOptions()`):

| Field | Default |
|-------|---------|
| `extOptions` | `{}` |
| `extParams` | `{}` |
| `hooksFileMarker` | `"{{{,}}}"` |
| `inlineVimrcs` | `[]` |
| `protocolOptions` | `{}` |
| `protocolParams` | `{}` |
| `protocols` | `[]` |
| `skipMergeFilenamePattern` | `"^tags(?:-\\w\\w)?$|^package.json$"` |

## Merge semantics

### Top-level vs per-key

`mergeDppOptions(a, b)` and `patchDppOptions(a, b)`:

- Top-level fields: shallow overwrite (`{...a, ...b}`, `b` wins).
- Nested maps (`extOptions`, `extParams`, `protocolOptions`, `protocolParams`): **per-key merge** via `migrateEachKeys` with `partialOverwrite`. Keys present in `b` are merged into the same-named key in `a`; keys only in `a` are preserved.

Result: setting `setGlobal({ extParams: { installer: {...} } })` does **not** wipe other extensions' `extParams` — only the `installer` key is overwritten.

### `setGlobal` vs `patchGlobal`

| Action | `this.global` after |
|--------|---------------------|
| `setGlobal({ a: 1 })` then `setGlobal({ b: 2 })` | `{ b: 2 }` (replace) |
| `setGlobal({ a: 1 })` then `patchGlobal({ b: 2 })` | `{ a: 1, b: 2 }` (merge) |
| `patchGlobal({ extParams: { x: {...} } })` then `patchGlobal({ extParams: { y: {...} } })` | `{ extParams: { x: {...}, y: {...} } }` (per-key) |

## Lifecycle within `makeState` (`denops/dpp/app.ts`)

1. `main` creates `const contextBuilder = new ContextBuilderImpl();` once per denops server.
2. `makeState(basePath, configPath, name, extraArgs)` dispatcher:
   1. `importPlugin(configPath)` → `new mod.Config()`.
   2. `obj.config({ contextBuilder, denops, dpp, basePath, name, extraArgs })` → returns `ConfigReturn`.
      - Inside `config()`, the config plugin calls `contextBuilder.setGlobal(...)` (or `patchGlobal`) and then `contextBuilder.get(denops)` to materialize options.
   3. `const [_, options] = await contextBuilder.get(denops);` is called again after `config()` returns.
   4. `dpp.makeState(denops, options, basePath, configPath, name, configReturn, extraArgs)`.
3. `extAction` dispatcher: `contextBuilder.setGlobal(currentOptions)` is called with `g:dpp.state.options` to re-inject the current runtime options before computing `options`.

## Validation

`ContextBuilderImpl.get()` calls `#validate(denops, "options", userOptions, defaultDppOptions())`:

- For every key in the merged `userOptions` not present in `defaultDppOptions()`, it calls `printError(denops, "Invalid options: \"<key>\"")`.
- Validation is **report-only** — it does not strip the unknown key. Unknown keys flow into `DppOptions` and may be ignored by downstream consumers.

## In this repo

| File | Use |
|------|-----|
| `denops/dpp.ts` | Type-only reference to `ContextBuilder` (in `ConfigArguments`) |
| `denops/dpp_sample.ts` | Calls `args.contextBuilder.setGlobal({ inlineVimrcs, protocols, protocolParams, extParams })` then `args.contextBuilder.get(denops)` |
| `denops/helper.ts` | Calls `args.contextBuilder.get(args.denops)` to fetch `[context, options]` for ext actions |

Local usage snippet (`denops/dpp_sample.ts`):

```ts
(args.contextBuilder as ContextBuilder).setGlobal({
  inlineVimrcs,
  protocols: ["git"],
  protocolParams: { git: { enablePartialClone: true } },
  extParams: {
    installer: {
      checkDiff: true,
      githubAPIToken: Deno.env.get("GITHUB_API_TOKEN"),
    },
  },
});

const [context, options] = await args.contextBuilder.get(denops);
```

The `as ContextBuilder` cast is redundant — `ConfigArguments.contextBuilder` is already typed `ContextBuilder`.

## Caveats / gotchas

- **`setGlobal` replaces, `patchGlobal` merges.** Two `setGlobal` calls in a row drop the first call's content. Use `patchGlobal` for incremental additions.
- **`get()` is required to materialize.** `setGlobal` only updates the override layer; the final `DppOptions` is produced by `get(denops)`. `app.ts` calls `get()` again after `config()` returns, so options set inside `config()` are honored.
- **`Context` is a placeholder.** `defaultContext()` returns `{}`; the first tuple element of `get()` currently carries no meaningful data. All real state lives in `DppOptions`.
- **Per-key merge applies only to the four nested maps.** All other top-level fields (`inlineVimrcs`, `protocols`, `hooksFileMarker`, `skipMergeFilenamePattern`) are replaced wholesale on `setGlobal`/`patchGlobal` at the top level.
- **Builder instance is per denops server.** `ContextBuilderImpl` is constructed once in `main` and shared across dispatcher calls; `setGlobal` mutates shared state. Concurrent dispatchers (`extAction`, `makeState`) share the same `this.global`. Use `patchGlobal` if ordering across dispatchers matters.
- **No chaining on the public interface.** `ContextBuilder.setGlobal` returns `void`; only the internal `Custom` returns itself for chaining.