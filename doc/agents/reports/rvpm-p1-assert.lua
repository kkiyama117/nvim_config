-- P1 gate: lazy denops registration under rvpm (copy-pasteable re-run)
-- Usage:
--   RVPM_NO_AUTOUPDATE=1 RVPM_APPNAME=nvim-rvpm nvim --headless -u doc/agents/reports/rvpm-p1-init.lua -l doc/agents/reports/rvpm-p1-assert.lua
-- Or: doc/agents/reports/rvpm-p1-run.sh

local function say(msg)
  io.write(msg .. "\n")
end

local function fail(msg)
  say("FAIL: " .. msg)
  os.exit(1)
end

local function ok(msg)
  say("OK: " .. msg)
end

local function rvpm_key(plugin)
  return "rvpm_loaded_" .. plugin
end

local function wait_until(ms, pred)
  vim.wait(ms, pred, 50)
end

vim.loader.enable()
if vim.fn.executable("deno") == 0 then
  local mise_deno = vim.fs.joinpath(vim.env.HOME, ".local/share/mise/installs/deno/latest/bin/deno")
  if vim.fn.executable(mise_deno) == 1 then
    vim.g["denops#deno"] = mise_deno
  end
end
local loader = vim.fn.expand("~/.cache/rvpm/nvim-rvpm/plugins/loader.lua")
if vim.fn.filereadable(loader) == 0 then
  fail("loader.lua missing: " .. loader)
end
dofile(loader)

local function wait_denops_ready(timeout_ms)
  timeout_ms = timeout_ms or 30000
  local ready = false
  vim.api.nvim_create_autocmd("User", {
    pattern = "DenopsReady",
    once = true,
    callback = function()
      ready = true
    end,
  })
  wait_until(timeout_ms, function()
    if vim.fn["denops#server#status"]() == "running" then
      ready = true
    end
    return ready
  end)
  return ready and vim.fn["denops#server#status"]() == "running"
end

if not wait_denops_ready() then
  fail("denops not ready (status=" .. vim.fn["denops#server#status"]() .. ")")
end
ok("denops running + DenopsReady passed")

local summary = {}

local function check_pre(plugin, denops_name)
  local pre_rvpm = _G[rvpm_key(plugin)]
  local pre_loaded = vim.fn["denops#plugin#is_loaded"](denops_name)
  if pre_rvpm ~= nil then
    fail(plugin .. " pre: rvpm_loaded already set")
  end
  if pre_loaded ~= 0 then
    fail(plugin .. " pre: is_loaded=" .. pre_loaded .. " (expected 0)")
  end
  ok(plugin .. " pre-checks pass")
  return pre_rvpm, pre_loaded
end

local function check_post(plugin, denops_name, trigger, pre_rvpm, pre_loaded)
  local post_rvpm = _G[rvpm_key(plugin)]
  local post_loaded = vim.fn["denops#plugin#is_loaded"](denops_name)
  local pass = post_rvpm == true and post_loaded == 1
  summary[#summary + 1] = {
    plugin = plugin,
    trigger = trigger,
    pre_rvpm = "nil",
    pre_is = pre_loaded,
    post_rvpm = tostring(post_rvpm),
    post_is = post_loaded,
    verdict = pass and "PASS" or "FAIL",
  }
  if pass then
    ok(plugin .. " post-checks pass (rvpm_loaded=true, is_loaded=1)")
  else
    say("FAIL post " .. plugin .. ": rvpm_loaded=" .. tostring(post_rvpm) .. " is_loaded=" .. post_loaded)
  end
  return pass
end

local function fire_skkeleton()
  vim.cmd("enew")
  local m = vim.fn.maparg("<C-j>", "n", false, true)
  if not m.callback then
    fail("skkeleton on_map <C-j> not registered")
  end
  m.callback()
end

local function fire_ddu()
  pcall(vim.cmd, "Ddu")
end

local function fire_ddc()
  vim.cmd("enew")
  vim.api.nvim_exec_autocmds("InsertEnter", { modeline = false })
end

-- skkeleton
local sk_pre_rvpm, sk_pre_loaded = check_pre("skkeleton", "skkeleton")
fire_skkeleton()
wait_until(15000, function()
  return _G[rvpm_key("skkeleton")] == true and vim.fn["denops#plugin#is_loaded"]("skkeleton") == 1
end)
check_post("skkeleton", "skkeleton", "<C-j>", sk_pre_rvpm, sk_pre_loaded)

-- ddu
local ddu_pre_rvpm, ddu_pre_loaded = check_pre("ddu.vim", "ddu")
fire_ddu()
wait_until(15000, function()
  return _G[rvpm_key("ddu.vim")] == true and vim.fn["denops#plugin#is_loaded"]("ddu") == 1
end)
check_post("ddu.vim", "ddu", ":Ddu", ddu_pre_rvpm, ddu_pre_loaded)

-- ddc
local ddc_pre_rvpm, ddc_pre_loaded = check_pre("ddc.vim", "ddc")
fire_ddc()
wait_until(15000, function()
  return _G[rvpm_key("ddc.vim")] == true and vim.fn["denops#plugin#is_loaded"]("ddc") == 1
end)
check_post("ddc.vim", "ddc", "InsertEnter", ddc_pre_rvpm, ddc_pre_loaded)

say("")
say("=== SUMMARY ===")
say("| Plugin | trigger | pre rvpm | pre is_loaded | post rvpm | post is_loaded | verdict |")
for _, r in ipairs(summary) do
  say(string.format(
    "| %s | %s | %s | %s | %s | %s | %s |",
    r.plugin, r.trigger, r.pre_rvpm, r.pre_is, r.post_rvpm, r.post_is, r.verdict
  ))
end

local all_pass = true
for _, r in ipairs(summary) do
  if r.verdict ~= "PASS" then
    all_pass = false
  end
end

say("")
if all_pass then
  say("P1 GATE: PASS")
  os.exit(0)
else
  say("P1 GATE: FAIL")
  os.exit(1)
end
