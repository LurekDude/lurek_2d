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
describe("lurek.pipeline module exists", function()
    it("lurek.pipeline is a table", function()
        expect_type("table", lurek.pipeline)
    end)

    it("has newStep factory", function()
        expect_type("function", lurek.pipeline.newStep)
    end)

    it("has newPipeline factory", function()
        expect_type("function", lurek.pipeline.newPipeline)
    end)

    it("has fromTable factory", function()
        expect_type("function", lurek.pipeline.fromTable)
    end)
end)

-- =========================================================================
-- 2. PipelineStep construction and configuration
-- =========================================================================
describe("PipelineStep construction", function()
    it("newStep returns userdata", function()
        local s = lurek.pipeline.newStep("step1")
        expect_type("userdata", s)
    end)

    it("newStep with name stores name", function()
        local s = lurek.pipeline.newStep("my_step")
        expect_equal("my_step", s:getName())
    end)

    it("newStep with callback fn stores it", function()
        local s = lurek.pipeline.newStep("cb_step", function(ctx) return 1 end)
        expect_equal("cb_step", s:getName())
    end)

    it("type() returns 'LPipelineStep'", function()
        local s = lurek.pipeline.newStep("s")
        expect_equal("LPipelineStep", s:type())
    end)

    it("typeOf('LPipelineStep') is true", function()
        local s = lurek.pipeline.newStep("s")
        expect_true(s:typeOf("LPipelineStep"))
    end)

    it("initial status is 'pending'", function()
        local s = lurek.pipeline.newStep("s")
        expect_equal("pending", s:getStatus())
    end)

    it("setDelay/getDelay roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setDelay(0.5)
        expect_near(0.5, s:getDelay())
    end)

    it("setOptional/isOptional roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setOptional(true)
        expect_true(s:isOptional())
        s:setOptional(false)
        expect_false(s:isOptional())
    end)

    it("setRetryCount/getRetryCount roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setRetryCount(3)
        expect_equal(3, s:getRetryCount())
    end)

    it("setTag/getTag roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setTag("critical")
        expect_equal("critical", s:getTag())
    end)

    it("setData/getData roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setData("env", "prod")
        expect_equal("prod", s:getData("env"))
    end)

    it("getData missing key returns nil", function()
        local s = lurek.pipeline.newStep("s")
        expect_nil(s:getData("nonexistent"))
    end)
end)

