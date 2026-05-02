-- tests/lua/content/demos/_common_checks.lua
-- Shared static-analysis and load checks for all demo smoke tests.
--
-- Each demo test file calls:
--   dofile("tests/lua/content/demos/_common_checks.lua")
--   demo_common_checks("<category>/<name>", "content/games/<category>/<name>/main.lua")
--
-- What is tested:
--   1. Source file exists and is non-empty.
--   2. File loads via dofile without Lua error.
--   3. Correct callback names: lurek.init / lurek.process (not load/update/draw).
--   4. No banned render API calls (lurek.render.rectangle, lurek.render.*).
--   5. No banned input API calls (lurek.input.isDown, lurek.input.getPosition).
--   6. No file-scope local captures of lurek sub-tables (captures nil in engine).
--   7. No old namespace names (lurek.render, lurek.input, lurek.mouse).
--
-- Note on __newindex:  after dofile(), lurek.init / lurek.process read as nil
-- because the lurek table's __newindex metamethod intercepts assignment and
-- stores callbacks internally without writing them back to the table.  All
-- callback verification is therefore done via static analysis of the source text.

-- Read source file, return text or nil.
local function read_source(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local src = f:read("*all")
    f:close()
    return src
end

-- Check that `src` does NOT contain `pattern`, failing with `msg` if it does.
local function refute_pattern(src, pattern, msg)
    local found = src:find(pattern) ~= nil
    expect_false(found, msg)
end

-- Check that `src` DOES contain `pattern`, failing with `msg` if it doesn't.
local function require_pattern(src, pattern, msg)
    local found = src:find(pattern) ~= nil
    expect_true(found, msg)
end

-- Run all standard checks for a demo.
-- `demo_name`  short label (e.g. "globe_demo")
-- `demo_path`  relative path to main.lua from repo root
function demo_common_checks(demo_name, demo_path)

    local src = nil

    -- -----------------------------------------------------------------
    -- Suite 1: File exists and loads
    -- -----------------------------------------------------------------
    describe(demo_name .. ": file and load", function()
        it("source file exists and is non-empty", function()
            src = read_source(demo_path)
            expect_not_nil(src, "Cannot open " .. demo_path)
            expect_greater(#src, 100, "source too short     likely missing or blank")
        end)

        it("dofile executes without Lua error", function()
            if not src then
                return
            end
            expect_no_error(function()
                dofile(demo_path)
            end, "dofile(" .. demo_path .. ")")
        end)
    end)

    -- -----------------------------------------------------------------
    -- Suite 2: Callback name correctness (static analysis)
    -- -----------------------------------------------------------------
    describe(demo_name .. ": callback names", function()
        before_each(function()
            if not src then src = read_source(demo_path) end
        end)

        it("registers lurek.init, not lurek.load", function()
            expect_not_nil(src, 'source missing')
            refute_pattern(src, "function%s+lurek%.load%s*%(",
                "found 'function lurek.load()'     wrong callback name, use lurek.init")
            require_pattern(src, "function%s+lurek%.init%s*%(",
                "lurek.init callback not found     required by engine loop")
        end)

        it("registers lurek.process, not lurek.update", function()
            expect_not_nil(src, 'source missing')
            refute_pattern(src, "function%s+lurek%.update%s*%(",
                "found 'function lurek.update()'     wrong callback name, use lurek.process")
            require_pattern(src, "function%s+lurek%.process%s*%(",
                "lurek.process callback not found     engine update loop won't run")
        end)

        it("does not use lurek.draw (wrong callback)", function()
            expect_not_nil(src, 'source missing')
            refute_pattern(src, "function%s+lurek%.draw%s*%(",
                "found 'function lurek.draw()'     wrong callback name, use lurek.render")
        end)
    end)

    -- -----------------------------------------------------------------
    -- Suite 3: API correctness (static analysis)
    -- -----------------------------------------------------------------
    describe(demo_name .. ": API correctness", function()
        before_each(function()
            if not src then src = read_source(demo_path) end
        end)

        it("does not call lurek.render.rectangle (invalid method)", function()
            expect_not_nil(src, 'source missing')
            refute_pattern(src, "lurek%.render%.rectangle%s*%(",
                "lurek.render.rectangle is not a valid API     use drawRect(\"fill\",...) or drawRect(\"line\",...)")
        end)

        it("does not call lurek.input.isDown (invalid method)", function()
            expect_not_nil(src, 'source missing')
            refute_pattern(src, "lurek%.input%.isDown%s*%(",
                "lurek.input.isDown() is invalid     use isActionDown() or wasActionPressed()")
        end)

        it("does not call lurek.input.getPosition (invalid method)", function()
            expect_not_nil(src, 'source missing')
            refute_pattern(src, "lurek%.input%.getPosition%s*%(",
                "lurek.input.getPosition() is invalid     use getMousePosition()")
        end)

        it("does not use old lurek.render namespace", function()
            expect_not_nil(src, 'source missing')
            -- Allow 'lurek.render' only if it's the globe 'graphic' property name.
            -- We target 'lurek.render.' method calls specifically.
            refute_pattern(src, "lurek%.graphic%.",
                "old namespace lurek.render.* found     render API is lurek.render.*")
        end)

        it("does not use old lurek.input namespace", function()
            expect_not_nil(src, 'source missing')
            refute_pattern(src, "lurek%.keyboard%.",
                "old namespace lurek.input found     use lurek.input")
        end)

        it("does not use old lurek.input namespace", function()
            expect_not_nil(src, 'source missing')
            -- Allow lurek.input only as a string argument like input.bind("mouse1")
            -- which won't match lurek.mouse.* anyway.
            refute_pattern(src, "lurek%.mouse%.",
                "old namespace lurek.input found     use lurek.input")
        end)

        it("does not capture lurek sub-table as file-scope local (captures nil)", function()
            expect_not_nil(src, 'source missing')
            -- Pattern: at file scope, before any function, 'local X = lurek.render'
            -- This is an anti-pattern: lurek.render is nil at parse time; the engine
            -- populates it after the file is loaded. Capture inside a callback is fine.
            refute_pattern(src, "^local%s+%a+%s*=%s*lurek%.render",
                "file-scope 'local X = lurek.render' captures nil     call lurek.render.* directly inside callbacks")
        end)
    end)
end
test_summary()
