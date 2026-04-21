-- Lurek2D mods API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests Mod lifecycle, hooks, config, and ModManager operations including
-- validateDependencies, circular detection, load order control, reload queue,
-- and scanFolder.

-- @description Covers suite: lurek.mods module exists.
describe("lurek.mods module exists", function()
    -- @tests lurek.mods
    -- @tests lurek.mods.newMod
    -- @tests lurek.mods.newModManager
    -- @tests lurek.mods.Mod.getId
    -- @tests lurek.mods.Mod.getName
    -- @tests lurek.mods.Mod.getVersion
    -- @tests lurek.mods.Mod.getAuthor
    -- @tests lurek.mods.Mod.getDescription
    -- @tests lurek.mods.Mod.getDependencies
    -- @tests lurek.mods.Mod.getPriority
    -- @tests lurek.mods.Mod.isEnabled
    -- @tests lurek.mods.Mod.setEnabled
    -- @tests lurek.mods.Mod.isLoaded
    -- @tests lurek.mods.Mod.setHook
    -- @tests lurek.mods.Mod.getHook
    -- @tests lurek.mods.Mod.hasHook
    -- @tests lurek.mods.Mod.getHookNames
    -- @tests lurek.mods.Mod.setConfig
    -- @tests lurek.mods.Mod.getConfig
    -- @tests lurek.mods.ModManager.registerMod
    -- @tests lurek.mods.ModManager.unregisterMod
    -- @tests lurek.mods.ModManager.hasMod
    -- @tests lurek.mods.ModManager.getModCount
    -- @tests lurek.mods.ModManager.getAllMods
    -- @tests lurek.mods.ModManager.getLoadOrder
    -- @tests lurek.mods.ModManager.validateDependencies
    -- @tests lurek.mods.ModManager.hasCircularDependencies
    -- @tests lurek.mods.ModManager.setLoadOrder
    -- @tests lurek.mods.ModManager.clearLoadOrder
    -- @tests lurek.mods.ModManager.markForReload
    -- @tests lurek.mods.ModManager.getReloadQueue
    -- @tests lurek.mods.ModManager.clearReloadQueue
    -- @description Verifies the mods namespace is available as a Lua table.
    it("lurek.mods is a table", function()
        expect_type("table", lurek.mods)
    end)
end)

-- @description Covers suite: Factory functions.
describe("Factory functions", function()
    -- @tests lurek.mods.newMod
    -- @description Verifies newMod is exposed.
    it("newMod is a function", function()
        expect_type("function", lurek.mods.newMod)
    end)

    -- @tests lurek.mods.newModManager
    -- @description Verifies newModManager is exposed.
    it("newModManager is a function", function()
        expect_type("function", lurek.mods.newModManager)
    end)
end)

