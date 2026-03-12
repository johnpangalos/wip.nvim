--- Minimal test runner for nvim --headless -l
--- Usage: nvim --headless -l tests/run.lua

local passed = 0
local failed = 0
local errors = {}

--- @param name string
--- @param fn fun()
function describe(name, fn)
  print("\n" .. name)
  fn()
end

--- @param name string
--- @param fn fun()
function it(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print("  PASS: " .. name)
  else
    failed = failed + 1
    table.insert(errors, { name = name, err = err })
    print("  FAIL: " .. name)
    print("    " .. tostring(err))
  end
end

--- @param a any
--- @param b any
--- @param msg string|nil
function assert_eq(a, b, msg)
  if type(a) == "table" and type(b) == "table" then
    assert(vim.deep_equal(a, b), msg or string.format("expected %s, got %s", vim.inspect(b), vim.inspect(a)))
  else
    assert(a == b, msg or string.format("expected %s, got %s", tostring(b), tostring(a)))
  end
end

--- @param t table
--- @param n number
--- @param msg string|nil
function assert_len(t, n, msg)
  assert(#t == n, msg or string.format("expected length %d, got %d", n, #t))
end

-- Add project root to package.path so require("wip.*") works
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

-- Discover and run all *_spec.lua files
local spec_dir = root .. "/tests"
local specs = vim.fn.glob(spec_dir .. "/*_spec.lua", false, true)
table.sort(specs)

for _, spec_file in ipairs(specs) do
  dofile(spec_file)
end

-- Summary
print(string.format("\n%d passed, %d failed", passed, failed))

if failed > 0 then
  vim.cmd("cquit 1")
else
  vim.cmd("qall!")
end
