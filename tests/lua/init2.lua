-- Luna2D Lua Test Framework
-- BDD-style test framework inspired by Lua game engine testing approaches
-- Usage:
--   describe("module name", function()
--       it("should do something", function()
--           expect_equal(expected, actual)
--       end)
--   end)
--   test_summary() -- returns true if all passed

_G._test_results = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = {},
    current_suite = "",
}

-- Describe a test suite
function describe(suite_name, fn)
    _G._test_results.current_suite = suite_name
    local ok, err = pcall(fn)
    if not ok then
        print("  ERROR in suite '" .. suite_name .. "': " .. tostring(err))
        _G._test_results.failed = _G._test_results.failed + 1
        _G._test_results.total = _G._test_results.total + 1
        table.insert(_G._test_results.errors, {
            suite = suite_name,
            test = "(suite setup)",
            error = tostring(err),
        })
    end
end

-- Define a test case
function it(test_name, fn)
    _G._test_results.total = _G._test_results.total + 1
    local ok, err = pcall(fn)
    if ok then
        _G._test_results.passed = _G._test_results.passed + 1
    else
        _G._test_results.failed = _G._test_results.failed + 1
        table.insert(_G._test_results.errors, {
            suite = _G._test_results.current_suite,
            test = test_name,
            error = tostring(err),
        })
    end
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
        error(string.format("%s: expected ~%s, got %s (tol=%s)",
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

-- Print test summary and return pass/fail
function test_summary()
    local r = _G._test_results
    if #r.errors > 0 then
        for _, e in ipairs(r.errors) do
            io.write(string.format("  FAIL [%s] %s: %s\n", e.suite, e.test, e.error))
        end
    end
    io.write(string.format("Total: %d | Passed: %d | Failed: %d\n",
        r.total, r.passed, r.failed))
    return r.failed == 0
end
