-- Integration test: library.quest    lurek.timer.Scheduler.
--
-- Scope: Drives quest progression and failure from a `lurek.timer.Scheduler`
-- userdata. Demonstrates the recommended pattern from `library/quest/init.lua`
-- (see its top-of-file note about time-limited objectives): the library does
-- NOT depend on `lurek.timer` directly; the game loop creates a Scheduler and
-- the scheduler callback calls `QuestLog:failQuest(id)` or
-- `QuestLog:advanceObjective(...)`.
--
-- Fallback: none. `lurek.timer.newScheduler` is gated by `modules.timer`
-- (default true) and works headless. The "lurek.timer" name (NOT
-- "lurek.timer") is the runtime namespace per P1 map.
--

local quest = require("library.quest")

local function build_log_with_quest(qid, deadline_obj_required)
    local log = quest.newQuestLog()
    local q = quest.newQuest(qid, qid)
    local s = quest.newQuestStage("s1", "Stage 1")
    s:addObjective(quest.newObjective("collect", "Collect items",
        deadline_obj_required or 5))
    q:addStage(s)
    log:addQuest(q)
    log:startQuest(qid)
    return log, q
end

describe("integration: library.quest    lurek.timer.Scheduler", function()

    it("scheduler:after deadline auto-fails an active quest", function()
        local log, q = build_log_with_quest("ticking")
        local sched = lurek.timer.newScheduler()

        sched:after(2.0, function() log:failQuest("ticking") end)

        sched:update(1.0)
        expect_equal("active", q.status)
        sched:update(1.5)
        expect_equal("failed", q.status)
    end)

    it("scheduler:every advances objective progress and completes it", function()
        local log = quest.newQuestLog()
        local q = quest.newQuest("hunt", "Hunt")
        local stage = quest.newQuestStage("s", "S")
        stage:addObjective(quest.newObjective("kills", "Slay foes", 3))
        q:addStage(stage)
        log:addQuest(q)
        log:startQuest("hunt")

        local sched = lurek.timer.newScheduler()
        sched:every(1.0, function()
            log:advanceObjective("hunt", "kills", 1)
        end, 3)

        sched:update(1.0); sched:update(1.0); sched:update(1.0)
        expect_equal(3, stage:getObjective("kills").current)
        expect_true(stage:getObjective("kills"):isComplete())
    end)

    it("cancel aborts the deadline and the quest stays active", function()
        local log, q = build_log_with_quest("cancellable")
        local sched = lurek.timer.newScheduler()

        local id = sched:after(1.0, function() log:failQuest("cancellable") end)
        local ok = sched:cancel(id)
        expect_true(ok)
        sched:update(2.0)
        expect_equal("active", q.status)
        expect_equal(0, sched:getCount())
    end)

    -- resuming lets it fire after the remaining wall time elapses.
    it("pause and resume preserves the remaining deadline window", function()
        local log, q = build_log_with_quest("pausable")
        local sched = lurek.timer.newScheduler()
        local id = sched:after(1.0, function() log:failQuest("pausable") end)

        sched:update(0.4)
        sched:pause(id)
        sched:update(5.0)
        expect_equal("active", q.status)
        sched:resume(id)
        sched:update(0.7)
        expect_equal("failed", q.status)
    end)

    it("zero-delay deadline fires on the next update", function()
        local log, q = build_log_with_quest("instant")
        local sched = lurek.timer.newScheduler()
        sched:after(0.0, function() log:failQuest("instant") end)
        sched:update(0.0001)
        expect_equal("failed", q.status)
    end)

    it("scheduler:after rejects a non-function callback", function()
        local sched = lurek.timer.newScheduler()
        expect_error(function()
            sched:after(1.0, "not a function")
        end)
    end)

end)




-- ================================================================
-- Merged from: test_integration_quest_time.lua
-- ================================================================

-- Integration test: library.quest    lurek.timer.Scheduler.
--
-- Scope: Drives quest progression and failure from a `lurek.timer.Scheduler`
-- userdata. Demonstrates the recommended pattern from `library/quest/init.lua`
-- (see its top-of-file note about time-limited objectives): the library does
-- NOT depend on `lurek.timer` directly; the game loop creates a Scheduler and
-- the scheduler callback calls `QuestLog:failQuest(id)` or
-- `QuestLog:advanceObjective(...)`.
--
-- Fallback: none. `lurek.timer.newScheduler` is gated by `modules.timer`
-- (default true) and works headless. The "lurek.timer" name (NOT
-- "lurek.timer") is the runtime namespace per P1 map.
--

local quest = require("library.quest")

local function build_log_with_quest(qid, deadline_obj_required)
    local log = quest.newQuestLog()
    local q = quest.newQuest(qid, qid)
    local s = quest.newQuestStage("s1", "Stage 1")
    s:addObjective(quest.newObjective("collect", "Collect items",
        deadline_obj_required or 5))
    q:addStage(s)
    log:addQuest(q)
    log:startQuest(qid)
    return log, q
end

describe("integration: library.quest    lurek.timer.Scheduler", function()

    it("scheduler:after deadline auto-fails an active quest", function()
        local log, q = build_log_with_quest("ticking")
        local sched = lurek.timer.newScheduler()

        sched:after(2.0, function() log:failQuest("ticking") end)

        sched:update(1.0)
        expect_equal("active", q.status)
        sched:update(1.5)
        expect_equal("failed", q.status)
    end)

    it("scheduler:every advances objective progress and completes it", function()
        local log = quest.newQuestLog()
        local q = quest.newQuest("hunt", "Hunt")
        local stage = quest.newQuestStage("s", "S")
        stage:addObjective(quest.newObjective("kills", "Slay foes", 3))
        q:addStage(stage)
        log:addQuest(q)
        log:startQuest("hunt")

        local sched = lurek.timer.newScheduler()
        sched:every(1.0, function()
            log:advanceObjective("hunt", "kills", 1)
        end, 3)

        sched:update(1.0); sched:update(1.0); sched:update(1.0)
        expect_equal(3, stage:getObjective("kills").current)
        expect_true(stage:getObjective("kills"):isComplete())
    end)

    it("cancel aborts the deadline and the quest stays active", function()
        local log, q = build_log_with_quest("cancellable")
        local sched = lurek.timer.newScheduler()

        local id = sched:after(1.0, function() log:failQuest("cancellable") end)
        local ok = sched:cancel(id)
        expect_true(ok)
        sched:update(2.0)
        expect_equal("active", q.status)
        expect_equal(0, sched:getCount())
    end)

    -- resuming lets it fire after the remaining wall time elapses.
    it("pause and resume preserves the remaining deadline window", function()
        local log, q = build_log_with_quest("pausable")
        local sched = lurek.timer.newScheduler()
        local id = sched:after(1.0, function() log:failQuest("pausable") end)

        sched:update(0.4)
        sched:pause(id)
        sched:update(5.0)
        expect_equal("active", q.status)
        sched:resume(id)
        sched:update(0.7)
        expect_equal("failed", q.status)
    end)

    it("zero-delay deadline fires on the next update", function()
        local log, q = build_log_with_quest("instant")
        local sched = lurek.timer.newScheduler()
        sched:after(0.0, function() log:failQuest("instant") end)
        sched:update(0.0001)
        expect_equal("failed", q.status)
    end)

    it("scheduler:after rejects a non-function callback", function()
        local sched = lurek.timer.newScheduler()
        expect_error(function()
            sched:after(1.0, "not a function")
        end)
    end)

end)
test_summary()