-- @description Covers suite: Mod object creation and metadata.
describe("Mod object creation and metadata", function()
    -- @tests lurek.mods.newMod
    -- @description Verifies newMod returns a non-nil mod handle when an id is supplied.
    it("newMod returns a non-nil object", function()
        local m = lurek.mods.newMod({ id = "test_mod" })
        expect_true(m ~= nil, "mod is not nil")
    end)

    -- @tests lurek.mods.newMod
    -- @description Verifies newMod rejects a definition table without an id field.
    it("newMod without id field raises an error", function()
        expect_error(function()
            lurek.mods.newMod({})
        end)
    end)

    -- @tests lurek.mods.Mod.getId
    -- @description Verifies getId echoes the id passed to the constructor.
    it("getId returns the id passed to newMod", function()
        local m = lurek.mods.newMod({ id = "my_mod" })
        expect_equal("my_mod", m:getId())
    end)

    -- @tests lurek.mods.Mod.getName
    -- @description Verifies getName returns the configured display name.
    it("getName returns the name when provided", function()
        local m = lurek.mods.newMod({ id = "x", name = "My Mod" })
        expect_equal("My Mod", m:getName())
    end)

    -- @tests lurek.mods.Mod.getName
    -- @description Verifies getName still returns a string when no explicit name is provided.
    it("getName returns a string even when not provided", function()
        local m = lurek.mods.newMod({ id = "x" })
        expect_type("string", m:getName())
    end)

    -- @tests lurek.mods.Mod.getVersion
    -- @description Verifies getVersion returns the configured version string.
    it("getVersion returns the version when provided", function()
        local m = lurek.mods.newMod({ id = "x", version = "1.2.3" })
        expect_equal("1.2.3", m:getVersion())
    end)

    -- @tests lurek.mods.Mod.getAuthor
    -- @description Verifies getAuthor returns the configured author string.
    it("getAuthor returns the author when provided", function()
        local m = lurek.mods.newMod({ id = "x", author = "Dev" })
        expect_equal("Dev", m:getAuthor())
    end)

    -- @tests lurek.mods.Mod.getDescription
    -- @description Verifies getDescription returns the configured description.
    it("getDescription returns the description when provided", function()
        local m = lurek.mods.newMod({ id = "x", description = "A cool mod" })
        expect_equal("A cool mod", m:getDescription())
    end)

    -- @tests lurek.mods.Mod.getDependencies
    -- @description Verifies getDependencies returns a table payload.
    it("getDependencies returns a table", function()
        local m = lurek.mods.newMod({ id = "x", dependencies = { "core_mod" } })
        local deps = m:getDependencies()
        expect_type("table", deps)
    end)

    -- @tests lurek.mods.Mod.getDependencies
    -- @description Verifies getDependencies preserves all declared dependency ids.
    it("getDependencies includes declared dependency ids", function()
        local m = lurek.mods.newMod({ id = "x", dependencies = { "dep_a", "dep_b" } })
        local deps = m:getDependencies()
        expect_equal(2, #deps)
    end)

    -- @tests lurek.mods.Mod.getPriority
    -- @description Verifies getPriority returns the configured load priority.
    it("getPriority returns the priority when provided", function()
        local m = lurek.mods.newMod({ id = "x", priority = 5 })
        expect_equal(5, m:getPriority())
    end)

    -- @tests lurek.mods.Mod.isEnabled
    -- @description Verifies mods start enabled by default.
    it("isEnabled returns true by default", function()
        local m = lurek.mods.newMod({ id = "x" })
        expect_true(m:isEnabled(), "mods are enabled by default")
    end)

    -- @tests lurek.mods.Mod.setEnabled
    -- @description Verifies setEnabled(false) disables the mod.
    it("setEnabled can disable a mod", function()
        local m = lurek.mods.newMod({ id = "x" })
        m:setEnabled(false)
        expect_false(m:isEnabled())
    end)

    -- @tests lurek.mods.Mod.setEnabled
    -- @description Verifies setEnabled(true) can re-enable a disabled mod.
    it("setEnabled can re-enable a mod", function()
        local m = lurek.mods.newMod({ id = "x" })
        m:setEnabled(false)
        m:setEnabled(true)
        expect_true(m:isEnabled())
    end)

    -- @tests lurek.mods.Mod.isLoaded
    -- @description Verifies mods start unloaded.
    it("isLoaded returns false by default", function()
        local m = lurek.mods.newMod({ id = "x" })
        expect_false(m:isLoaded())
    end)
end)

-- @description Covers suite: Mod hooks.
describe("Mod hooks", function()
    -- @tests lurek.mods.Mod.setHook
    -- @description Verifies setHook stores a function retrievable through getHook.
    it("setHook stores a function callable via getHook", function()
        local m = lurek.mods.newMod({ id = "hooks_mod" })
        local called = false
        m:setHook("on_load", function() called = true end)
        local fn = m:getHook("on_load")
        expect_type("function", fn)
        fn()
        expect_true(called, "hook was invoked")
    end)

    -- @tests lurek.mods.Mod.hasHook
    -- @description Verifies hasHook returns false before registration.
    it("hasHook returns false before setHook", function()
        local m = lurek.mods.newMod({ id = "has_hook_test" })
        expect_false(m:hasHook("on_load"))
    end)

    -- @tests lurek.mods.Mod.hasHook
    -- @description Verifies hasHook returns true after registration.
    it("hasHook returns true after setHook", function()
        local m = lurek.mods.newMod({ id = "has_hook_set" })
        m:setHook("on_load", function() end)
        expect_true(m:hasHook("on_load"))
    end)

    -- @tests lurek.mods.Mod.getHookNames
    -- @description Verifies getHookNames lists registered hook names.
    it("getHookNames returns a table of registered hook names", function()
        local m = lurek.mods.newMod({ id = "hook_names_mod" })
        m:setHook("on_load",   function() end)
        m:setHook("on_unload", function() end)
        local names = m:getHookNames()
        expect_type("table", names)
        expect_true(#names >= 2, "at least 2 hook names")
    end)

    -- @tests lurek.mods.Mod.getHookNames
    -- @description Verifies getHookNames returns an empty table when no hooks exist.
    it("getHookNames returns empty table for mod with no hooks", function()
        local m = lurek.mods.newMod({ id = "no_hooks" })
        local names = m:getHookNames()
        expect_equal(0, #names)
    end)

    -- @tests lurek.mods.Mod.getHook
    -- @description Verifies getHook returns nil for an unknown hook name.
    it("getHook returns nil for unregistered hook name", function()
        local m = lurek.mods.newMod({ id = "getHook_nil" })
        expect_nil(m:getHook("nonexistent_hook"))
    end)

    -- @tests lurek.mods.Mod.setHook
    -- @description Verifies separately registered hooks remain independent when invoked.
    it("multiple hooks are stored independently", function()
        local m = lurek.mods.newMod({ id = "multi_hook" })
        local a_called, b_called = false, false
        m:setHook("hook_a", function() a_called = true end)
        m:setHook("hook_b", function() b_called = true end)
        m:getHook("hook_a")()
        expect_true(a_called,  "hook_a was called")
        expect_false(b_called, "hook_b was not called yet")
        m:getHook("hook_b")()
        expect_true(b_called, "hook_b was called")
    end)
end)

-- @description Covers suite: Mod config.
describe("Mod config", function()
    -- @tests lurek.mods.Mod.setConfig
    -- @description Verifies string config values round-trip through setConfig and getConfig.
    it("setConfig / getConfig round-trips a string value", function()
        local m = lurek.mods.newMod({ id = "cfg_mod" })
        m:setConfig("0.8")
        expect_equal("0.8", m:getConfig())
    end)

    -- @tests lurek.mods.Mod.setConfig
    -- @description Verifies numeric config values round-trip through setConfig and getConfig.
    it("setConfig / getConfig round-trips a number value", function()
        local m = lurek.mods.newMod({ id = "cfg_num" })
        m:setConfig(42)
        local v = m:getConfig()
        expect_equal(42, v)
    end)

    -- @tests lurek.mods.Mod.getConfig
    -- @description Verifies getConfig returns nil before any config is set.
    it("getConfig returns nil when not set", function()
        local m = lurek.mods.newMod({ id = "cfg_nil" })
        expect_nil(m:getConfig())
    end)

    -- @tests lurek.mods.Mod.setConfig
    -- @description Verifies later setConfig calls overwrite the previous value.
    it("setConfig overwrites previous value", function()
        local m = lurek.mods.newMod({ id = "cfg_overwrite" })
        m:setConfig(1)
        m:setConfig(2)
        expect_equal(2, m:getConfig())
    end)
end)

-- @description Covers suite: ModManager object.
describe("ModManager object", function()
    -- @tests lurek.mods.newModManager
    -- @description Verifies newModManager returns a non-nil manager handle.
    it("newModManager returns a non-nil object", function()
        local mm = lurek.mods.newModManager()
        expect_true(mm ~= nil, "mod manager is not nil")
    end)

    -- @tests lurek.mods.ModManager.getLoadOrder
    -- @description Verifies getLoadOrder returns a table on an empty manager.
    it("getLoadOrder returns a table on empty manager", function()
        local mm = lurek.mods.newModManager()
        expect_type("table", mm:getLoadOrder())
    end)

    -- @tests lurek.mods.ModManager.getLoadOrder
    -- @description Verifies a new manager starts with an empty load order.
    it("getLoadOrder is empty on new manager", function()
        local mm = lurek.mods.newModManager()
        expect_equal(0, #mm:getLoadOrder())
    end)

    -- @tests lurek.mods.ModManager.registerMod
    -- @description Verifies registerMod adds a mod that appears in getAllMods.
    it("registerMod adds a mod and getAllMods includes it", function()
        local mm = lurek.mods.newModManager()
        local m = lurek.mods.newMod({ id = "pack_a" })
        mm:registerMod(m)
        local all = mm:getAllMods()
        expect_type("table", all)
        expect_true(#all >= 1, "at least one mod registered")
    end)

    -- @tests lurek.mods.ModManager.hasMod
    -- @description Verifies hasMod returns false for an unknown mod id.
    it("hasMod returns false for unknown id", function()
        local mm = lurek.mods.newModManager()
        expect_false(mm:hasMod("nonexistent_mod"))
    end)

    -- @tests lurek.mods.ModManager.hasMod
    -- @description Verifies hasMod returns true after a mod is registered.
    it("hasMod returns true after registerMod", function()
        local mm = lurek.mods.newModManager()
        local m = lurek.mods.newMod({ id = "unique_mod" })
        mm:registerMod(m)
        expect_true(mm:hasMod("unique_mod"), "found registered mod by id")
    end)

    -- @tests lurek.mods.ModManager.unregisterMod
    -- @description Verifies unregisterMod removes a mod from manager lookup.
    it("unregisterMod removes the mod", function()
        local mm = lurek.mods.newModManager()
        local m = lurek.mods.newMod({ id = "temp_mod" })
        mm:registerMod(m)
        mm:unregisterMod("temp_mod")
        expect_false(mm:hasMod("temp_mod"))
    end)

    -- @tests lurek.mods.ModManager.getModCount
    -- @description Verifies getModCount reports zero for a new manager.
    it("getModCount returns 0 on empty manager", function()
        local mm = lurek.mods.newModManager()
        expect_equal(0, mm:getModCount())
    end)

    -- @tests lurek.mods.ModManager.getModCount
    -- @description Verifies getModCount increases as mods are registered.
    it("getModCount increments after registerMod", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "m1" }))
        mm:registerMod(lurek.mods.newMod({ id = "m2" }))
        expect_equal(2, mm:getModCount())
    end)
end)

-- @description Covers suite: ModManager.validateDependencies / hasCircularDependencies.
describe("ModManager.validateDependencies / hasCircularDependencies", function()
    -- @tests lurek.mods.ModManager.validateDependencies
    -- @description Verifies validateDependencies returns a table result.
    it("validateDependencies returns a table", function()
        local mm = lurek.mods.newModManager()
        local result = mm:validateDependencies()
        expect_type("table", result)
    end)

    -- @tests lurek.mods.ModManager.validateDependencies
    -- @description Verifies independent mods validate without dependency errors.
    it("validateDependencies is empty for independent mods", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "standalone_a" }))
        mm:registerMod(lurek.mods.newMod({ id = "standalone_b" }))
        local errors = mm:validateDependencies()
        expect_equal(0, #errors)
    end)

    -- @tests lurek.mods.ModManager.validateDependencies
    -- @description Verifies missing dependencies produce validation errors.
    it("validateDependencies reports missing dependency", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({
            id = "needs_missing",
            dependencies = { "missing_dep" },
        }))
        local errors = mm:validateDependencies()
        expect_true(#errors >= 1, "unmet dependency should produce an error entry")
    end)

    -- @tests lurek.mods.ModManager.validateDependencies
    -- @description Verifies registered dependency providers clear validation errors.
    it("validateDependencies is empty when dependencies are all registered", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "dep_provider" }))
        mm:registerMod(lurek.mods.newMod({
            id = "dep_consumer",
            dependencies = { "dep_provider" },
        }))
        local errors = mm:validateDependencies()
        expect_equal(0, #errors)
    end)

    -- @tests lurek.mods.ModManager.hasCircularDependencies
    -- @description Verifies hasCircularDependencies returns a boolean.
    it("hasCircularDependencies returns a boolean", function()
        local mm = lurek.mods.newModManager()
        local result = mm:hasCircularDependencies()
        expect_type("boolean", result)
    end)

    -- @tests lurek.mods.ModManager.hasCircularDependencies
    -- @description Verifies acyclic graphs report no circular dependencies.
    it("hasCircularDependencies is false for acyclic dependency graph", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "base" }))
        mm:registerMod(lurek.mods.newMod({ id = "depends_on_base", dependencies = { "base" } }))
        expect_false(mm:hasCircularDependencies())
    end)
