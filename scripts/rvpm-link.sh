#!/usr/bin/env sh
# Link ~/.config/rvpm/<appname> -> <repo>/rvpm/
# Idempotent; refuses to clobber a real directory or foreign symlink.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
rvpm_src=$repo_root/rvpm

appname=${RVPM_APPNAME:-${NVIM_APPNAME:-nvim}}
target=$HOME/.config/rvpm/$appname

if [ ! -d "$rvpm_src" ]; then
  printf 'REFUSE: repo rvpm dir missing: %s\n' "$rvpm_src" >&2
  exit 1
fi

mkdir -p "$HOME/.config/rvpm"

if [ -L "$target" ]; then
  current=$(readlink "$target")
  if [ "$current" = "$rvpm_src" ]; then
    printf 'OK: %s -> %s (already linked)\n' "$target" "$rvpm_src"
    exit 0
  fi
  printf 'REFUSE: %s is a symlink to %s\n' "$target" "$current" >&2
  printf 'Expected: %s\n' "$rvpm_src" >&2
  printf 'Remove the symlink manually, then re-run.\n' >&2
  exit 1
fi

if [ -d "$target" ]; then
  printf 'REFUSE: %s is a real directory (not a symlink).\n' "$target" >&2
  if [ "$appname" = "nvim" ] && [ -f "$target/config.toml" ]; then
    bytes=$(wc -c < "$target/config.toml" | tr -d ' ')
    if [ "$bytes" -le 128 ]; then
      printf 'Looks like the rvpm init stub (%s bytes). Remove it:\n' "$bytes" >&2
      printf '  rm -rf %s\n' "$target" >&2
      exit 1
    fi
  fi
  printf 'Back up or remove the directory, then re-run.\n' >&2
  exit 1
fi

if [ -e "$target" ]; then
  printf 'REFUSE: %s exists and is not a directory or symlink.\n' "$target" >&2
  exit 1
fi

ln -s "$rvpm_src" "$target"
printf 'OK: created %s -> %s\n' "$target" "$rvpm_src"
exit 0
