#!/usr/bin/env bash
set -euo pipefail
export RVPM_NO_AUTOUPDATE=1
export RVPM_APPNAME=nvim-rvpm
cd /home/kiyama/.config/nvim
exec script -qec 'nvim --headless -u doc/agents/reports/rvpm-p1-init.lua -l doc/agents/reports/rvpm-p1-assert.lua' /dev/null