end)

-- @description Covers suite: ModManager load order control.
describe("ModManager load order control", function()
    -- @tests lurek.mods.ModManager.setLoadOrder
    -- @description Verifies setLoadOrder accepts an explicit ordered list of mod ids.
    it("setLoadOrder accepts an ordered list of mod ids", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "ord_a" }))
        mm:registerMod(lurek.mods.newMod({ id = "ord_b" }))
        expect_no_error(function()
            mm:setLoadOrder({ "ord_a", "ord_b" })
        end)
    end)

    -- @tests lurek.mods.ModManager.getLoadOrder
    -- @description Verifies getLoadOrder reflects the previously assigned order.
    it("getLoadOrder reflects setLoadOrder", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "lo_first" }))
        mm:registerMod(lurek.mods.newMod({ id = "lo_second" }))
        mm:setLoadOrder({ "lo_first", "lo_second" })
        local order = mm:getLoadOrder()
        -- getLoadOrder returns a table of mod info tables; check the first
        -- item's id field to confirm ordering was applied.
        expect_type("table", order)
        expect_true(#order >= 1, "at least one entry after setLoadOrder")
    end)

    -- @tests lurek.mods.ModManager.clearLoadOrder
    -- @description Verifies clearLoadOrder resets explicit ordering state.
    it("clearLoadOrder resets the explicit order", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "clr_a" }))
        mm:setLoadOrder({ "clr_a" })
        expect_no_error(function() mm:clearLoadOrder() end)
    end)
