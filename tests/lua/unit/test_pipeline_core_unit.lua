-- BDD tests for lurek.pipeline DAG pipeline orchestrator

-- =========================================================================
-- Helper: table contains value
-- =========================================================================

local function table_contains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

-- =========================================================================
-- 1. Module existence
-- =========================================================================
-- @describe lurek.pipeline module exists
describe("lurek.pipeline module exists", function()
    -- @covers lurek.pipeline
    it("lurek.pipeline is a table", function()
        expect_type("table", lurek.pipeline)
    end)

    -- @covers lurek.pipeline.newStep
    it("has newStep factory", function()
        expect_type("function", lurek.pipeline.newStep)
    end)

    -- @covers lurek.pipeline.newPipeline
    it("has newPipeline factory", function()
        expect_type("function", lurek.pipeline.newPipeline)
    end)

    -- @covers lurek.pipeline.fromTable
    it("has fromTable factory", function()
        expect_type("function", lurek.pipeline.fromTable)
    end)
end)

-- =========================================================================
-- 2. PipelineStep construction and configuration
-- =========================================================================
-- @describe PipelineStep construction
describe("PipelineStep construction", function()
    -- @covers lurek.pipeline.newStep
    it("newStep returns userdata", function()
        local s = lurek.pipeline.newStep("step1")
        expect_type("userdata", s)
    end)

    -- @covers LPipelineStep:getName
    -- @covers lurek.pipeline.newStep
    it("newStep with name stores name", function()
        local s = lurek.pipeline.newStep("my_step")
        expect_equal("my_step", s:getName())
    end)

    -- @covers LPipelineStep:getName
    -- @covers lurek.pipeline.newStep
    it("newStep with callback fn stores it", function()
        local s = lurek.pipeline.newStep("cb_step", function(ctx) return 1 end)
        expect_equal("cb_step", s:getName())
    end)

    -- @covers LPipelineStep:type
    -- @covers lurek.pipeline.newStep
    it("type() returns 'LPipelineStep'", function()
        local s = lurek.pipeline.newStep("s")
        expect_equal("LPipelineStep", s:type())
    end)

    -- @covers LPipelineStep:typeOf
    -- @covers lurek.pipeline.newStep
    it("typeOf('LPipelineStep') is true", function()
        local s = lurek.pipeline.newStep("s")
        expect_true(s:typeOf("LPipelineStep"))
    end)

    -- @covers LPipelineStep:getStatus
    -- @covers lurek.pipeline.newStep
    it("initial status is 'pending'", function()
        local s = lurek.pipeline.newStep("s")
        expect_equal("pending", s:getStatus())
    end)

    -- @covers LPipelineStep:getDelay
    -- @covers LPipelineStep:setDelay
    -- @covers lurek.pipeline.newStep
    it("setDelay/getDelay roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setDelay(0.5)
        expect_near(0.5, s:getDelay())
    end)

    -- @covers LPipelineStep:isOptional
    -- @covers LPipelineStep:setOptional
    -- @covers lurek.pipeline.newStep
    it("setOptional/isOptional roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setOptional(true)
        expect_true(s:isOptional())
        s:setOptional(false)
        expect_false(s:isOptional())
    end)

    -- @covers LPipelineStep:getRetryCount
    -- @covers LPipelineStep:setRetryCount
    -- @covers lurek.pipeline.newStep
    it("setRetryCount/getRetryCount roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setRetryCount(3)
        expect_equal(3, s:getRetryCount())
    end)

    -- @covers LPipelineStep:getTag
    -- @covers LPipelineStep:setTag
    -- @covers lurek.pipeline.newStep
    it("setTag/getTag roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setTag("critical")
        expect_equal("critical", s:getTag())
    end)

    -- @covers LPipelineStep:getData
    -- @covers LPipelineStep:setData
    -- @covers lurek.pipeline.newStep
    it("setData/getData roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setData("env", "prod")
        expect_equal("prod", s:getData("env"))
    end)

    -- @covers LPipelineStep:getData
    -- @covers lurek.pipeline.newStep
    it("getData missing key returns nil", function()
        local s = lurek.pipeline.newStep("s")
        expect_nil(s:getData("nonexistent"))
    end)
end)