-- =========================================================================
-- 3. PipelineStep dependency management
-- =========================================================================
describe("PipelineStep dependency management", function()
    it("dependsOn string adds dependency", function()
        local s = lurek.pipeline.newStep("child")
        s:dependsOn("parent")
        local deps = s:getDependencies()
        expect_true(table_contains(deps, "parent"))
    end)

    it("dependsOn step object adds dependency by name", function()
        local parent = lurek.pipeline.newStep("parent_step")
        local child = lurek.pipeline.newStep("child_step")
        child:dependsOn(parent)
        local deps = child:getDependencies()
        expect_true(table_contains(deps, "parent_step"))
    end)

    it("dependsOn returns self for chaining", function()
        local s = lurek.pipeline.newStep("s")
        local ret = s:dependsOn("a")
        -- should not error and should be the same step
        expect_equal("s", ret:getName())
    end)

    it("getDependencies returns all added deps", function()
        local s = lurek.pipeline.newStep("s")
        s:dependsOn("x")
        s:dependsOn("y")
        local deps = s:getDependencies()
        expect_true(table_contains(deps, "x"))
        expect_true(table_contains(deps, "y"))
    end)

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
describe("Pipeline construction", function()
    it("newPipeline returns userdata", function()
        local p = lurek.pipeline.newPipeline("test")
        expect_type("userdata", p)
    end)

    it("type() returns 'LPipeline'", function()
        local p = lurek.pipeline.newPipeline()
        expect_equal("LPipeline", p:type())
    end)

    it("typeOf('LPipeline') is true", function()
        local p = lurek.pipeline.newPipeline()
        expect_true(p:typeOf("LPipeline"))
    end)

    it("empty pipeline has stepCount 0", function()
        local p = lurek.pipeline.newPipeline()
        expect_equal(0, p:getStepCount())
    end)

    it("addStep increments stepCount", function()
        local p = lurek.pipeline.newPipeline()
        local s = lurek.pipeline.newStep("s", function(ctx) return 1 end)
        p:addStep(s)
        expect_equal(1, p:getStepCount())
    end)

    it("getStep returns the added step", function()
        local p = lurek.pipeline.newPipeline()
        local s = lurek.pipeline.newStep("find_me", function(ctx) return 1 end)
        p:addStep(s)
        local got = p:getStep("find_me")
        expect_type("userdata", got)
        expect_equal("find_me", got:getName())
    end)

    it("getStep unknown returns nil", function()
        local p = lurek.pipeline.newPipeline()
        expect_nil(p:getStep("ghost"))
    end)

    it("removeStep decrements count", function()
        local p = lurek.pipeline.newPipeline()
        local s = lurek.pipeline.newStep("s", function(ctx) return 1 end)
        p:addStep(s)
        p:removeStep("s")
        expect_equal(0, p:getStepCount())
    end)

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

    it("clear empties pipeline", function()
        local p = lurek.pipeline.newPipeline()
        p:addStep(lurek.pipeline.newStep("a", function(ctx) return 1 end))
        p:addStep(lurek.pipeline.newStep("b", function(ctx) return 2 end))
        p:clear()
        expect_equal(0, p:getStepCount())
    end)

    it("getName/setName roundtrip", function()
        local p = lurek.pipeline.newPipeline("original")
        expect_equal("original", p:getName())
        p:setName("renamed")
        expect_equal("renamed", p:getName())
    end)

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
describe("Pipeline validation", function()
    it("empty pipeline validates ok", function()
        local p = lurek.pipeline.newPipeline()
        local ok, errs = p:validate()
        expect_true(ok)
        expect_equal(0, #errs)
    end)

    it("valid dag validates ok", function()
        local p = lurek.pipeline.newPipeline()
        local s1 = lurek.pipeline.newStep("a", function(ctx) return 1 end)
        local s2 = lurek.pipeline.newStep("b", function(ctx) return 2 end)
        s2:dependsOn("a")
        p:addStep(s1):addStep(s2)
        local ok, errs = p:validate()
        expect_true(ok)
    end)

    it("missing dep fails validation", function()
        local p = lurek.pipeline.newPipeline()
        local s = lurek.pipeline.newStep("child", function(ctx) return 1 end)
        s:dependsOn("missing_parent")
        p:addStep(s)
        local ok, errs = p:validate()
        expect_false(ok)
        expect_true(#errs > 0)
    end)

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
describe("Pipeline.run() execution", function()
    it("single step runs and result is success", function()
        local s = lurek.pipeline.newStep("compute", function(ctx) return 42 end)
        local p = lurek.pipeline.newPipeline("test")
        p:addStep(s)
        local r = p:run()
        expect_true(r.success)
    end)

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

    it("result stored in ctx.results after run", function()
        local s = lurek.pipeline.newStep("producer", function(ctx) return 99 end)
        local p = lurek.pipeline.newPipeline()
        p:addStep(s)
        local ctx = {}
        p:run(ctx)
        -- ctx.results.producer should be 99 (Lua receives updated table)
        expect_equal(99, ctx.results and ctx.results.producer)
    end)

    it("completed list contains step name", function()
        local s = lurek.pipeline.newStep("done_step", function(ctx) return 1 end)
        local p = lurek.pipeline.newPipeline()
        p:addStep(s)
        local r = p:run()
        expect_true(table_contains(r.completed, "done_step"))
    end)

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

    it("failed step in abort mode: result not success", function()
        local sfail = lurek.pipeline.newStep("fail", function(ctx) error("boom") end)
        local p = lurek.pipeline.newPipeline("abort_test")
        p:setErrorMode("abort")
        p:addStep(sfail)
        local r = p:run()
        expect_false(r.success)
        expect_true(table_contains(r.failed, "fail"))
    end)

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
describe("Pipeline serialization", function()
    it("toTable returns table with name", function()
        local p = lurek.pipeline.newPipeline("serial_test")
        local t = p:toTable()
        expect_type("table", t)
        expect_equal("serial_test", t.name)
    end)

    it("toTable includes steps list", function()
        local p = lurek.pipeline.newPipeline("with_steps")
        p:addStep(lurek.pipeline.newStep("s1", function(ctx) return 1 end))
        p:addStep(lurek.pipeline.newStep("s2", function(ctx) return 2 end))
        local t = p:toTable()
        expect_type("table", t.steps)
        expect_equal(2, #t.steps)
    end)

    it("toTable includes errorMode", function()
        local p = lurek.pipeline.newPipeline("em_test")
        p:setErrorMode("continue")
        local t = p:toTable()
        expect_equal("continue", t.errorMode)
    end)

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

describe("lurek.pipeline addConditional", function()
    it("addConditional executes step when condition is true", function()
        local ran = false
        local p = lurek.pipeline.newPipeline("cond_test")
        p:addConditional("guarded", {}, function(ctx) ran = true end, function() return true end)
        local r = p:run()
        expect_true(ran, "step body must run when condition is true")
        expect_true(table_contains(r.completed, "guarded"))
    end)

    it("addConditional skips step when condition is false", function()
        local ran = false
        local p = lurek.pipeline.newPipeline("skip_test")
        p:addConditional("skipped", {}, function(ctx) ran = true end, function() return false end)
        p:run()
        expect_equal(ran, false, "step body must NOT run when condition is false")
    end)
end)

describe("lurek.pipeline onProgress", function()
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

describe("lurek.pipeline toAscii", function()
    it("toAscii returns a non-empty string", function()
        local p = lurek.pipeline.newPipeline("ascii_test")
        p:addStep(lurek.pipeline.newStep("s1", function() end))
        p:addStep(lurek.pipeline.newStep("s2", function() end))
        local diagram = p:toAscii()
        expect_equal(type(diagram), "string")
        expect_true(#diagram > 0, "toAscii must return a non-empty string")
    end)

    it("toAscii output contains step names", function()
        local p = lurek.pipeline.newPipeline("ascii_names")
        p:addStep(lurek.pipeline.newStep("init_step", function() end))
        local diagram = p:toAscii()
        expect_true(diagram:find("init_step") ~= nil, "diagram must mention step name 'init_step'")
    end)
end)

describe("pipeline regression coverage", function()
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
test_summary()