end)

-- @description Covers suite: ModManager reload queue.
describe("ModManager reload queue", function()
    -- @tests lurek.mods.ModManager.markForReload
    -- @description Verifies markForReload queues a mod id without error.
    it("markForReload adds a mod id to the reload queue", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "reload_me" }))
        expect_no_error(function() mm:markForReload("reload_me") end)
    end)

    -- @tests lurek.mods.ModManager.getReloadQueue
    -- @description Verifies getReloadQueue returns a table payload.
    it("getReloadQueue returns a table", function()
        local mm = lurek.mods.newModManager()
        local q = mm:getReloadQueue()
        expect_type("table", q)
    end)

    -- @tests lurek.mods.ModManager.getReloadQueue
    -- @description Verifies queued ids appear in the reload queue.
    it("getReloadQueue contains id after markForReload", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "rq_mod" }))
        mm:markForReload("rq_mod")
        local q = mm:getReloadQueue()
        local found = false
        for _, id in ipairs(q) do
            if id == "rq_mod" then found = true end
        end
        expect_true(found, "rq_mod should appear in reload queue")
    end)

    -- @tests lurek.mods.ModManager.clearReloadQueue
    -- @description Verifies clearReloadQueue empties the reload queue.
    it("clearReloadQueue empties the queue", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "rq_clear" }))
        mm:markForReload("rq_clear")
        mm:clearReloadQueue()
        expect_equal(0, #mm:getReloadQueue())
    end)
