#!/usr/bin/env python3
"""Convert deps/*.toml (dpp) to rvpm/config.toml. Re-runnable and deterministic."""

from __future__ import annotations

import json
import re
import sys
import tomllib
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEPS_DIR = ROOT / "deps"
OUT = ROOT / "rvpm" / "config.toml"
OPTIONS_HEADER = OUT.read_text().split("[[plugins]]")[0].rstrip() + "\n\n" if OUT.exists() else ""

DROP_REPOS = {
    "Shougo/dpp.vim",
    "Shougo/dpp-ext-lazy",
    "Shougo/dpp-ext-toml",
    "Shougo/dpp-ext-local",
    "Shougo/dpp-ext-installer",
    "Shougo/dpp-ext-packspec",
    "Shougo/dpp-protocol-git",
    "Shougo/dpp-protocol-http",
}

# dpp field -> dropped at emit time (still counted in mapping report)
DROP_FIELDS = {"group", "denops_wait", "rtp", "description", "extAttrs", "hook_add"}

# inline hooks -> P4, not config.toml
INLINE_HOOK_FIELDS = {"hook_source", "lua_source", "lua_add", "ftplugin"}

RVPM_KEY_ORDER = (
    "url",
    "name",
    "depends",
    "lazy",
    "cond",
    "on_cmd",
    "on_event",
    "on_ft",
    "on_map",
    "on_source",
    "dev",
    "dst",
    "rev",
    "merge",
    "merge_doc",
)


def is_dpp_stack(repo: str) -> bool:
    return repo in DROP_REPOS


def normalize_hooks_path(path: str) -> str:
    return path.replace("$NVIM_CONFIG_HOME/", "")


def rvpm_hook_dir(url: str) -> str:
    return f"rvpm/plugins/github.com/{url}/"


def fmt_string(s: str) -> str:
    if "\n" in s:
        raise ValueError(f"multiline string unexpected: {s!r}")
    return json.dumps(s, ensure_ascii=False)


def fmt_array(items: list[Any], indent: str = "") -> str:
    if not items:
        return "[]"
    if all(isinstance(x, str) for x in items):
        inner = ", ".join(fmt_string(x) for x in items)
        return f"[{inner}]"
    lines = ["["]
    for item in items:
        if isinstance(item, dict):
            lines.append(f"{indent}  {{ lhs = {fmt_string(item['lhs'])}, mode = {fmt_array(item['mode'])} }},")
        else:
            lines.append(f"{indent}  {fmt_string(item)},")
    lines.append(f"{indent}]")
    return "\n".join(lines)