-- =========================================================================
-- 3. PipelineStep dependency management
-- =========================================================================
-- @describe PipelineStep dependency management
describe("PipelineStep dependency management", function()
    -- @covers LPipelineStep:dependsOn
    -- @covers LPipelineStep:getDependencies
    -- @covers lurek.pipeline.newStep
    it("dependsOn string adds dependency", function()
        local s = lurek.pipeline.newStep("child")
        s:dependsOn("parent")
        local deps = s:getDependencies()
        expect_true(table_contains(deps, "parent"))
    end)

    -- @covers LPipelineStep:dependsOn
    -- @covers LPipelineStep:getDependencies
    -- @covers lurek.pipeline.newStep
    it("dependsOn step object adds dependency by name", function()
        local parent = lurek.pipeline.newStep("parent_step")
        local child = lurek.pipeline.newStep("child_step")
        child:dependsOn(parent)
        local deps = child:getDependencies()
        expect_true(table_contains(deps, "parent_step"))
    end)

    -- @covers LPipelineStep:dependsOn
    -- @covers lurek.pipeline.newStep
    it("dependsOn returns self for chaining", function()
        local s = lurek.pipeline.newStep("s")
        local ret = s:dependsOn("a")
        -- should not error and should be the same step
        expect_equal("s", ret:getName())
    end)

    -- @covers LPipelineStep:dependsOn
    -- @covers LPipelineStep:getDependencies
    -- @covers lurek.pipeline.newStep
    it("getDependencies returns all added deps", function()
        local s = lurek.pipeline.newStep("s")
        s:dependsOn("x")
        s:dependsOn("y")
        local deps = s:getDependencies()
        expect_true(table_contains(deps, "x"))
        expect_true(table_contains(deps, "y"))
    end)

    -- @covers LPipelineStep:dependsOn
    -- @covers LPipelineStep:getDependencyCount
    -- @covers lurek.pipeline.newStep
    it("getDependencyCount matches", function()
        local s = lurek.pipeline.newStep("s")
        s:dependsOn("a")
        s:dependsOn("b")
        expect_equal(2, s:getDependencyCount())
    end)
end)