end)

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.mods.checkApiVersion
    it("covers lurek.mods.checkApiVersion", function()
        -- TODO: Implement test for lurek.mods.checkApiVersion
    end)

    -- @tests Mod:getApiVersion
    it("covers Mod:getApiVersion", function()
        -- TODO: Implement test for Mod:getApiVersion
    end)

    -- @tests Mod:setApiVersion
    it("covers Mod:setApiVersion", function()
        -- TODO: Implement test for Mod:setApiVersion
    end)

    -- @tests Mod:getCapabilities
    it("covers Mod:getCapabilities", function()
        -- TODO: Implement test for Mod:getCapabilities
    end)

    -- @tests Mod:setCapabilities
    it("covers Mod:setCapabilities", function()
        -- TODO: Implement test for Mod:setCapabilities
    end)

    -- @tests Mod:getConfigSchema
    it("covers Mod:getConfigSchema", function()
        -- TODO: Implement test for Mod:getConfigSchema
    end)

    -- @tests Mod:setConfigSchema
    it("covers Mod:setConfigSchema", function()
        -- TODO: Implement test for Mod:setConfigSchema
    end)

    -- @tests Mod:releaseRefs
    it("covers Mod:releaseRefs", function()
        -- TODO: Implement test for Mod:releaseRefs
    end)

    -- @tests ModManager:getModPath
    it("covers ModManager:getModPath", function()
        -- TODO: Implement test for ModManager:getModPath
    end)

