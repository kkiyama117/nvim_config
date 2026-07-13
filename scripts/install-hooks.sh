#!/usr/bin/env sh
set -e
cd "$(git rev-parse --show-toplevel)"

target="../../scripts/hooks/pre-commit"
hook=".git/hooks/pre-commit"

mkdir -p .git/hooks
ln -sf "$target" "$hook"
chmod +x scripts/hooks/pre-commit
echo "Installed .git/hooks/pre-commit -> scripts/hooks/pre-commit"
