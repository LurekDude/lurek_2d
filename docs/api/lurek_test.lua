---@meta
--- LuaCATS declarations for the Lurek2D Lua test harness.

---@class LurekTestResults
---@field total integer
---@field passed integer
---@field failed integer
---@field skipped integer
---@field errors table[]
---@field passes table[]
_G._test_results = _G._test_results

---@param fn fun()
function before_each(fn) end

---@param fn fun()
function after_each(fn) end

---@param suite_name string
---@param fn fun()
function describe(suite_name, fn) end

---@param suite_name string
---@param fn fun()
function xdescribe(suite_name, fn) end

---@param test_name string
---@param fn fun()
function it(test_name, fn) end

---@param test_name string
---@param fn? fun()
function xit(test_name, fn) end

---@param msg? string
function pending(msg) end

---@param expected any
---@param actual any
---@param msg? string
function expect_equal(expected, actual, msg) end

---@param a any
---@param b any
---@param msg? string
function expect_not_equal(a, b, msg) end

---@param expected number
---@param actual number
---@param tolerance? number
---@param msg? string
function expect_near(expected, actual, tolerance, msg) end

---@param val any
---@param msg? string
function expect_true(val, msg) end

---@param val any
---@param msg? string
function expect_false(val, msg) end

---@param val any
---@param msg? string
function expect_nil(val, msg) end

---@param val any
---@param msg? string
function expect_not_nil(val, msg) end

---@param expected_type string
---@param val any
---@param msg? string
function expect_type(expected_type, val, msg) end

---@param haystack string
---@param needle string
---@param msg? string
function expect_contains(haystack, needle, msg) end

---@return boolean
function test_summary() end

---@param name string
function ensure_evidence_dir(name) end

---@param name string
---@return string
function evidence_output_dir(name) end

---@param path string
function expect_evidence_created(path) end
