# Task: Fix `quint verify` failing to start the JVM

> **STATUS: FIXED (2026-08-10).** Root cause verified and resolved by adding
> `java = "22.0.2"` to the global mise config `[tools]`
> (`~/.config/mise/config.toml`). New shells get Java 22 on PATH via mise
> activate, and `quint verify` runs to completion. See "Verified root cause"
> and "The fix" below.

## Context

`quint` (Informal Systems' specification language) is installed on this machine
via mise (`github:informalsystems/quint`, version **0.32.0**). The `quint run`
subcommand (simulator) works fine. The `quint verify` subcommand (model checker)
fails before doing any work because the JVM it launches rejects a VM option.

This is a **separate issue** from the vim/LSP setup (which is already done and
working). Do not touch the LSP config.

## The bug

Running:

```sh
quint verify bank.qnt --invariant=no_negatives
```

produces:

```
Unrecognized VM option 'G1PeriodicGCInterval=600000'
Error: Could not create the Java Virtual Machine.
Error: A fatal exception has occurred. Program will exit.
```

The JVM never starts, so no verification happens.

## Environment

- `quint` 0.32.0, binary at `~/.local/share/mise/installs/github-informalsystems-quint/latest/quint`
- System `java` = OpenJDK **1.8.0_502** (`/usr/bin/java`)
- mise has these Java versions installed:
  - `temurin-8.0.452+9`
  - `22.0.2`
  - `24-loom+2-24.0.0`
- The error occurs with **both** Java 8 and Java 22 (tested via
  `JAVA_HOME=$(mise where java@22.0.2) quint verify ...`).

## Root-cause hypothesis (verify this)

**VERIFIED, with one correction.** The flag comes from Apalache's own launcher
script, and the JDK range hypothesis (9–16 only) is wrong:

- `~/.quint/apalache-dist-0.56.1/apalache/bin/apalache-mc` line 48 sets
  `JVM_GC_ARGS="-XX:+UseG1GC -XX:G1PeriodicGCInterval=600000 -XX:+G1PeriodicGCInvokesConcurrent"`
  unconditionally whenever the `JVM_GC_ARGS` env var is empty. This is the
  Apalache distribution that quint auto-downloads to `~/.quint/`; quint itself
  does not pass the flag.
- Upstream Apalache `main` still has the flag
  (`src/universal/bin/apalache-mc` line 58), so upgrading Apalache/quint does
  not help.
- `G1PeriodicGCInterval` was introduced in JDK 9. The system `java` is OpenJDK
  **1.8.0_502** (`/usr/bin/java`), which rejects it → JVM never starts.
- **Correction:** Java 22.0.2 **accepts** the flag (verified:
  `java -XX:G1PeriodicGCInterval=600000 -version` works). The doc's earlier
  claim that Java 22 also fails was a test artifact: `apalache-mc` invokes
  `java` from **`PATH`**, not `$JAVA_HOME`, so setting `JAVA_HOME` alone still
  ran Java 8. The real problem is simply that the system `java` is Java 8.

## The fix (applied)

Added to `~/.config/mise/config.toml` `[tools]`:

```toml
java = "22.0.2"
```

`mise activate zsh` then puts Java 22 on PATH (via shims or direct bin path) in
new shells, so `apalache-mc` finds a JDK that accepts the flag. No edits to the
quint binary or the Apalache dist.

Verified end-to-end in a clean shell:

- un-fixed bank spec → `[violation] Found an issue` (finds `no_negatives`)
- guarded spec → `[ok] No violation found`
- `quint run` unaffected

Notes:

- Existing shells keep a stale PATH until their next mise hook re-run (after
  `cd`) or until restarted.
- Alternative one-off workaround (no config change):
  `export PATH="$(mise where java@22.0.2)/bin:$PATH"` before `quint verify`,
  or set `JVM_GC_ARGS="-XX:+UseG1GC"` (non-empty skips the script's default;
  still needs a JDK ≥ 11 — Java 8 cannot run Apalache 0.56.1 anyway, class file
  version 55).
- Spec syntax gotcha found while testing: `balance' >= 0` (primed variable in a
  boolean expression) does not parse in quint 0.32.0 — `'` is only valid in
  assignment form `x' = e`. Also, `nondet x = e1` is let-sugar
  (`let nondet x = e1 in <body>`); a trailing comma after `e1` breaks it. Use
  the pattern from quint's own `coin.qnt`:
  ```quint
  action withdraw = all {
    nondet amount = oneOf(1.to(1000))
    all {
      balance' = balance - amount,
      balance - amount >= 0
    }
  }
  ```

## Where to investigate

- quint source (GitHub: `informalsystems/quint`, branch `main`):
  - `quint/src/verify.ts` — the verify command; imports from `./apalache`
  - `quint/src/apalache.ts` — Apalache server interface; note
    `DEFAULT_APALACHE_VERSION_TAG = '0.56.1'`
  - Search the repo for `G1PeriodicGCInterval` and for how the Apalache JVM is
    launched (JVM args, `JAVA_OPTS`, launcher scripts, `.jvmopts`, etc.)
- The Apalache distribution that quint downloads/fetches (see `fetchApalache` in
  `quint/src/apalache.ts` and `apalacheDistDir` in `quint/src/config.ts`). The
  option may be set by Apalache's own launcher, not by quint.
- Check whether the option is set unconditionally or only for a specific JDK
  range, and whether a newer Apalache version (or a JDK 9–16) avoids it.

## What to try / possible fixes

- Find where `G1PeriodicGCInterval=600000` is set and determine the cleanest fix:
  - a JDK 9–16 runtime (if one can be installed via mise) that accepts the flag, or
  - overriding/removing the flag (e.g. via `JAVA_OPTS`/`JAVA_TOOL_OPTIONS` or a
    config option), or
  - upgrading Apalache / quint to a version that no longer passes the flag.
- Prefer a fix that does not require editing the installed quint binary.

## Definition of done

`quint verify bank.qnt --invariant=no_negatives` runs to completion and returns
a real result (for the un-fixed bank example, it should find the `no_negatives`
violation; for a fixed spec it should return `[ok]`). The JVM must start without
the `Unrecognized VM option` error.

## Notes

- A minimal repro spec (`bank.qnt`) is the standard Quint "Getting Started" bank
  example; recreate it from https://quint.sh/docs/getting-started if needed.
- `quint run` already works — do not regress it.