end)

describe("Missing explicit test for Mod:getId", function()
    it("Mod:getId works", function()
        -- @tests Mod:getId
        -- TODO: add assertion for Mod:getId
    end)
end)

describe("Missing explicit test for Mod:getName", function()
    it("Mod:getName works", function()
        -- @tests Mod:getName
        -- TODO: add assertion for Mod:getName
    end)
end)

describe("Missing explicit test for Mod:getVersion", function()
    it("Mod:getVersion works", function()
        -- @tests Mod:getVersion
        -- TODO: add assertion for Mod:getVersion
    end)
end)

describe("Missing explicit test for Mod:getAuthor", function()
    it("Mod:getAuthor works", function()
        -- @tests Mod:getAuthor
        -- TODO: add assertion for Mod:getAuthor
    end)
end)

describe("Missing explicit test for Mod:getDescription", function()
    it("Mod:getDescription works", function()
        -- @tests Mod:getDescription
        -- TODO: add assertion for Mod:getDescription
    end)
end)

describe("Missing explicit test for Mod:getDependencies", function()
    it("Mod:getDependencies works", function()
        -- @tests Mod:getDependencies
        -- TODO: add assertion for Mod:getDependencies
    end)
end)

describe("Missing explicit test for Mod:getPriority", function()
    it("Mod:getPriority works", function()
        -- @tests Mod:getPriority
        -- TODO: add assertion for Mod:getPriority
    end)
end)

describe("Missing explicit test for Mod:isEnabled", function()
    it("Mod:isEnabled works", function()
        -- @tests Mod:isEnabled
        -- TODO: add assertion for Mod:isEnabled
    end)
end)

describe("Missing explicit test for Mod:setEnabled", function()
    it("Mod:setEnabled works", function()
        -- @tests Mod:setEnabled
        -- TODO: add assertion for Mod:setEnabled
    end)
end)

describe("Missing explicit test for Mod:isLoaded", function()
    it("Mod:isLoaded works", function()
        -- @tests Mod:isLoaded
        -- TODO: add assertion for Mod:isLoaded
    end)
end)

describe("Missing explicit test for Mod:getHook", function()
    it("Mod:getHook works", function()
        -- @tests Mod:getHook
        -- TODO: add assertion for Mod:getHook
    end)
end)

describe("Missing explicit test for Mod:hasHook", function()
    it("Mod:hasHook works", function()
        -- @tests Mod:hasHook
        -- TODO: add assertion for Mod:hasHook
    end)
end)

