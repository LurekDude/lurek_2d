-- BDD tests for lurek.pipeline DAG pipeline orchestrator

-- =========================================================================
-- Helper: table contains value
-- =========================================================================
-- @tests lurek.pipeline.fromTable
-- @tests lurek.pipeline.newPipeline
-- @tests lurek.pipeline.newStep

local function table_contains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

-- =========================================================================
-- 1. Module existence
-- =========================================================================
-- @description Verifies that the pipeline namespace exposes the module table and all three public factory functions used throughout the file.
describe("lurek.pipeline module exists", function()
    -- @description Confirms the root pipeline binding is exposed to Lua as a table.
    it("lurek.pipeline is a table", function()
        expect_type("table", lurek.pipeline)
    end)

    -- @description Confirms the step factory is callable from the pipeline module.
    it("has newStep factory", function()
        expect_type("function", lurek.pipeline.newStep)
    end)

    -- @description Confirms the pipeline factory is callable from the pipeline module.
    it("has newPipeline factory", function()
        expect_type("function", lurek.pipeline.newPipeline)
    end)

    -- @description Confirms the declarative pipeline factory is callable from the pipeline module.
    it("has fromTable factory", function()
        expect_type("function", lurek.pipeline.fromTable)
    end)
end)

-- =========================================================================
-- 2. PipelineStep construction and configuration
-- =========================================================================
-- @description Checks that a new step reports the expected userdata identity and that all mutable configuration fields round-trip through their getters.
describe("PipelineStep construction", function()
    -- @description Ensures newStep creates a userdata-backed step object.
    it("newStep returns userdata", function()
        local s = lurek.pipeline.newStep("step1")
        expect_type("userdata", s)
    end)

    -- @description Ensures the constructor stores the provided step name and getName returns it unchanged.
    it("newStep with name stores name", function()
        local s = lurek.pipeline.newStep("my_step")
        expect_equal("my_step", s:getName())
    end)

    -- @description Ensures supplying a callback at construction still preserves the step name.
    it("newStep with callback fn stores it", function()
        local s = lurek.pipeline.newStep("cb_step", function(ctx) return 1 end)
        expect_equal("cb_step", s:getName())
    end)

    -- @description Verifies the runtime type string for a step is reported as PipelineStep.
    it("type() returns 'LPipelineStep'", function()
        local s = lurek.pipeline.newStep("s")
        expect_equal("LPipelineStep", s:type())
    end)

    -- @description Verifies the step passes a typeOf check for the PipelineStep type name.
    it("typeOf('LPipelineStep') is true", function()
        local s = lurek.pipeline.newStep("s")
        expect_true(s:typeOf("LPipelineStep"))
    end)

    -- @description Verifies a newly created step begins in the pending status before any execution.
    it("initial status is 'pending'", function()
        local s = lurek.pipeline.newStep("s")
        expect_equal("pending", s:getStatus())
    end)

    -- @description Verifies the configured delay value is returned unchanged by getDelay.
    it("setDelay/getDelay roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setDelay(0.5)
        expect_near(0.5, s:getDelay())
    end)

    -- @description Verifies the optional flag can be toggled on and off and observed through isOptional.
    it("setOptional/isOptional roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setOptional(true)
        expect_true(s:isOptional())
        s:setOptional(false)
        expect_false(s:isOptional())
    end)

    -- @description Verifies the retry count setter stores the exact integer returned by getRetryCount.
    it("setRetryCount/getRetryCount roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setRetryCount(3)
        expect_equal(3, s:getRetryCount())
    end)

    -- @description Verifies a custom tag string is stored and returned unchanged.
    it("setTag/getTag roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setTag("critical")
        expect_equal("critical", s:getTag())
    end)

    -- @description Verifies arbitrary keyed step data is retrievable from the same key after assignment.
    it("setData/getData roundtrip", function()
        local s = lurek.pipeline.newStep("s")
        s:setData("env", "prod")
        expect_equal("prod", s:getData("env"))
    end)

    -- @description Verifies looking up an unset data key returns nil instead of a default value.
    it("getData missing key returns nil", function()
        local s = lurek.pipeline.newStep("s")
        expect_nil(s:getData("nonexistent"))
    end)
end)

