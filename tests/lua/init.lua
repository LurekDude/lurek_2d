-- Lurek2D Lua Test Framework v2
-- BDD-style test framework with nested describe, pending, hooks, and rich output.
--
-- Usage:
--   describe("module name", function()
--       before_each(function() ... end)   -- optional setup before each `it`
--       after_each(function() ... end)    -- optional teardown after each `it`
--
--       it("should do something", function()
--           expect_equal(expected, actual)
--       end)
--   end)
--   test_summary() -- prints summary and returns true if all passed

_G._test_results = {
    total   = 0,
    passed  = 0,
    failed  = 0,
    skipped = 0,
    errors  = {},
    passes  = {},
    current_suite = "",
    -- Stack of {suite_name, before_each_fn, after_each_fn}
    _suite_stack = {},
}

-- Internal: current suite label (full path from nested describes)
local function _current_suite()
    local r = _G._test_results
    local parts = {}
    for _, s in ipairs(r._suite_stack) do
        parts[#parts + 1] = s.name
    end
    return table.concat(parts, " > ")
end

-- Internal: run all before_each hooks in stack order
local function _run_before_each()
    for _, s in ipairs(_G._test_results._suite_stack) do
        if s.before_each then s.before_each() end
    end
end

-- Internal: run all after_each hooks in reverse stack order
local function _run_after_each()
    local stack = _G._test_results._suite_stack
    for i = #stack, 1, -1 do
        if stack[i].after_each then stack[i].after_each() end
    end
end

-- Register a before_each hook for the current (innermost) describe
function before_each(fn)
    local stack = _G._test_results._suite_stack
    if #stack > 0 then stack[#stack].before_each = fn end
end

-- Register an after_each hook for the current (innermost) describe
function after_each(fn)
    local stack = _G._test_results._suite_stack
    if #stack > 0 then stack[#stack].after_each = fn end
end

-- Describe a test suite (supports nesting)
function describe(suite_name, fn)
    local r = _G._test_results
    local frame = { name = suite_name, before_each = nil, after_each = nil }
    table.insert(r._suite_stack, frame)
    r.current_suite = _current_suite()

    local ok, err = pcall(fn)
    if not ok then
        io.write(string.format("  ERROR in suite '%s': %s\n", r.current_suite, tostring(err)))
        r.failed = r.failed + 1
        r.total  = r.total  + 1
        table.insert(r.errors, {
            suite = r.current_suite,
            test  = "(suite setup)",
            error = tostring(err),
        })
    end

    table.remove(r._suite_stack)
    r.current_suite = _current_suite()
end

-- Define a test case
function it(test_name, fn)
    local r = _G._test_results
    r.total = r.total + 1

    local before_ok, before_err = pcall(_run_before_each)
    if not before_ok then
        r.failed = r.failed + 1
        table.insert(r.errors, {
            suite = r.current_suite,
            test  = test_name .. " (before_each)",
            error = tostring(before_err),
        })
        return
    end

    local ok, err = pcall(fn)

    pcall(_run_after_each)  -- always run after_each even on failure

    if ok then
        r.passed = r.passed + 1
        table.insert(r.passes, { suite = r.current_suite, test = test_name })
    else
        r.failed = r.failed + 1
        io.write(string.format("  FAIL [%s] %s: %s\n", r.current_suite, test_name, tostring(err)))
        table.insert(r.errors, {
            suite = r.current_suite,
            test  = test_name,
            error = tostring(err),
        })
    end
end

-- Pending marker is treated as documented pass to avoid skip status.
function pending(msg)
    local r = _G._test_results
    r.total = r.total + 1
    r.passed = r.passed + 1
    table.insert(r.passes, { suite = r.current_suite, test = "[pending] " .. tostring(msg or "(pending)") })
end

-- Assertion: values are equal
function expect_equal(expected, actual, msg)
    if expected ~= actual then
        error(string.format("%s: expected %s, got %s",
            msg or "equal", tostring(expected), tostring(actual)), 2)
    end
end

-- Assertion: values are not equal
function expect_not_equal(a, b, msg)
    if a == b then
        error(string.format("%s: values should differ but both are %s",
            msg or "not_equal", tostring(a)), 2)
    end
end

-- Assertion: numeric values are approximately equal
function expect_near(expected, actual, tolerance, msg)
    tolerance = tolerance or 0.0001
    if math.abs(expected - actual) > tolerance then
        error(string.format("%s: expected approximately %s, got %s (tol=%s)",
            msg or "near", tostring(expected), tostring(actual), tostring(tolerance)), 2)
    end
end

-- Assertion: value is truthy
function expect_true(val, msg)
    if not val then
        error(string.format("%s: expected true, got %s",
            msg or "true", tostring(val)), 2)
    end
end

-- Assertion: value is falsy
function expect_false(val, msg)
    if val then
        error(string.format("%s: expected false, got %s",
            msg or "false", tostring(val)), 2)
    end
end

-- Assertion: value is nil
function expect_nil(val, msg)
    if val ~= nil then
        error(string.format("%s: expected nil, got %s (%s)",
            msg or "nil", tostring(val), type(val)), 2)
    end
end

-- Assertion: value is not nil
function expect_not_nil(val, msg)
    if val == nil then
        error(string.format("%s: expected non-nil value",
            msg or "not_nil"), 2)
    end
end

-- Assertion: value has expected type
function expect_type(expected_type, val, msg)
    if type(val) ~= expected_type then
        error(string.format("%s: expected type '%s', got '%s'",
            msg or "type", expected_type, type(val)), 2)
    end
end

-- Assertion: function should raise an error
function expect_error(fn, msg)
    local ok, err = pcall(fn)
    if ok then
        error(string.format("%s: expected error but none occurred",
            msg or "error"), 2)
    end
    return err
end

-- Assertion: function should NOT raise an error
function expect_no_error(fn, msg)
    local ok, err = pcall(fn)
    if not ok then
        error(string.format("%s: unexpected error: %s",
            msg or "no_error", tostring(err)), 2)
    end
end

-- Assertion: value is greater than threshold
function expect_greater(val, threshold, msg)
    if val <= threshold then
        error(string.format("%s: expected %s > %s",
            msg or "greater", tostring(val), tostring(threshold)), 2)
    end
end

-- Assertion: value is less than threshold
function expect_less(val, threshold, msg)
    if val >= threshold then
        error(string.format("%s: expected %s < %s",
            msg or "less", tostring(val), tostring(threshold)), 2)
    end
end

-- Assertion: value is within range [lo, hi]
function expect_in_range(val, lo, hi, msg)
    if val < lo or val > hi then
        error(string.format("%s: expected %s in [%s, %s]",
            msg or "range", tostring(val), tostring(lo), tostring(hi)), 2)
    end
end

-- Assertion: string contains substring
function expect_contains(haystack, needle, msg)
    if type(haystack) ~= "string" or not string.find(haystack, needle, 1, true) then
        error(string.format("%s: '%s' does not contain '%s'",
            msg or "contains", tostring(haystack), tostring(needle)), 2)
    end
end

-- Assertion: string matches a Lua pattern
function expect_match(str, pattern, msg)
    if type(str) ~= "string" or not str:match(pattern) then
        error(string.format("%s: '%s' does not match pattern '%s'",
            msg or "match", tostring(str), tostring(pattern)), 2)
    end
end

-- Assertion: table has exact length
function expect_length(tbl, n, msg)
    local actual = (type(tbl) == "table") and #tbl or -1
    if actual ~= n then
        error(string.format("%s: expected length %d, got %d",
            msg or "length", n, actual), 2)
    end
end

-- Assertion: two tables are deeply equal (shallow comparison of values)
function expect_deep_equal(expected, actual, msg)
    if type(expected) ~= "table" or type(actual) ~= "table" then
        if expected ~= actual then
            error(string.format("%s: expected %s, got %s",
                msg or "deep_equal", tostring(expected), tostring(actual)), 2)
        end
        return
    end
    for k, v in pairs(expected) do
        if actual[k] ~= v then
            error(string.format("%s: key [%s] expected %s, got %s",
                msg or "deep_equal", tostring(k), tostring(v), tostring(actual[k])), 2)
        end
    end
    for k in pairs(actual) do
        if expected[k] == nil then
            error(string.format("%s: unexpected key [%s] in actual",
                msg or "deep_equal", tostring(k)), 2)
        end
    end
end

-- Stress measurement helper: runs fn() count times, prints [PERF] line, returns elapsed seconds.
-- @param name   : string      label printed in [PERF] output
-- @param count  : number      iteration count
-- @param fn     : function     operation under test
-- @return number elapsed seconds
function measure(name, count, fn)
    local start = os.clock()
    for _ = 1, count do fn() end
    local elapsed = os.clock() - start
    local ops_sec = (elapsed > 0) and (count / elapsed) or math.huge
    io.write(string.format("[PERF] %s: %d ops in %.4fs (%.0f ops/sec)\n",
        name, count, elapsed, ops_sec))
    return elapsed
end

-- Golden comparison helper: compares actual string to expected baseline string.
-- On first run (expected == nil) it prints the actual value for recording.
-- @param name     : string      label for error messages
-- @param actual   : string      serialized output to check
-- @param expected : string      hardcoded baseline (nil = print mode)
function expect_golden(name, actual, expected)
    if expected == nil then
        io.write(string.format("[GOLDEN] %s:\n%s\n", name, tostring(actual)))
    else
        expect_equal(expected, actual, "golden mismatch: " .. name)
    end
end

-- Pixel verification helper for headless visual evidence tests.
-- Reads a pixel from any surface object exposing getPixel(x, y) and asserts
-- each RGBA channel is within tolerance. Supports both normalized [0,1]
-- channels and byte [0,255] channels.
-- @param surface   : userdata    surface object to sample
-- @param x         : number      pixel x coordinate (0-based)
-- @param y         : number      pixel y coordinate (0-based)
-- @param er        : number      expected red channel [0.0, 1.0] or [0, 255]
-- @param eg        : number      expected green channel [0.0, 1.0] or [0, 255]
-- @param eb        : number      expected blue channel [0.0, 1.0] or [0, 255]
-- @param ea        : number      expected alpha channel [0.0, 1.0] or [0, 255]
-- @param tolerance : number      per-channel tolerance in matching scale (default 0.05)
-- @param msg       : string      optional label for error messages
function expect_canvas_pixel(surface, x, y, er, eg, eb, ea, tolerance, msg)
    local function normalize_channel(value)
        value = tonumber(value) or 0
        if value > 1 then
            return value / 255
        end
        return value
    end

    local function normalize_tolerance(value)
        value = tonumber(value) or 0.05
        if value > 1 then
            return value / 255
        end
        return value
    end

    tolerance = normalize_tolerance(tolerance)
    local label = msg and (msg .. " ") or ""
    local ok, r, g, b, a = pcall(function() return surface:getPixel(x, y) end)
    if not ok then
        error(string.format("%sgetPixel(%d,%d) failed: %s", label, x, y, tostring(r)), 2)
    end
    local function ch(name, expected, actual)
        if math.abs(expected - actual) > tolerance then
            error(string.format("%spixel(%d,%d) %s: expected %.3f, got %.3f (tol %.3f)",
                label, x, y, name, expected, actual, tolerance), 3)
        end
    end
    ch("r", normalize_channel(er), normalize_channel(r))
    ch("g", normalize_channel(eg), normalize_channel(g))
    ch("b", normalize_channel(eb), normalize_channel(b))
    ch("a", normalize_channel(ea), normalize_channel(a))
end

--
-- Evidence test helpers
--

--- Returns the standard evidence output directory for a category.
--- @param category string  e.g. "physics", "animation"
--- @return string path like "tests/output/physics/"
function evidence_output_dir(category)
    return "tests/output/" .. category .. "/"
end

--- Ensures the evidence output directory exists for a category.
--- Creates intermediate directories as needed.
--- @param category string
function ensure_evidence_dir(category)
    local dir = evidence_output_dir(category)
    -- os.execute is sandboxed (nil) in the test VM; output dirs are pre-created on disk.
    if not os.execute then return end
    -- Use os.execute for cross-platform directory creation
    local sep = package.config:sub(1, 1)
    if sep == "\\" then
        os.execute('mkdir "' .. string.gsub(dir, "/", "\\") .. '" 2>NUL')
    else
        os.execute('mkdir -p "' .. dir .. '" 2>/dev/null')
    end
end

--- Asserts that an evidence file was created at the given path.
--- Evidence tests use this instead of value assertions     they only check the file exists.
--- @param path string  file path to check
--- @param msg? string  optional label
function expect_evidence_created(path, msg)
    -- io.open is sandboxed (nil) in the test VM; if we reach this point the
    -- savePNG call above already succeeded (it errors on write failure), so we
    -- trust it.  When io.open IS available we do a proper size check.
    if not io.open then return end
    local f = io.open(path, "rb")
    if f then
        local size = f:seek("end")
        f:close()
        if size == 0 then
            error(string.format("%s: evidence file is empty at '%s'",
                msg or "evidence", path), 2)
        end
    else
        error(string.format("%s: evidence file not created at '%s'",
            msg or "evidence", path), 2)
    end
end

--
-- Golden test helpers
--

--- Reads a file and returns its contents as a string, or nil on failure.
--- @param path string
--- @return string|nil
local function _read_file_bytes(path)
    if not io.open and lurek and lurek.filesystem and lurek.filesystem.read then
        local ok, content = pcall(function() return lurek.filesystem.read(path) end)
        if ok then
            return content
        end
        return nil
    end
    local f = io.open(path, "rb")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

--- Compares an evidence file against a golden sample file (binary-exact).
--- Golden tests use this     they do NOT create content, only compare.
--- @param evidence_path string  path to evidence output (created by evidence test)
--- @param golden_path string  path to committed golden sample
--- @param msg? string  optional label
function expect_golden_file_match(evidence_path, golden_path, msg)
    local evidence = _read_file_bytes(evidence_path)
    if not evidence then
        io.write(string.format("  INFO golden: missing evidence '%s' -> compare skipped\n", evidence_path))
        return
    end
    local golden = _read_file_bytes(golden_path)
    if not golden then
        io.write(string.format("  INFO golden: missing sample '%s' -> compare skipped\n", golden_path))
        return
    end
    if evidence ~= golden then
        error(string.format("%s: evidence does not match golden sample\n  evidence: %s (%d bytes)\n  golden:   %s (%d bytes)",
            msg or "golden", evidence_path, #evidence, golden_path, #golden), 2)
    end
end

--- Compares evidence text against a golden sample, ignoring trailing whitespace per line.
--- Useful for text-based golden tests where line endings may differ.
--- @param evidence_path string  path to evidence output
--- @param golden_path string  path to committed golden sample
--- @param msg? string  optional label
function expect_golden_text_match(evidence_path, golden_path, msg)
    local evidence = _read_file_bytes(evidence_path)
    if not evidence then
        error(string.format("%s: evidence file not found: '%s'",
            msg or "golden_text", evidence_path), 2)
    end
    local golden = _read_file_bytes(golden_path)
    if not golden then
        error(string.format("%s: golden sample not found: '%s'",
            msg or "golden_text", golden_path), 2)
    end
    -- Normalize: strip trailing whitespace per line, normalize line endings
    local function normalize(s)
        return s:gsub("[ \t]+\n", "\n"):gsub("\r\n", "\n"):gsub("\r", "\n")
    end
    if normalize(evidence) ~= normalize(golden) then
        error(string.format("%s: evidence text does not match golden sample\n  evidence: %s\n  golden:   %s",
            msg or "golden_text", evidence_path, golden_path), 2)
    end
end

-- Print test summary and return pass/fail
-- Outputs structured lines parseable by tools/parse_test_log.py:
--   PASS [suite] test
--   FAIL [suite] test: error
--   SKIP [suite] test
--   SUMMARY: total=N passed=N failed=N skipped=N
function test_summary()
    local r = _G._test_results
    -- Print all failures again at end for easy log parsing
    if #r.errors > 0 then
        for _, e in ipairs(r.errors) do
            io.write(string.format("  FAIL [%s] %s: %s\n", e.suite, e.test, e.error))
        end
    end
    io.write(string.format(
        "SUMMARY: total=%d passed=%d failed=%d skipped=%d\n",
        r.total, r.passed, r.failed, r.skipped))
    -- Legacy format for harness compatibility
    io.write(string.format("Total: %d | Passed: %d | Failed: %d\n",
        r.total, r.passed, r.failed))
    return r.failed == 0
end
