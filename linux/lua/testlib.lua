-- testlib.lua - minimal check/report helper shared by linux/tests/*.lua.
--
-- Exit code contract: 0 all pass, 1 at least one failure, 77 nothing ran
-- (skipped) so a runner can tell "no coverage" from "green".

local T = { checks = 0, failures = 0, skipped = 0 }

local function show(v)
  if type(v) == "string" then return "[" .. v .. "]" end
  return tostring(v)
end

function T.eq(name, got, want)
  T.checks = T.checks + 1
  if got == want then
    print("  ok   " .. name)
  else
    T.failures = T.failures + 1
    print("  FAIL " .. name .. " got=" .. show(got) .. " want=" .. show(want))
  end
end

function T.ok(name, cond, detail)
  T.checks = T.checks + 1
  if cond then
    print("  ok   " .. name)
  else
    T.failures = T.failures + 1
    print("  FAIL " .. name .. (detail and ("  detail=" .. tostring(detail)) or ""))
  end
end

function T.skip(name, why)
  T.skipped = T.skipped + 1
  print("  skip " .. name .. "  (" .. why .. ")")
end

-- T.done() - print the summary and exit with the contract code.
function T.done(label)
  if T.checks == 0 then
    print(label .. ": SKIPPED (nothing ran)")
    os.exit(77)
  end
  if T.failures > 0 then
    print(string.format("%s: %d/%d FAILED", label, T.failures, T.checks))
    os.exit(1)
  end
  print(string.format("%s: %d passed%s", label, T.checks,
    T.skipped > 0 and (", " .. T.skipped .. " skipped") or ""))
  os.exit(0)
end

return T