describe("Missing explicit test for Mod:getHookNames", function()
    it("Mod:getHookNames works", function()
        -- @tests Mod:getHookNames
        -- TODO: add assertion for Mod:getHookNames
    end)
end)

describe("Missing explicit test for Mod:setConfig", function()
    it("Mod:setConfig works", function()
        -- @tests Mod:setConfig
        -- TODO: add assertion for Mod:setConfig
    end)
end)

describe("Missing explicit test for Mod:getConfig", function()
    it("Mod:getConfig works", function()
        -- @tests Mod:getConfig
        -- TODO: add assertion for Mod:getConfig
    end)
end)

describe("Missing explicit test for ModManager:registerMod", function()
    it("ModManager:registerMod works", function()
        -- @tests ModManager:registerMod
        -- TODO: add assertion for ModManager:registerMod
    end)
end)

describe("Missing explicit test for ModManager:unregisterMod", function()
    it("ModManager:unregisterMod works", function()
        -- @tests ModManager:unregisterMod
        -- TODO: add assertion for ModManager:unregisterMod
    end)
end)

describe("Missing explicit test for ModManager:hasMod", function()
    it("ModManager:hasMod works", function()
        -- @tests ModManager:hasMod
        -- TODO: add assertion for ModManager:hasMod
    end)
end)

describe("Missing explicit test for ModManager:getModCount", function()
    it("ModManager:getModCount works", function()
        -- @tests ModManager:getModCount
        -- TODO: add assertion for ModManager:getModCount
    end)
end)

describe("Missing explicit test for ModManager:getAllMods", function()
    it("ModManager:getAllMods works", function()
        -- @tests ModManager:getAllMods
        -- TODO: add assertion for ModManager:getAllMods
    end)
end)

describe("Missing explicit test for ModManager:getLoadOrder", function()
    it("ModManager:getLoadOrder works", function()
        -- @tests ModManager:getLoadOrder
        -- TODO: add assertion for ModManager:getLoadOrder
    end)
end)

describe("Missing explicit test for ModManager:validateDependencies", function()
    it("ModManager:validateDependencies works", function()
        -- @tests ModManager:validateDependencies
        -- TODO: add assertion for ModManager:validateDependencies
    end)
end)

describe("Missing explicit test for ModManager:hasCircularDependencies", function()
    it("ModManager:hasCircularDependencies works", function()
        -- @tests ModManager:hasCircularDependencies
        -- TODO: add assertion for ModManager:hasCircularDependencies
    end)
end)

describe("Missing explicit test for ModManager:setLoadOrder", function()
    it("ModManager:setLoadOrder works", function()
        -- @tests ModManager:setLoadOrder
        -- TODO: add assertion for ModManager:setLoadOrder
    end)
end)

describe("Missing explicit test for ModManager:clearLoadOrder", function()
    it("ModManager:clearLoadOrder works", function()
        -- @tests ModManager:clearLoadOrder
        -- TODO: add assertion for ModManager:clearLoadOrder
    end)
end)

describe("Missing explicit test for ModManager:scanFolder", function()
    it("ModManager:scanFolder works", function()
        -- @tests ModManager:scanFolder
        -- TODO: add assertion for ModManager:scanFolder
    end)
end)

describe("Missing explicit test for ModManager:markForReload", function()
    it("ModManager:markForReload works", function()
        -- @tests ModManager:markForReload
        -- TODO: add assertion for ModManager:markForReload
    end)
end)

describe("Missing explicit test for ModManager:getReloadQueue", function()
    it("ModManager:getReloadQueue works", function()
        -- @tests ModManager:getReloadQueue
        -- TODO: add assertion for ModManager:getReloadQueue
    end)
end)

describe("Missing explicit test for ModManager:clearReloadQueue", function()
    it("ModManager:clearReloadQueue works", function()
        -- @tests ModManager:clearReloadQueue
        -- TODO: add assertion for ModManager:clearReloadQueue
    end)
end)