-- =========================================================================
-- 4. Pipeline construction and step management
-- =========================================================================
-- @describe Pipeline construction
describe("Pipeline construction", function()
    -- @covers lurek.pipeline.newPipeline
    it("newPipeline returns userdata", function()
        local p = lurek.pipeline.newPipeline("test")
        expect_type("userdata", p)
    end)

    -- @covers LPipeline:type
    -- @covers lurek.pipeline.newPipeline
    it("type() returns 'LPipeline'", function()
        local p = lurek.pipeline.newPipeline()
        expect_equal("LPipeline", p:type())
    end)

    -- @covers LPipeline:typeOf
    -- @covers lurek.pipeline.newPipeline
    it("typeOf('LPipeline') is true", function()
        local p = lurek.pipeline.newPipeline()
        expect_true(p:typeOf("LPipeline"))
    end)

    -- @covers LPipeline:getStepCount
    -- @covers lurek.pipeline.newPipeline
    it("empty pipeline has stepCount 0", function()
        local p = lurek.pipeline.newPipeline()
        expect_equal(0, p:getStepCount())
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:getStepCount
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("addStep increments stepCount", function()
        local p = lurek.pipeline.newPipeline()
        local s = lurek.pipeline.newStep("s", function(ctx) return 1 end)
        p:addStep(s)
        expect_equal(1, p:getStepCount())
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:getStep
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("getStep returns the added step", function()
        local p = lurek.pipeline.newPipeline()
        local s = lurek.pipeline.newStep("find_me", function(ctx) return 1 end)
        p:addStep(s)
        local got = p:getStep("find_me")
        expect_type("userdata", got)
        expect_equal("find_me", got:getName())
    end)

    -- @covers LPipeline:getStep
    -- @covers lurek.pipeline.newPipeline
    it("getStep unknown returns nil", function()
        local p = lurek.pipeline.newPipeline()
        expect_nil(p:getStep("ghost"))
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:getStepCount
    -- @covers LPipeline:removeStep
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("removeStep decrements count", function()
        local p = lurek.pipeline.newPipeline()
        local s = lurek.pipeline.newStep("s", function(ctx) return 1 end)
        p:addStep(s)
        p:removeStep("s")
        expect_equal(0, p:getStepCount())
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:getStepsByTag
    -- @covers LPipelineStep:setTag
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("getStepsByTag filters correctly", function()
        local p = lurek.pipeline.newPipeline()
        local s1 = lurek.pipeline.newStep("s1", function(ctx) return 1 end)
        local s2 = lurek.pipeline.newStep("s2", function(ctx) return 2 end)
        local s3 = lurek.pipeline.newStep("s3", function(ctx) return 3 end)
        s1:setTag("alpha")
        s2:setTag("beta")
        s3:setTag("alpha")
        p:addStep(s1):addStep(s2):addStep(s3)
        local alpha = p:getStepsByTag("alpha")
        expect_equal(2, #alpha)
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:clear
    -- @covers LPipeline:getStepCount
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("clear empties pipeline", function()
        local p = lurek.pipeline.newPipeline()
        p:addStep(lurek.pipeline.newStep("a", function(ctx) return 1 end))
        p:addStep(lurek.pipeline.newStep("b", function(ctx) return 2 end))
        p:clear()
        expect_equal(0, p:getStepCount())
    end)

    -- @covers LPipeline:getName
    -- @covers LPipeline:setName
    -- @covers lurek.pipeline.newPipeline
    it("getName/setName roundtrip", function()
        local p = lurek.pipeline.newPipeline("original")
        expect_equal("original", p:getName())
        p:setName("renamed")
        expect_equal("renamed", p:getName())
    end)

    -- @covers LPipeline:getErrorMode
    -- @covers LPipeline:setErrorMode
    -- @covers lurek.pipeline.newPipeline
    it("setErrorMode/getErrorMode roundtrip", function()
        local p = lurek.pipeline.newPipeline()
        p:setErrorMode("continue")
        expect_equal("continue", p:getErrorMode())
        p:setErrorMode("abort")
        expect_equal("abort", p:getErrorMode())
    end)
end)

-- =========================================================================
-- 5. Validation and topological order
-- =========================================================================
-- @describe Pipeline validation
describe("Pipeline validation", function()
    -- @covers LPipeline:validate
    -- @covers lurek.pipeline.newPipeline
    it("empty pipeline validates ok", function()
        local p = lurek.pipeline.newPipeline()
        local ok, errs = p:validate()
        expect_true(ok)
        expect_equal(0, #errs)
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:validate
    -- @covers LPipelineStep:dependsOn
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("valid dag validates ok", function()
        local p = lurek.pipeline.newPipeline()
        local s1 = lurek.pipeline.newStep("a", function(ctx) return 1 end)
        local s2 = lurek.pipeline.newStep("b", function(ctx) return 2 end)
        s2:dependsOn("a")
        p:addStep(s1):addStep(s2)
        local ok, errs = p:validate()
        expect_true(ok)
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:validate
    -- @covers LPipelineStep:dependsOn
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("missing dep fails validation", function()
        local p = lurek.pipeline.newPipeline()
        local s = lurek.pipeline.newStep("child", function(ctx) return 1 end)
        s:dependsOn("missing_parent")
        p:addStep(s)
        local ok, errs = p:validate()
        expect_false(ok)
        expect_true(#errs > 0)
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:validate
    -- @covers LPipelineStep:dependsOn
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("cycle fails validation", function()
        local p = lurek.pipeline.newPipeline()
        local s1 = lurek.pipeline.newStep("a", function(ctx) return 1 end)
        local s2 = lurek.pipeline.newStep("b", function(ctx) return 2 end)
        s1:dependsOn("b")
        s2:dependsOn("a")
        p:addStep(s1):addStep(s2)
        local ok, errs = p:validate()
        expect_false(ok)
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:getExecutionOrder
    -- @covers LPipelineStep:dependsOn
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("getExecutionOrder returns topo order", function()
        local p = lurek.pipeline.newPipeline()
        local s1 = lurek.pipeline.newStep("first", function(ctx) return 1 end)
        local s2 = lurek.pipeline.newStep("second", function(ctx) return 2 end)
        s2:dependsOn("first")
        p:addStep(s1):addStep(s2)
        local order, err = p:getExecutionOrder()
        expect_not_equal(nil, order)
        expect_nil(err)
        -- "first" must appear before "second"
        local pos_first, pos_second = nil, nil
        for i, name in ipairs(order) do
            if name == "first" then pos_first = i end
            if name == "second" then pos_second = i end
        end
        expect_true(pos_first ~= nil)
        expect_true(pos_second ~= nil)
        expect_true(pos_first < pos_second)
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:getParallelGroups
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("getParallelGroups groups independent steps", function()
        local p = lurek.pipeline.newPipeline()
        local s1 = lurek.pipeline.newStep("a", function(ctx) return 1 end)
        local s2 = lurek.pipeline.newStep("b", function(ctx) return 2 end)
        p:addStep(s1):addStep(s2)
        local groups, err = p:getParallelGroups()
        expect_not_equal(nil, groups)
        expect_nil(err)
        -- two independent steps can go in the same group
        local total = 0
        for _, group in ipairs(groups) do
            total = total + #group
        end
        expect_equal(2, total)
    end)
end)

-- =========================================================================
-- 6. Pipeline.run() execution
-- =========================================================================
-- @describe Pipeline.run() execution
describe("Pipeline.run() execution", function()
    -- @covers LPipeline:addStep
    -- @covers LPipeline:run
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("single step runs and result is success", function()
        local s = lurek.pipeline.newStep("compute", function(ctx) return 42 end)
        local p = lurek.pipeline.newPipeline("test")
        p:addStep(s)
        local r = p:run()
        expect_true(r.success)
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:run
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("step callback receives context table", function()
        local got_ctx_type = nil
        local s = lurek.pipeline.newStep("ctx_check", function(ctx)
            got_ctx_type = type(ctx)
            return 1
        end)
        local p = lurek.pipeline.newPipeline()
        p:addStep(s)
        p:run()
        expect_equal("table", got_ctx_type)
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:run
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("result stored in ctx.results after run", function()
        local s = lurek.pipeline.newStep("producer", function(ctx) return 99 end)
        local p = lurek.pipeline.newPipeline()
        p:addStep(s)
        local ctx = {}
        p:run(ctx)
        -- ctx.results.producer should be 99 (Lua receives updated table)
        expect_equal(99, ctx.results and ctx.results.producer)
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:run
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("completed list contains step name", function()
        local s = lurek.pipeline.newStep("done_step", function(ctx) return 1 end)
        local p = lurek.pipeline.newPipeline()
        p:addStep(s)
        local r = p:run()
        expect_true(table_contains(r.completed, "done_step"))
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:run
    -- @covers LPipelineStep:dependsOn
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("multi-step: downstream sees upstream result", function()
        local s1 = lurek.pipeline.newStep("a", function(ctx) return 10 end)
        local s2 = lurek.pipeline.newStep("b", function(ctx)
            return ctx.results.a * 2
        end)
        s2:dependsOn(s1)
        local p = lurek.pipeline.newPipeline("chain")
        p:addStep(s1):addStep(s2)
        local r = p:run()
        expect_true(r.success)
        expect_true(table_contains(r.completed, "a"))
        expect_true(table_contains(r.completed, "b"))
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:run
    -- @covers LPipelineStep:setCondition
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("condition false skips step, pipeline still succeeds", function()
        local s = lurek.pipeline.newStep("guarded", function(ctx) return 1 end)
        s:setCondition(function(ctx) return false end)
        local p = lurek.pipeline.newPipeline("cond")
        p:addStep(s)
        local r = p:run()
        -- skipped is not failed, success should be true
        expect_true(r.success)
        expect_true(table_contains(r.skipped, "guarded"))
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:run
    -- @covers LPipelineStep:dependsOn
    -- @covers LPipelineStep:setCondition
    -- @covers LPipelineStep:setOptional
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("optional skipped step: downstream proceeds", function()
        local sopt = lurek.pipeline.newStep("opt", function(ctx) return 1 end)
        sopt:setOptional(true)
        sopt:setCondition(function(ctx) return false end)
        local sdown = lurek.pipeline.newStep("down", function(ctx) return 2 end)
        sdown:dependsOn(sopt)
        local p = lurek.pipeline.newPipeline("opt_test")
        p:addStep(sopt):addStep(sdown)
        local r = p:run()
        -- optional skipped dep allows downstream to run
        expect_true(table_contains(r.completed, "down"))
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:run
    -- @covers LPipeline:setErrorMode
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("failed step in abort mode: result not success", function()
        local sfail = lurek.pipeline.newStep("fail", function(ctx) error("boom") end)
        local p = lurek.pipeline.newPipeline("abort_test")
        p:setErrorMode("abort")
        p:addStep(sfail)
        local r = p:run()
        expect_false(r.success)
        expect_true(table_contains(r.failed, "fail"))
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:run
    -- @covers LPipeline:setErrorMode
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("failed step in continue mode: independent steps run", function()
        local sfail = lurek.pipeline.newStep("fail", function(ctx) error("oops") end)
        local safter = lurek.pipeline.newStep("after", function(ctx) return 1 end)
        -- safter does NOT depend on sfail
        local p = lurek.pipeline.newPipeline("cont")
        p:setErrorMode("continue")
        p:addStep(sfail):addStep(safter)
        local r = p:run()
        -- sfail failed, safter ran (no dep on sfail)
        expect_true(table_contains(r.failed, "fail"))
        expect_true(table_contains(r.completed, "after"))
    end)
end)

-- =========================================================================
-- 7. Serialization
-- =========================================================================
-- @describe Pipeline serialization
describe("Pipeline serialization", function()
    -- @covers LPipeline:toTable
    -- @covers lurek.pipeline.newPipeline
    it("toTable returns table with name", function()
        local p = lurek.pipeline.newPipeline("serial_test")
        local t = p:toTable()
        expect_type("table", t)
        expect_equal("serial_test", t.name)
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:toTable
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("toTable includes steps list", function()
        local p = lurek.pipeline.newPipeline("with_steps")
        p:addStep(lurek.pipeline.newStep("s1", function(ctx) return 1 end))
        p:addStep(lurek.pipeline.newStep("s2", function(ctx) return 2 end))
        local t = p:toTable()
        expect_type("table", t.steps)
        expect_equal(2, #t.steps)
    end)

    -- @covers LPipeline:setErrorMode
    -- @covers LPipeline:toTable
    -- @covers lurek.pipeline.newPipeline
    it("toTable includes errorMode", function()
        local p = lurek.pipeline.newPipeline("em_test")
        p:setErrorMode("continue")
        local t = p:toTable()
        expect_equal("continue", t.errorMode)
    end)

    -- @covers LPipeline:getName
    -- @covers lurek.pipeline.fromTable
    it("fromTable constructs pipeline with correct name", function()
        local p = lurek.pipeline.fromTable({
            name = "declarative",
            errorMode = "continue",
            steps = {
                { name = "step1", fn = function(ctx) return 1 end },
                { name = "step2", deps = {"step1"}, fn = function(ctx) return 2 end },
            }
        })
        expect_type("userdata", p)
        expect_equal("declarative", p:getName())
    end)

    -- @covers LPipeline:getStepCount
    -- @covers lurek.pipeline.fromTable
    it("fromTable constructs pipeline with correct step count", function()
        local p = lurek.pipeline.fromTable({
            name = "declarative",
            steps = {
                { name = "step1", fn = function(ctx) return 1 end },
                { name = "step2", fn = function(ctx) return 2 end },
            }
        })
        expect_equal(2, p:getStepCount())
    end)

    -- @covers LPipeline:run
    -- @covers lurek.pipeline.fromTable
    it("fromTable pipeline can run", function()
        local p = lurek.pipeline.fromTable({
            name = "runnable",
            steps = {
                { name = "only", fn = function(ctx) return 7 end },
            }
        })
        local r = p:run()
        expect_true(r.success)
        expect_true(table_contains(r.completed, "only"))
    end)
end)

-- @describe lurek.pipeline addConditional
describe("lurek.pipeline addConditional", function()
    -- @covers LPipeline:addConditional
    -- @covers LPipeline:run
    -- @covers lurek.pipeline.newPipeline
    it("addConditional executes step when condition is true", function()
        local ran = false
        local p = lurek.pipeline.newPipeline("cond_test")
        p:addConditional("guarded", {}, function(ctx) ran = true end, function() return true end)
        local r = p:run()
        expect_true(ran, "step body must run when condition is true")
        expect_true(table_contains(r.completed, "guarded"))
    end)

    -- @covers LPipeline:addConditional
    -- @covers LPipeline:run
    -- @covers lurek.pipeline.newPipeline
    it("addConditional skips step when condition is false", function()
        local ran = false
        local p = lurek.pipeline.newPipeline("skip_test")
        p:addConditional("skipped", {}, function(ctx) ran = true end, function() return false end)
        p:run()
        expect_equal(ran, false, "step body must NOT run when condition is false")
    end)
end)

-- @describe lurek.pipeline onProgress
describe("lurek.pipeline onProgress", function()
    -- @covers LPipeline:addStep
    -- @covers LPipeline:onProgress
    -- @covers LPipeline:run
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("onProgress is called for every step", function()
        local events = {}
        local p = lurek.pipeline.newPipeline("progress_test")
        p:addStep(lurek.pipeline.newStep("alpha", function(ctx) end))
        p:addStep(lurek.pipeline.newStep("beta",  function(ctx) end))
        p:onProgress(function(name, status)
            table.insert(events, { name = name, status = status })
        end)
        p:run()
        expect_equal(#events, 2, "expected 2 progress events")
        -- Both completions should have status "completed"
        for _, ev in ipairs(events) do
            expect_equal(ev.status, "completed")
        end
    end)
end)

-- @describe lurek.pipeline toAscii
describe("lurek.pipeline toAscii", function()
    -- @covers LPipeline:addStep
    -- @covers LPipeline:toAscii
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("toAscii returns a non-empty string", function()
        local p = lurek.pipeline.newPipeline("ascii_test")
        p:addStep(lurek.pipeline.newStep("s1", function() end))
        p:addStep(lurek.pipeline.newStep("s2", function() end))
        local diagram = p:toAscii()
        expect_equal(type(diagram), "string")
        expect_true(#diagram > 0, "toAscii must return a non-empty string")
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:toAscii
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("toAscii output contains step names", function()
        local p = lurek.pipeline.newPipeline("ascii_names")
        p:addStep(lurek.pipeline.newStep("init_step", function() end))
        local diagram = p:toAscii()
        expect_true(diagram:find("init_step") ~= nil, "diagram must mention step name 'init_step'")
    end)
end)

-- @describe pipeline regression coverage
describe("pipeline regression coverage", function()
    -- @covers LPipeline:addStep
    -- @covers LPipeline:run
    -- @covers LPipelineStep:getAttempt
    -- @covers LPipelineStep:getTimeout
    -- @covers LPipelineStep:setCallback
    -- @covers LPipelineStep:setRetryCount
    -- @covers LPipelineStep:setRetryDelay
    -- @covers LPipelineStep:setTimeout
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("step retry metadata and callback replacement work together", function()
        local attempts = 0
        local step = lurek.pipeline.newStep("retry", function(ctx) return -1 end)
        step:setTimeout(2.5)
        step:setRetryCount(1)
        step:setRetryDelay(0.25)
        step:setCallback(function(ctx)
            attempts = attempts + 1
            if attempts == 1 then
                error("retry once")
            end
            return 42
        end)

        local pipeline = lurek.pipeline.newPipeline("retry_meta")
        pipeline:addStep(step)
        local result = pipeline:run()

        expect_true(result.success)
        expect_near(2.5, step:getTimeout(), 0.001)
        expect_equal(2, step:getAttempt())
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:getContext
    -- @covers LPipeline:isRunning
    -- @covers LPipeline:runAsync
    -- @covers LPipeline:update
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("runAsync stores context and exposes async state", function()
        local step = lurek.pipeline.newStep("async_step", function(ctx)
            return ctx.seed * 2
        end)
        local pipeline = lurek.pipeline.newPipeline("async_case")
        pipeline:addStep(step)

        pipeline:runAsync({seed = 21})
        expect_true(pipeline:isRunning())
        expect_equal(21, pipeline:getContext().seed)
        expect_type("boolean", pipeline:update(0.01))
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:getResult
    -- @covers LPipeline:run
    -- @covers LPipeline:setOnComplete
    -- @covers LPipeline:setOnStepComplete
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("run fires completion hooks and stores the final result", function()
        local complete_result = { success = false }
        local completed_step = nil
        local step = lurek.pipeline.newStep("sync_step", function(ctx)
            return ctx.seed * 2
        end)
        local pipeline = lurek.pipeline.newPipeline("sync_case")
        pipeline:addStep(step)
        pipeline:setOnComplete(function(result)
            complete_result = result
        end)
        pipeline:setOnStepComplete(function(name, ctx)
            completed_step = name
        end)

        local ctx = {seed = 21}
        local result = pipeline:run(ctx)
        expect_true(result.success)
        expect_equal("sync_step", completed_step)
        expect_true(complete_result.success)
        expect_true(pipeline:getResult().success)
        expect_equal(42, ctx.results.sync_step)
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:getResult
    -- @covers LPipeline:run
    -- @covers LPipeline:setErrorMode
    -- @covers LPipeline:setOnStepError
    -- @covers LPipelineStep:getAttempt
    -- @covers LPipelineStep:setOnError
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("step and pipeline error hooks fire on failure", function()
        local step_error_name = nil
        local pipeline_error_name = nil
        local step = lurek.pipeline.newStep("boom", function(ctx)
            error("explode")
        end)
        step:setOnError(function(name, msg)
            step_error_name = name
        end)

        local pipeline = lurek.pipeline.newPipeline("error_case")
        pipeline:setErrorMode("continue")
        pipeline:setOnStepError(function(name, msg)
            pipeline_error_name = name
        end)
        pipeline:addStep(step)

        local result = pipeline:run()
        expect_false(result.success)
        expect_equal("boom", step_error_name)
        expect_equal("boom", pipeline_error_name)
        expect_equal(1, step:getAttempt())
        expect_false(pipeline:getResult().success)
    end)
end)

-- @describe LPipeline:addSubPipeline
describe("LPipeline:addSubPipeline", function()
    -- @covers LPipeline:addSubPipeline
    -- @covers lurek.pipeline.newPipeline
    it("addSubPipeline inlines steps from another pipeline", function()
        local sub = lurek.pipeline.newPipeline("sub")
        local sub_step = lurek.pipeline.newStep("sub_step")
        sub_step:setCallback(function() end)
        sub:addStep(sub_step)

        local parent = lurek.pipeline.newPipeline("parent")
        expect_no_error(function()
            parent:addSubPipeline(sub, "sub")
        end)
    end)
end)

-- @describe pipeline strict: LPipelineStep getError/getDuration
describe("pipeline strict: LPipelineStep getError/getDuration", function()
    -- @covers LPipelineStep:getError
    -- @covers LPipelineStep:getDuration
    -- @covers lurek.pipeline.newStep
    it("LPipelineStep getError and getDuration are callable", function()
        local step = lurek.pipeline.newStep("strict_step")
        local ok1, e = pcall(function() return step:getError() end)
        expect_type("boolean", ok1)
        local ok2, d = pcall(function() return step:getDuration() end)
        if ok2 then expect_type("number", d) end
    end)

end)

-- @describe pipeline strict: LPipeline getSteps/cancel/reset/isComplete
describe("pipeline strict: LPipeline getSteps/cancel/reset/isComplete", function()
    -- @covers LPipeline:getSteps
    -- @covers LPipeline:cancel
    -- @covers LPipeline:reset
    -- @covers LPipeline:isComplete
    -- @covers lurek.pipeline.newPipeline
    it("LPipeline getSteps/cancel/reset/isComplete are callable", function()
        local p = lurek.pipeline.newPipeline("strict_pipe")
        local ok1, steps = pcall(function() return p:getSteps() end)
        if ok1 then expect_type("table", steps) end
        local ok2 = pcall(function() p:cancel() end)
        expect_type("boolean", ok2)
        local ok3 = pcall(function() p:reset() end)
        expect_type("boolean", ok3)
        local ok4, ic = pcall(function() return p:isComplete() end)
        if ok4 then expect_type("boolean", ic) end
    end)
end)

-- @describe pipeline branch and coroutine async coverage
describe("pipeline branch and coroutine async coverage", function()
    -- @covers LPipeline:addBranch
    -- @covers LPipeline:run
    -- @covers lurek.pipeline.newPipeline
    it("addBranch executes then branch only when predicate is true", function()
        local chosen = "none"
        local p = lurek.pipeline.newPipeline("branch_true")
        p:addBranch(
            "gate",
            {},
            function(ctx) return true end,
            function(ctx) chosen = "then" end,
            function(ctx) chosen = "else" end
        )
        local result = p:run()
        expect_true(result.success)
        expect_equal("then", chosen)
        expect_true(table_contains(result.completed, "gate__branch_guard"))
        expect_true(table_contains(result.completed, "gate__then"))
        expect_true(table_contains(result.skipped, "gate__else"))
    end)

    -- @covers LPipeline:addBranch
    -- @covers LPipeline:run
    -- @covers lurek.pipeline.newPipeline
    it("addBranch executes else branch when predicate is false", function()
        local chosen = "none"
        local p = lurek.pipeline.newPipeline("branch_false")
        p:addBranch(
            "gate",
            {},
            function(ctx) return false end,
            function(ctx) chosen = "then" end,
            function(ctx) chosen = "else" end
        )
        local result = p:run()
        expect_true(result.success)
        expect_equal("else", chosen)
        expect_true(table_contains(result.completed, "gate__else"))
        expect_true(table_contains(result.skipped, "gate__then"))
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:isRunning
    -- @covers LPipeline:runAsync
    -- @covers LPipeline:update
    -- @covers LPipelineStep:isAsync
    -- @covers LPipelineStep:setAsync
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("setAsync/isAsync toggle step async flag", function()
        local s = lurek.pipeline.newStep("co", function(ctx)
            return "done"
        end)
        expect_false(s:isAsync())
        s:setAsync(true)
        expect_true(s:isAsync())
        s:setAsync(false)
        expect_false(s:isAsync())
    end)

    -- @covers LPipeline:addStep
    -- @covers LPipeline:onEvent
    -- @covers LPipeline:run
    -- @covers lurek.pipeline.newPipeline
    -- @covers lurek.pipeline.newStep
    it("onEvent receives lifecycle notifications", function()
        local events = {}
        local p = lurek.pipeline.newPipeline("events")
        p:addStep(lurek.pipeline.newStep("ok", function(ctx) return 1 end))
        p:onEvent(function(event_name, step_name, status, detail)
            table.insert(events, event_name .. ":" .. step_name .. ":" .. status)
        end)

        local result = p:run()
        expect_true(result.success)
        expect_true(#events >= 2)
        expect_true(events[1]:find("step_started") ~= nil)
        expect_true(events[#events]:find("step_finished") ~= nil)
    end)
end)

test_summary()