def convert_on_map(raw: dict[str, Any]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for mode, lhs_val in raw.items():
        lhs_list = [lhs_val] if isinstance(lhs_val, str) else list(lhs_val)
        for lhs in lhs_list:
            out.append({"lhs": lhs, "mode": [mode]})
    return out


DISPLAY_ALIASES = {
    "gin": "vim-gin",
}


def normalize_ref(name: str) -> str:
    return DISPLAY_ALIASES.get(name, name)


def convert_depends(raw: str | list[str]) -> list[str]:
    items = [raw] if isinstance(raw, str) else list(raw)
    return [normalize_ref(x) for x in items]


def convert_listish(raw: str | list[str]) -> list[str]:
    items = [raw] if isinstance(raw, str) else list(raw)
    return [normalize_ref(x) for x in items]


def convert_external_commands(cmds: list[str]) -> str:
    parts = [f"vim.fn.executable({fmt_string(c)}) == 1" for c in cmds]
    return " and ".join(parts)


def convert_if(expr: str) -> str:
    if "MOCWORD_DATA" in expr:
        return "vim.env.MOCWORD_DATA ~= nil"
    if "win32" in expr:
        return "not vim.fn.has('win32')"
    raise ValueError(f"unhandled if expression: {expr!r}")


def convert_on_if(expr: str) -> str:
    if "NVIM" in expr:
        return "vim.env.NVIM ~= nil"
    raise ValueError(f"unhandled on_if expression: {expr!r}")


def merge_cond(existing: str | None, new: str) -> str:
    if not existing:
        return new
    return f"({existing}) and ({new})"


def plugin_to_rvpm(plugin: dict[str, Any], source: str) -> tuple[dict[str, Any], dict[str, Any]]:
    """Return (rvpm_entry, sidecar notes for report)."""
    notes: dict[str, Any] = {
        "source": source,
        "dropped_fields": {},
        "inline_hooks": {},
        "unmapped": {},
    }
    out: dict[str, Any] = {"url": plugin["repo"]}
    cond: str | None = None

    for field, value in plugin.items():
        if field == "repo":
            continue
        if field in DROP_FIELDS:
            notes["dropped_fields"][field] = value
            continue
        if field in INLINE_HOOK_FIELDS:
            notes["inline_hooks"][field] = value
            continue
        if field == "hooks_file":
            notes["hooks_file"] = value
            continue
        if field == "depends":
            out["depends"] = convert_depends(value)
        elif field == "lazy":
            out["lazy"] = value
        elif field == "name":
            out["name"] = value
        elif field == "on_event":
            events = convert_listish(value)
            out["on_event"] = [
                e if e.startswith("User ") or e in ("VimEnter", "UIEnter", "FileType", "BufReadPost", "BufNewFile", "InsertEnter", "CmdlineEnter", "BufRead", "CursorHold")
                else f"User {e}"
                if e == "DenopsReady"
                else e
                for e in events
            ]
        elif field == "on_source":
            out["on_source"] = convert_listish(value)
        elif field == "on_ft":
            out["on_ft"] = convert_listish(value)
        elif field == "on_cmd":
            out["on_cmd"] = convert_listish(value)
        elif field == "on_post_source":
            out["on_source"] = convert_listish(value)
            notes["dropped_fields"]["on_post_source"] = "mapped to on_source"
        elif field == "on_map":
            out["on_map"] = convert_on_map(value)
        elif field == "external_commands":
            cond = merge_cond(cond, convert_external_commands(value))
        elif field == "if":
            cond = merge_cond(cond, convert_if(value))
        elif field == "on_if":
            cond = merge_cond(cond, convert_on_if(value))
        elif field == "on_lua":
            notes["unmapped"]["on_lua"] = value
            out["lazy"] = False
        else:
            notes["unmapped"][field] = value

    if cond:
        out["cond"] = cond

    return out, notes


def emit_plugin(entry: dict[str, Any]) -> str:
    lines = ["[[plugins]]"]
    keys = [k for k in RVPM_KEY_ORDER if k in entry]
    extra = [k for k in entry if k not in RVPM_KEY_ORDER]
    for key in keys + sorted(extra):
        val = entry[key]
        if key == "lazy":
            lines.append(f"lazy = {'true' if val else 'false'}")
        elif key == "depends":
            lines.append(f"depends = {fmt_array(val)}")
        elif key in ("on_event", "on_source", "on_ft", "on_cmd"):
            lines.append(f"{key} = {fmt_array(val)}")
        elif key == "on_map":
            lines.append(f"on_map = {fmt_array(val, indent='')}")
        elif key == "cond":
            lines.append(f'cond = {fmt_string(val)}')
        elif key == "name":
            lines.append(f"name = {fmt_string(val)}")
        elif key == "url":
            lines.append(f"url = {fmt_string(val)}")
        else:
            lines.append(f"{key} = {json.dumps(val, ensure_ascii=False)}")
    return "\n".join(lines)


def load_deps() -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    plugins: list[dict[str, Any]] = []
    file_hooks: list[dict[str, Any]] = []
    multiple_hooks: list[dict[str, Any]] = []
    for path in sorted(DEPS_DIR.glob("*.toml")):
        data = tomllib.loads(path.read_text())
        if "hooks_file" in data and "plugins" in data:
            # file-level hook in no_lazy.toml only
            file_hooks.append({"file": path.name, "hooks_file": data["hooks_file"]})
        for mh in data.get("multiple_hooks", []):
            multiple_hooks.append({"file": path.name, **mh})
        for plugin in data.get("plugins", []):
            plugins.append({"__file": path.name, **plugin})
    return plugins, file_hooks, multiple_hooks


def main() -> int:
    raw_plugins, file_hooks, multiple_hooks = load_deps()
    emitted: list[dict[str, Any]] = []
    dropped: list[dict[str, str]] = []
    all_notes: list[dict[str, Any]] = []
    hooks_handoff: list[dict[str, str]] = []

    for raw in raw_plugins:
        source = raw["__file"]
        plugin = {k: v for k, v in raw.items() if k != "__file"}
        repo = plugin["repo"]
        if is_dpp_stack(repo):
            dropped.append({"repo": repo, "reason": "dpp stack deleted in migration"})
            continue
        entry, notes = plugin_to_rvpm(plugin, source)
        emitted.append(entry)
        all_notes.append({"repo": repo, **notes})
        if "hooks_file" in notes:
            hooks_handoff.append(
                {
                    "url": repo,
                    "dpp_hooks_file": normalize_hooks_path(notes["hooks_file"]),
                    "rvpm_hook_dir": rvpm_hook_dir(repo),
                }
            )

    for fh in file_hooks:
        hooks_handoff.append(
            {
                "url": "(global)",
                "dpp_hooks_file": normalize_hooks_path(fh["hooks_file"]),
                "rvpm_hook_dir": "rvpm/before.lua + rvpm/after.lua (global)",
            }
        )

    for mh in multiple_hooks:
        for plug in mh["plugins"]:
            url = plug if "/" in plug else f"Shougo/{plug}" if plug.endswith(".vim") else plug
            # resolve display names to urls heuristically
            name_map = {
                "ddc.vim": "Shougo/ddc.vim",
                "skkeleton": "vim-skk/skkeleton",
                "ddu.vim": "Shougo/ddu.vim",
                "vim-gin": "lambdalisue/vim-gin",
            }
            url = name_map.get(plug, url)
            hooks_handoff.append(
                {
                    "url": url,
                    "dpp_hooks_file": normalize_hooks_path(mh["hooks_file"]),
                    "rvpm_hook_dir": rvpm_hook_dir(url) + " (+ require lua/hooks/shared/*.lua)",
                }
            )

    body = "\n\n".join(emit_plugin(e) for e in emitted) + "\n"
    header = OPTIONS_HEADER if OPTIONS_HEADER.strip() else (
        "# rvpm options — plugins added in P3\n"
        "# config_root stays unset (§2.3: cannot relocate config.toml itself)\n\n"
        "[options]\n"
        'auto_update = "notify"\n'
        'cooldown = "1d"\n'
        "concurrency = 16\n"
        "auto_clean = false\n\n"
    )
    OUT.write_text(header + body)

    report = {
        "input_plugins": len(raw_plugins),
        "emitted": len(emitted),
        "dropped": dropped,
        "hooks_handoff": hooks_handoff,
        "notes": all_notes,
        "file_hooks": file_hooks,
        "multiple_hooks": multiple_hooks,
    }
    json.dump(report, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