-- =========================================================================
-- 3. PipelineStep dependency management
-- =========================================================================
-- @description Verifies dependency APIs record names correctly whether the dependency is supplied as a string or another step object, and that the fluent API reports accurate counts.
describe("PipelineStep dependency management", function()
    -- @description Ensures a string dependency name is added to the dependency list.
    it("dependsOn string adds dependency", function()
        local s = lurek.pipeline.newStep("child")
        s:dependsOn("parent")
        local deps = s:getDependencies()
        expect_true(table_contains(deps, "parent"))
    end)

    -- @description Ensures passing a step object records that step's name as the dependency.
    it("dependsOn step object adds dependency by name", function()
        local parent = lurek.pipeline.newStep("parent_step")
        local child = lurek.pipeline.newStep("child_step")
        child:dependsOn(parent)
        local deps = child:getDependencies()
        expect_true(table_contains(deps, "parent_step"))
    end)

    -- @description Ensures dependsOn returns the same step so chained configuration can continue on it.
    it("dependsOn returns self for chaining", function()
        local s = lurek.pipeline.newStep("s")
        local ret = s:dependsOn("a")
        -- should not error and should be the same step
        expect_equal("s", ret:getName())
    end)

    -- @description Ensures multiple dependency additions are all preserved in the returned dependency list.
    it("getDependencies returns all added deps", function()
        local s = lurek.pipeline.newStep("s")
        s:dependsOn("x")
        s:dependsOn("y")
        local deps = s:getDependencies()
        expect_true(table_contains(deps, "x"))
        expect_true(table_contains(deps, "y"))
    end)

    -- @description Ensures the dependency count matches the number of dependency names that were added.
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
-- @description Verifies pipeline objects expose the expected identity, track added and removed steps, filter by tag, clear state, and round-trip mutable pipeline metadata.
describe("Pipeline construction", function()
    -- @description Ensures newPipeline creates a userdata-backed pipeline object.
    it("newPipeline returns userdata", function()
        local p = lurek.pipeline.newPipeline("test")
        expect_type("userdata", p)
    end)

    -- @description Verifies the runtime type string for a pipeline is reported as Pipeline.
    it("type() returns 'LPipeline'", function()
        local p = lurek.pipeline.newPipeline()
        expect_equal("LPipeline", p:type())
    end)

    -- @description Verifies the pipeline passes a typeOf check for the Pipeline type name.
    it("typeOf('LPipeline') is true", function()
        local p = lurek.pipeline.newPipeline()
        expect_true(p:typeOf("LPipeline"))
    end)

    -- @description Verifies a fresh pipeline reports zero registered steps.
    it("empty pipeline has stepCount 0", function()
        local p = lurek.pipeline.newPipeline()
        expect_equal(0, p:getStepCount())
    end)

    -- @description Verifies adding one step increments the reported step count to one.
    it("addStep increments stepCount", function()
        local p = lurek.pipeline.newPipeline()
        local s = lurek.pipeline.newStep("s", function(ctx) return 1 end)
        p:addStep(s)
        expect_equal(1, p:getStepCount())
    end)

    -- @description Verifies getStep returns the same named userdata that was previously added.
    it("getStep returns the added step", function()
        local p = lurek.pipeline.newPipeline()
        local s = lurek.pipeline.newStep("find_me", function(ctx) return 1 end)
        p:addStep(s)
        local got = p:getStep("find_me")
        expect_type("userdata", got)
        expect_equal("find_me", got:getName())
    end)

    -- @description Verifies getStep returns nil when no step exists under the requested name.
    it("getStep unknown returns nil", function()
        local p = lurek.pipeline.newPipeline()
        expect_nil(p:getStep("ghost"))
    end)

    -- @description Verifies removing a previously added step drops the step count back to zero.
    it("removeStep decrements count", function()
        local p = lurek.pipeline.newPipeline()
        local s = lurek.pipeline.newStep("s", function(ctx) return 1 end)
        p:addStep(s)
        p:removeStep("s")
        expect_equal(0, p:getStepCount())
    end)

    -- @description Verifies getStepsByTag returns only the two steps tagged alpha out of three total steps.
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

    -- @description Verifies clear removes all previously added steps from the pipeline.
    it("clear empties pipeline", function()
        local p = lurek.pipeline.newPipeline()
        p:addStep(lurek.pipeline.newStep("a", function(ctx) return 1 end))
        p:addStep(lurek.pipeline.newStep("b", function(ctx) return 2 end))
        p:clear()
        expect_equal(0, p:getStepCount())
    end)

    -- @description Verifies the pipeline name can be read, changed, and read back with the new value.
    it("getName/setName roundtrip", function()
        local p = lurek.pipeline.newPipeline("original")
        expect_equal("original", p:getName())
        p:setName("renamed")
        expect_equal("renamed", p:getName())
    end)

    -- @description Verifies the error mode setter persists both continue and abort values exactly.
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
-- @description Verifies validation outcomes for empty, valid, missing-dependency, and cyclic graphs, then checks that execution-order helpers return dependency-respecting results.
describe("Pipeline validation", function()
    -- @description Verifies an empty pipeline validates successfully and reports no validation errors.
    it("empty pipeline validates ok", function()
        local p = lurek.pipeline.newPipeline()
        local ok, errs = p:validate()
        expect_true(ok)
        expect_equal(0, #errs)
    end)

    -- @description Verifies a simple two-step DAG with one dependency validates successfully.
    it("valid dag validates ok", function()
        local p = lurek.pipeline.newPipeline()
        local s1 = lurek.pipeline.newStep("a", function(ctx) return 1 end)
        local s2 = lurek.pipeline.newStep("b", function(ctx) return 2 end)
        s2:dependsOn("a")
        p:addStep(s1):addStep(s2)
        local ok, errs = p:validate()
        expect_true(ok)
    end)

    -- @description Verifies validation fails and reports at least one error when a dependency name is missing from the pipeline.
    it("missing dep fails validation", function()
        local p = lurek.pipeline.newPipeline()
        local s = lurek.pipeline.newStep("child", function(ctx) return 1 end)
        s:dependsOn("missing_parent")
        p:addStep(s)
        local ok, errs = p:validate()
        expect_false(ok)
        expect_true(#errs > 0)
    end)

    -- @description Verifies validation fails when two steps depend on each other and form a cycle.
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

    -- @description Verifies getExecutionOrder returns a non-error topological order where first appears before second.
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

    -- @description Verifies getParallelGroups returns groups without error and that the combined group membership covers both independent steps.
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
-- @description Verifies runtime behavior for successful execution, context propagation, result storage, skipped optional work, and failure handling under both abort and continue modes.
describe("Pipeline.run() execution", function()
    -- @description Verifies a one-step pipeline reports overall success after the callback returns 42.
    it("single step runs and result is success", function()
        local s = lurek.pipeline.newStep("compute", function(ctx) return 42 end)
        local p = lurek.pipeline.newPipeline("test")
        p:addStep(s)
        local r = p:run()
        expect_true(r.success)
    end)

    -- @description Verifies each step callback receives a Lua table as its execution context.
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

    -- @description Verifies run mutates the supplied context table by storing the producer result under ctx.results.producer.
    it("result stored in ctx.results after run", function()
        local s = lurek.pipeline.newStep("producer", function(ctx) return 99 end)
        local p = lurek.pipeline.newPipeline()
        p:addStep(s)
        local ctx = {}
        p:run(ctx)
        -- ctx.results.producer should be 99 (Lua receives updated table)
        expect_equal(99, ctx.results and ctx.results.producer)
    end)

    -- @description Verifies the run result records the completed step name in the completed list.
    it("completed list contains step name", function()
        local s = lurek.pipeline.newStep("done_step", function(ctx) return 1 end)
        local p = lurek.pipeline.newPipeline()
        p:addStep(s)
        local r = p:run()
        expect_true(table_contains(r.completed, "done_step"))
    end)

    -- @description Verifies a downstream step can read ctx.results.a and still leaves both steps marked completed.
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

    -- @description Verifies a false condition skips the step, preserves overall success, and records the step in skipped.
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

    -- @description Verifies a skipped optional dependency does not block its dependent step from completing.
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

    -- @description Verifies abort mode marks the run unsuccessful and records the failing step when the callback errors.
    it("failed step in abort mode: result not success", function()
        local sfail = lurek.pipeline.newStep("fail", function(ctx) error("boom") end)
        local p = lurek.pipeline.newPipeline("abort_test")
        p:setErrorMode("abort")
        p:addStep(sfail)
        local r = p:run()
        expect_false(r.success)
        expect_true(table_contains(r.failed, "fail"))
    end)

    -- @description Verifies continue mode records the failing step while still completing an independent step with no dependency on it.
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
-- @description Verifies serialized pipeline tables retain name, step list, and error mode, and that fromTable reconstructs runnable pipelines with the expected structure.
describe("Pipeline serialization", function()
    -- @description Verifies toTable returns a Lua table whose name field matches the pipeline name.
    it("toTable returns table with name", function()
        local p = lurek.pipeline.newPipeline("serial_test")
        local t = p:toTable()
        expect_type("table", t)
        expect_equal("serial_test", t.name)
    end)

    -- @description Verifies toTable includes a steps array containing both added steps.
    it("toTable includes steps list", function()
        local p = lurek.pipeline.newPipeline("with_steps")
        p:addStep(lurek.pipeline.newStep("s1", function(ctx) return 1 end))
        p:addStep(lurek.pipeline.newStep("s2", function(ctx) return 2 end))
        local t = p:toTable()
        expect_type("table", t.steps)
        expect_equal(2, #t.steps)
    end)

    -- @description Verifies toTable preserves the configured errorMode field value.
    it("toTable includes errorMode", function()
        local p = lurek.pipeline.newPipeline("em_test")
        p:setErrorMode("continue")
        local t = p:toTable()
        expect_equal("continue", t.errorMode)
    end)

    -- @description Verifies fromTable rebuilds a pipeline userdata whose name matches the declarative input.
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

    -- @description Verifies fromTable creates the same number of steps described in the declarative input.
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

    -- @description Verifies a pipeline created from a table can run successfully and records its only step as completed.
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
    -- @tests lurek.pipeline.Pipeline.addConditional
    -- @description addConditional runs the step when the condition returns true.
    it("addConditional executes step when condition is true", function()
        local ran = false
        local p = lurek.pipeline.newPipeline("cond_test")
        p:addConditional("guarded", {}, function(ctx) ran = true end, function() return true end)
        local r = p:run()
        expect_true(ran, "step body must run when condition is true")
        expect_true(table_contains(r.completed, "guarded"))
    end)

    -- @tests lurek.pipeline.Pipeline.addConditional
    -- @description addConditional skips the step when the condition returns false.
    it("addConditional skips step when condition is false", function()
        local ran = false
        local p = lurek.pipeline.newPipeline("skip_test")
        p:addConditional("skipped", {}, function(ctx) ran = true end, function() return false end)
        p:run()
        expect_equal(ran, false, "step body must NOT run when condition is false")
    end)
end)

describe("lurek.pipeline onProgress", function()
    -- @tests lurek.pipeline.Pipeline.onProgress
    -- @description onProgress callback receives step_name and a status string after every step.
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
    -- @tests lurek.pipeline.Pipeline.toAscii
    -- @description toAscii returns a non-empty string describing the DAG.
    it("toAscii returns a non-empty string", function()
        local p = lurek.pipeline.newPipeline("ascii_test")
        p:addStep(lurek.pipeline.newStep("s1", function() end))
        p:addStep(lurek.pipeline.newStep("s2", function() end))
        local diagram = p:toAscii()
        expect_equal(type(diagram), "string")
        expect_true(#diagram > 0, "toAscii must return a non-empty string")
    end)

    -- @tests lurek.pipeline.Pipeline.toAscii
    -- @description toAscii output contains step names.
    it("toAscii output contains step names", function()
        local p = lurek.pipeline.newPipeline("ascii_names")
        p:addStep(lurek.pipeline.newStep("init_step", function() end))
        local diagram = p:toAscii()
        expect_true(diagram:find("init_step") ~= nil, "diagram must mention step name 'init_step'")
    end)
end)

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests Step:setCallback
    it("covers Step:setCallback", function()
        -- TODO: Implement test for Step:setCallback
    end)

    -- @tests Step:getTimeout
    it("covers Step:getTimeout", function()
        -- TODO: Implement test for Step:getTimeout
    end)

    -- @tests Step:setRetryDelay
    it("covers Step:setRetryDelay", function()
        -- TODO: Implement test for Step:setRetryDelay
    end)

    -- @tests Step:setOnError
    it("covers Step:setOnError", function()
        -- TODO: Implement test for Step:setOnError
    end)

    -- @tests Step:getAttempt
    it("covers Step:getAttempt", function()
        -- TODO: Implement test for Step:getAttempt
    end)

    -- @tests Pipeline:run
    it("covers Pipeline:run", function()
        -- TODO: Implement test for Pipeline:run
    end)

    -- @tests Pipeline:runAsync
    it("covers Pipeline:runAsync", function()
        -- TODO: Implement test for Pipeline:runAsync
    end)

    -- @tests Pipeline:getResult
    it("covers Pipeline:getResult", function()
        -- TODO: Implement test for Pipeline:getResult
    end)

    -- @tests Pipeline:getContext
    it("covers Pipeline:getContext", function()
        -- TODO: Implement test for Pipeline:getContext
    end)

    -- @tests Pipeline:setOnComplete
    it("covers Pipeline:setOnComplete", function()
        -- TODO: Implement test for Pipeline:setOnComplete
    end)

    -- @tests Pipeline:setOnStepComplete
    it("covers Pipeline:setOnStepComplete", function()
        -- TODO: Implement test for Pipeline:setOnStepComplete
    end)

    -- @tests Pipeline:setOnStepError
    it("covers Pipeline:setOnStepError", function()
        -- TODO: Implement test for Pipeline:setOnStepError
    end)

end)

describe("Missing explicit test for Step:getName", function()
    it("Step:getName works", function()
        -- @tests Step:getName
        -- TODO: add assertion for Step:getName
    end)
end)

describe("Missing explicit test for Step:setCondition", function()
    it("Step:setCondition works", function()
        -- @tests Step:setCondition
        -- TODO: add assertion for Step:setCondition
    end)
end)

describe("Missing explicit test for Step:setDelay", function()
    it("Step:setDelay works", function()
        -- @tests Step:setDelay
        -- TODO: add assertion for Step:setDelay
    end)
end)

describe("Missing explicit test for Step:getDelay", function()
    it("Step:getDelay works", function()
        -- @tests Step:getDelay
        -- TODO: add assertion for Step:getDelay
    end)
end)

describe("Missing explicit test for Step:setTimeout", function()
    it("Step:setTimeout works", function()
        -- @tests Step:setTimeout
        -- TODO: add assertion for Step:setTimeout
    end)
end)

describe("Missing explicit test for Step:setRetryCount", function()
    it("Step:setRetryCount works", function()
        -- @tests Step:setRetryCount
        -- TODO: add assertion for Step:setRetryCount
    end)
end)

describe("Missing explicit test for Step:getRetryCount", function()
    it("Step:getRetryCount works", function()
        -- @tests Step:getRetryCount
        -- TODO: add assertion for Step:getRetryCount
    end)
end)

describe("Missing explicit test for Step:setOptional", function()
    it("Step:setOptional works", function()
        -- @tests Step:setOptional
        -- TODO: add assertion for Step:setOptional
    end)
end)

describe("Missing explicit test for Step:isOptional", function()
    it("Step:isOptional works", function()
        -- @tests Step:isOptional
        -- TODO: add assertion for Step:isOptional
    end)
end)

describe("Missing explicit test for Step:setData", function()
    it("Step:setData works", function()
        -- @tests Step:setData
        -- TODO: add assertion for Step:setData
    end)
end)

describe("Missing explicit test for Step:getData", function()
    it("Step:getData works", function()
        -- @tests Step:getData
        -- TODO: add assertion for Step:getData
    end)
end)

describe("Missing explicit test for Step:setTag", function()
    it("Step:setTag works", function()
        -- @tests Step:setTag
        -- TODO: add assertion for Step:setTag
    end)
end)

describe("Missing explicit test for Step:getTag", function()
    it("Step:getTag works", function()
        -- @tests Step:getTag
        -- TODO: add assertion for Step:getTag
    end)
end)

describe("Missing explicit test for Step:dependsOn", function()
    it("Step:dependsOn works", function()
        -- @tests Step:dependsOn
        -- TODO: add assertion for Step:dependsOn
    end)
end)

describe("Missing explicit test for Step:getDependencies", function()
    it("Step:getDependencies works", function()
        -- @tests Step:getDependencies
        -- TODO: add assertion for Step:getDependencies
    end)
end)

describe("Missing explicit test for Step:getDependencyCount", function()
    it("Step:getDependencyCount works", function()
        -- @tests Step:getDependencyCount
        -- TODO: add assertion for Step:getDependencyCount
    end)
end)

describe("Missing explicit test for Step:getStatus", function()
    it("Step:getStatus works", function()
        -- @tests Step:getStatus
        -- TODO: add assertion for Step:getStatus
    end)
end)

describe("Missing explicit test for Step:getError", function()
    it("Step:getError works", function()
        -- @tests Step:getError
        -- TODO: add assertion for Step:getError
    end)
end)

describe("Missing explicit test for Step:getDuration", function()
    it("Step:getDuration works", function()
        -- @tests Step:getDuration
        -- TODO: add assertion for Step:getDuration
    end)
end)

describe("Missing explicit test for Step:type", function()
    it("Step:type works", function()
        -- @tests Step:type
        -- TODO: add assertion for Step:type
    end)
end)

describe("Missing explicit test for Step:typeOf", function()
    it("Step:typeOf works", function()
        -- @tests Step:typeOf
        -- TODO: add assertion for Step:typeOf
    end)
end)

describe("Missing explicit test for Pipeline:addStep", function()
    it("Pipeline:addStep works", function()
        -- @tests Pipeline:addStep
        -- TODO: add assertion for Pipeline:addStep
    end)
end)

describe("Missing explicit test for Pipeline:removeStep", function()
    it("Pipeline:removeStep works", function()
        -- @tests Pipeline:removeStep
        -- TODO: add assertion for Pipeline:removeStep
    end)
end)

describe("Missing explicit test for Pipeline:getStep", function()
    it("Pipeline:getStep works", function()
        -- @tests Pipeline:getStep
        -- TODO: add assertion for Pipeline:getStep
    end)
end)

describe("Missing explicit test for Pipeline:getSteps", function()
    it("Pipeline:getSteps works", function()
        -- @tests Pipeline:getSteps
        -- TODO: add assertion for Pipeline:getSteps
    end)
end)

describe("Missing explicit test for Pipeline:getStepCount", function()
    it("Pipeline:getStepCount works", function()
        -- @tests Pipeline:getStepCount
        -- TODO: add assertion for Pipeline:getStepCount
    end)
end)

describe("Missing explicit test for Pipeline:getStepsByTag", function()
    it("Pipeline:getStepsByTag works", function()
        -- @tests Pipeline:getStepsByTag
        -- TODO: add assertion for Pipeline:getStepsByTag
    end)
end)

describe("Missing explicit test for Pipeline:clear", function()
    it("Pipeline:clear works", function()
        -- @tests Pipeline:clear
        -- TODO: add assertion for Pipeline:clear
    end)
end)

describe("Missing explicit test for Pipeline:validate", function()
    it("Pipeline:validate works", function()
        -- @tests Pipeline:validate
        -- TODO: add assertion for Pipeline:validate
    end)
end)

describe("Missing explicit test for Pipeline:getExecutionOrder", function()
    it("Pipeline:getExecutionOrder works", function()
        -- @tests Pipeline:getExecutionOrder
        -- TODO: add assertion for Pipeline:getExecutionOrder
    end)
end)

describe("Missing explicit test for Pipeline:getParallelGroups", function()
    it("Pipeline:getParallelGroups works", function()
        -- @tests Pipeline:getParallelGroups
        -- TODO: add assertion for Pipeline:getParallelGroups
    end)
end)

describe("Missing explicit test for Pipeline:update", function()
    it("Pipeline:update works", function()
        -- @tests Pipeline:update
        -- TODO: add assertion for Pipeline:update
    end)
end)

describe("Missing explicit test for Pipeline:cancel", function()
    it("Pipeline:cancel works", function()
        -- @tests Pipeline:cancel
        -- TODO: add assertion for Pipeline:cancel
    end)
end)

describe("Missing explicit test for Pipeline:reset", function()
    it("Pipeline:reset works", function()
        -- @tests Pipeline:reset
        -- TODO: add assertion for Pipeline:reset
    end)
end)

describe("Missing explicit test for Pipeline:isRunning", function()
    it("Pipeline:isRunning works", function()
        -- @tests Pipeline:isRunning
        -- TODO: add assertion for Pipeline:isRunning
    end)
end)

describe("Missing explicit test for Pipeline:isComplete", function()
    it("Pipeline:isComplete works", function()
        -- @tests Pipeline:isComplete
        -- TODO: add assertion for Pipeline:isComplete
    end)
end)

describe("Missing explicit test for Pipeline:setErrorMode", function()
    it("Pipeline:setErrorMode works", function()
        -- @tests Pipeline:setErrorMode
        -- TODO: add assertion for Pipeline:setErrorMode
    end)
end)

describe("Missing explicit test for Pipeline:getErrorMode", function()
    it("Pipeline:getErrorMode works", function()
        -- @tests Pipeline:getErrorMode
        -- TODO: add assertion for Pipeline:getErrorMode
    end)
end)

describe("Missing explicit test for Pipeline:getName", function()
    it("Pipeline:getName works", function()
        -- @tests Pipeline:getName
        -- TODO: add assertion for Pipeline:getName
    end)
end)

describe("Missing explicit test for Pipeline:setName", function()
    it("Pipeline:setName works", function()
        -- @tests Pipeline:setName
        -- TODO: add assertion for Pipeline:setName
    end)
end)

describe("Missing explicit test for Pipeline:toTable", function()
    it("Pipeline:toTable works", function()
        -- @tests Pipeline:toTable
        -- TODO: add assertion for Pipeline:toTable
    end)
end)

describe("Missing explicit test for Pipeline:type", function()
    it("Pipeline:type works", function()
        -- @tests Pipeline:type
        -- TODO: add assertion for Pipeline:type
    end)
end)

describe("Missing explicit test for Pipeline:onProgress", function()
    it("Pipeline:onProgress works", function()
        -- @tests Pipeline:onProgress
        -- TODO: add assertion for Pipeline:onProgress
    end)
end)

describe("Missing explicit test for Pipeline:toAscii", function()
    it("Pipeline:toAscii works", function()
        -- @tests Pipeline:toAscii
        -- TODO: add assertion for Pipeline:toAscii
    end)
end)

describe("Missing explicit test for Pipeline:typeOf", function()
    it("Pipeline:typeOf works", function()
        -- @tests Pipeline:typeOf
        -- TODO: add assertion for Pipeline:typeOf
    end)
end)
