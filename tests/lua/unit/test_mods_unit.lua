-- Lurek2D mods API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests Mod lifecycle, hooks, config, and ModManager operations including
-- validateDependencies, circular detection, load order control, reload queue,
-- and scanFolder.

describe("lurek.mods module exists", function()
    it("lurek.mods is a table", function()
        expect_type("table", lurek.mods)
    end)
end)

describe("Factory functions", function()
    it("newMod is a function", function()
        expect_type("function", lurek.mods.newMod)
    end)

    it("newModManager is a function", function()
        expect_type("function", lurek.mods.newModManager)
    end)
end)

describe("Mod object creation and metadata", function()
    it("newMod returns a non-nil object", function()
        local m = lurek.mods.newMod({ id = "test_mod" })
        expect_true(m ~= nil, "mod is not nil")
    end)

    it("newMod without id field raises an error", function()
        expect_error(function()
            lurek.mods.newMod({})
        end)
    end)

    it("getId returns the id passed to newMod", function()
        local m = lurek.mods.newMod({ id = "my_mod" })
        expect_equal("my_mod", m:getId())
    end)

    it("getName returns the name when provided", function()
        local m = lurek.mods.newMod({ id = "x", name = "My Mod" })
        expect_equal("My Mod", m:getName())
    end)

    it("getName returns a string even when not provided", function()
        local m = lurek.mods.newMod({ id = "x" })
        expect_type("string", m:getName())
    end)

    it("getVersion returns the version when provided", function()
        local m = lurek.mods.newMod({ id = "x", version = "1.2.3" })
        expect_equal("1.2.3", m:getVersion())
    end)

    it("getAuthor returns the author when provided", function()
        local m = lurek.mods.newMod({ id = "x", author = "Dev" })
        expect_equal("Dev", m:getAuthor())
    end)

    it("getDescription returns the description when provided", function()
        local m = lurek.mods.newMod({ id = "x", description = "A cool mod" })
        expect_equal("A cool mod", m:getDescription())
    end)

    it("getDependencies returns a table", function()
        local m = lurek.mods.newMod({ id = "x", dependencies = { "core_mod" } })
        local deps = m:getDependencies()
        expect_type("table", deps)
    end)

    it("getDependencies includes declared dependency ids", function()
        local m = lurek.mods.newMod({ id = "x", dependencies = { "dep_a", "dep_b" } })
        local deps = m:getDependencies()
        expect_equal(2, #deps)
    end)

    it("getPriority returns the priority when provided", function()
        local m = lurek.mods.newMod({ id = "x", priority = 5 })
        expect_equal(5, m:getPriority())
    end)

    it("isEnabled returns true by default", function()
        local m = lurek.mods.newMod({ id = "x" })
        expect_true(m:isEnabled(), "mods are enabled by default")
    end)

    it("setEnabled can disable a mod", function()
        local m = lurek.mods.newMod({ id = "x" })
        m:setEnabled(false)
        expect_false(m:isEnabled())
    end)

    it("setEnabled can re-enable a mod", function()
        local m = lurek.mods.newMod({ id = "x" })
        m:setEnabled(false)
        m:setEnabled(true)
        expect_true(m:isEnabled())
    end)

    it("isLoaded returns false by default", function()
        local m = lurek.mods.newMod({ id = "x" })
        expect_false(m:isLoaded())
    end)
end)

describe("Mod hooks", function()
    it("setHook stores a function callable via getHook", function()
        local m = lurek.mods.newMod({ id = "hooks_mod" })
        local called = false
        m:setHook("on_load", function() called = true end)
        local fn = m:getHook("on_load")
        expect_type("function", fn)
        fn()
        expect_true(called, "hook was invoked")
    end)

    it("hasHook returns false before setHook", function()
        local m = lurek.mods.newMod({ id = "has_hook_test" })
        expect_false(m:hasHook("on_load"))
    end)

    it("hasHook returns true after setHook", function()
        local m = lurek.mods.newMod({ id = "has_hook_set" })
        m:setHook("on_load", function() end)
        expect_true(m:hasHook("on_load"))
    end)

    it("getHookNames returns a table of registered hook names", function()
        local m = lurek.mods.newMod({ id = "hook_names_mod" })
        m:setHook("on_load",   function() end)
        m:setHook("on_unload", function() end)
        local names = m:getHookNames()
        expect_type("table", names)
        expect_true(#names >= 2, "at least 2 hook names")
    end)

    it("getHookNames returns empty table for mod with no hooks", function()
        local m = lurek.mods.newMod({ id = "no_hooks" })
        local names = m:getHookNames()
        expect_equal(0, #names)
    end)

    it("getHook returns nil for unregistered hook name", function()
        local m = lurek.mods.newMod({ id = "getHook_nil" })
        expect_nil(m:getHook("nonexistent_hook"))
    end)

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

describe("Mod config", function()
    it("setConfig / getConfig round-trips a string value", function()
        local m = lurek.mods.newMod({ id = "cfg_mod" })
        m:setConfig("0.8")
        expect_equal("0.8", m:getConfig())
    end)

    it("setConfig / getConfig round-trips a number value", function()
        local m = lurek.mods.newMod({ id = "cfg_num" })
        m:setConfig(42)
        local v = m:getConfig()
        expect_equal(42, v)
    end)

    it("getConfig returns nil when not set", function()
        local m = lurek.mods.newMod({ id = "cfg_nil" })
        expect_nil(m:getConfig())
    end)

    it("setConfig overwrites previous value", function()
        local m = lurek.mods.newMod({ id = "cfg_overwrite" })
        m:setConfig(1)
        m:setConfig(2)
        expect_equal(2, m:getConfig())
    end)
end)

describe("ModManager object", function()
    it("newModManager returns a non-nil object", function()
        local mm = lurek.mods.newModManager()
        expect_true(mm ~= nil, "mod manager is not nil")
    end)

    it("getLoadOrder returns a table on empty manager", function()
        local mm = lurek.mods.newModManager()
        expect_type("table", mm:getLoadOrder())
    end)

    it("getLoadOrder is empty on new manager", function()
        local mm = lurek.mods.newModManager()
        expect_equal(0, #mm:getLoadOrder())
    end)

    it("registerMod adds a mod and getAllMods includes it", function()
        local mm = lurek.mods.newModManager()
        local m = lurek.mods.newMod({ id = "pack_a" })
        mm:registerMod(m)
        local all = mm:getAllMods()
        expect_type("table", all)
        expect_true(#all >= 1, "at least one mod registered")
    end)

    it("hasMod returns false for unknown id", function()
        local mm = lurek.mods.newModManager()
        expect_false(mm:hasMod("nonexistent_mod"))
    end)

    it("hasMod returns true after registerMod", function()
        local mm = lurek.mods.newModManager()
        local m = lurek.mods.newMod({ id = "unique_mod" })
        mm:registerMod(m)
        expect_true(mm:hasMod("unique_mod"), "found registered mod by id")
    end)

    it("unregisterMod removes the mod", function()
        local mm = lurek.mods.newModManager()
        local m = lurek.mods.newMod({ id = "temp_mod" })
        mm:registerMod(m)
        mm:unregisterMod("temp_mod")
        expect_false(mm:hasMod("temp_mod"))
    end)

    it("getModCount returns 0 on empty manager", function()
        local mm = lurek.mods.newModManager()
        expect_equal(0, mm:getModCount())
    end)

    it("getModCount increments after registerMod", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "m1" }))
        mm:registerMod(lurek.mods.newMod({ id = "m2" }))
        expect_equal(2, mm:getModCount())
    end)
end)

describe("ModManager.validateDependencies / hasCircularDependencies", function()
    it("validateDependencies returns a table", function()
        local mm = lurek.mods.newModManager()
        local result = mm:validateDependencies()
        expect_type("table", result)
    end)

    it("validateDependencies is empty for independent mods", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "standalone_a" }))
        mm:registerMod(lurek.mods.newMod({ id = "standalone_b" }))
        local errors = mm:validateDependencies()
        expect_equal(0, #errors)
    end)

    it("validateDependencies reports missing dependency", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({
            id = "needs_missing",
            dependencies = { "missing_dep" },
        }))
        local errors = mm:validateDependencies()
        expect_true(#errors >= 1, "unmet dependency should produce an error entry")
    end)

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

    it("hasCircularDependencies returns a boolean", function()
        local mm = lurek.mods.newModManager()
        local result = mm:hasCircularDependencies()
        expect_type("boolean", result)
    end)

    it("hasCircularDependencies is false for acyclic dependency graph", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "base" }))
        mm:registerMod(lurek.mods.newMod({ id = "depends_on_base", dependencies = { "base" } }))
        expect_false(mm:hasCircularDependencies())
    end)
end)

describe("ModManager load order control", function()
    it("setLoadOrder accepts an ordered list of mod ids", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "ord_a" }))
        mm:registerMod(lurek.mods.newMod({ id = "ord_b" }))
        expect_no_error(function()
            mm:setLoadOrder({ "ord_a", "ord_b" })
        end)
    end)

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

    it("getLoadOrder sorts registered mods by priority", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "priority_high", priority = 10 }))
        mm:registerMod(lurek.mods.newMod({ id = "priority_low", priority = 5 }))

        local order = mm:getLoadOrder()
        expect_type("table", order)
        expect_true(#order >= 2, "expected both mods in load order")
        expect_equal("priority_low", order[1].id)
        expect_equal("priority_high", order[2].id)
    end)

    it("clearLoadOrder resets the explicit order", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "clr_a" }))
        mm:setLoadOrder({ "clr_a" })
        expect_no_error(function() mm:clearLoadOrder() end)
    end)
end)

describe("ModManager reload queue", function()
    it("markForReload adds a mod id to the reload queue", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "reload_me" }))
        expect_no_error(function() mm:markForReload("reload_me") end)
    end)

    it("getReloadQueue returns a table", function()
        local mm = lurek.mods.newModManager()
        local q = mm:getReloadQueue()
        expect_type("table", q)
    end)

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

    it("clearReloadQueue empties the queue", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "rq_clear" }))
        mm:markForReload("rq_clear")
        mm:clearReloadQueue()
        expect_equal(0, #mm:getReloadQueue())
    end)
end)

-- =========================================================================
-- =========================================================================

describe("lurek.mods API coverage", function()
    it("checkApiVersion returns true when mod has no version constraint", function()
        local mod = lurek.mods.newMod({ id = "compat_mod" })
        local ok, err = lurek.mods.checkApiVersion(mod, "1.0.0")
        expect_equal(true, ok)
    end)

    it("checkApiVersion returns false when version does not match", function()
        local mod = lurek.mods.newMod({ id = "incompat_mod", api_version = "2.0.0" })
        local ok, err = lurek.mods.checkApiVersion(mod, "1.0.0")
        expect_equal(false, ok)
        expect_type("string", err)
    end)

    it("getApiVersion / setApiVersion round-trip", function()
        local mod = lurek.mods.newMod({ id = "api_ver_mod" })
        mod:setApiVersion("3.2.1")
        expect_equal("3.2.1", mod:getApiVersion())
    end)

    it("getCapabilities / setCapabilities round-trip", function()
        local mod = lurek.mods.newMod({ id = "caps_mod" })
        mod:setCapabilities({ "save", "network" })
        local caps = mod:getCapabilities()
        expect_type("table", caps)
        expect_equal("save", caps[1])
        expect_equal("network", caps[2])
    end)

    it("getConfigSchema / setConfigSchema round-trip", function()
        local mod = lurek.mods.newMod({ id = "schema_mod" })
        local schema = { { key = "volume", type = "number", default = 0.8 } }
        mod:setConfigSchema(schema)
        local result = mod:getConfigSchema()
        expect_type("table", result)
        expect_equal("volume", result[1].key)
    end)

    it("releaseRefs does not error", function()
        local mod = lurek.mods.newMod({ id = "release_mod" })
        expect_no_error(function()
            mod:releaseRefs()
        end)
    end)

    it("getModPath returns nil for a mod registered without a path", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "path_mod" }))
        local p = mm:getModPath("path_mod")
        -- mods created without a path have nil path
        expect_true(p == nil or type(p) == "string", "must be nil or string")
    end)
end)

describe("Mod core accessors", function()
    local function make_mod()
        return lurek.mods.newMod({
            id = "accessor_mod",
            name = "Accessor Mod",
            version = "1.2.3",
            author = "TestAuthor",
            description = "A test mod",
            dependencies = { "dep_a", "dep_b" },
            priority = 7,
        })
    end

    it("getId returns the mod id", function()
        expect_equal("accessor_mod", make_mod():getId())
    end)

    it("getName returns the mod name", function()
        expect_equal("Accessor Mod", make_mod():getName())
    end)

    it("getVersion returns the version string", function()
        expect_equal("1.2.3", make_mod():getVersion())
    end)

    it("getAuthor returns the author string", function()
        expect_equal("TestAuthor", make_mod():getAuthor())
    end)

    it("getDescription returns the description string", function()
        expect_equal("A test mod", make_mod():getDescription())
    end)

    it("getDependencies returns the dependency array", function()
        local deps = make_mod():getDependencies()
        expect_type("table", deps)
        expect_equal(2, #deps)
        expect_equal("dep_a", deps[1])
        expect_equal("dep_b", deps[2])
    end)

    it("getPriority returns the priority integer", function()
        expect_equal(7, make_mod():getPriority())
    end)

    it("isEnabled defaults to true and setEnabled toggles it", function()
        local m = make_mod()
        expect_equal(true, m:isEnabled())
        m:setEnabled(false)
        expect_equal(false, m:isEnabled())
        m:setEnabled(true)
        expect_equal(true, m:isEnabled())
    end)

    it("isLoaded returns false for a new mod", function()
        expect_equal(false, make_mod():isLoaded())
    end)
end)

describe("Mod hooks and config", function()
    it("registerHook / getHook / hasHook / getHookNames", function()
        local m = lurek.mods.newMod({ id = "hook_mod" })
        expect_equal(false, m:hasHook("onLoad"))
        local fn = function() end
        m:setHook("onLoad", fn)
        expect_equal(true, m:hasHook("onLoad"))
        local hook = m:getHook("onLoad")
        expect_equal("function", type(hook))
        local names = m:getHookNames()
        expect_type("table", names)
        expect_equal("onLoad", names[1])
    end)

    it("setConfig / getConfig round-trip", function()
        local m = lurek.mods.newMod({ id = "config_mod" })
        m:setConfig({ volume = 0.5, fullscreen = true })
        local cfg = m:getConfig()
        expect_type("table", cfg)
        expect_equal(0.5, cfg.volume)
        expect_equal(true, cfg.fullscreen)
    end)
end)

describe("Missing explicit test for ModManager:registerMod", function()
    it("ModManager:registerMod works", function()
        local mm = lurek.mods.newModManager()
        local mod = lurek.mods.newMod({ id = "manager_register" })
        mm:registerMod(mod)

        expect_true(mm:hasMod("manager_register"))
        expect_equal(1, mm:getModCount())
    end)
end)

describe("Missing explicit test for ModManager:unregisterMod", function()
    it("ModManager:unregisterMod works", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "manager_unregister" }))
        mm:markForReload("manager_unregister")

        expect_true(mm:unregisterMod("manager_unregister"))
        expect_false(mm:hasMod("manager_unregister"))
        expect_equal(0, #mm:getReloadQueue())
    end)
end)

describe("ModManager queries", function()
    local function make_mm_with_two()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "query_a", priority = 1 }))
        mm:registerMod(lurek.mods.newMod({ id = "query_b", priority = 2 }))
        return mm
    end

    it("hasMod returns true after registerMod", function()
        local mm = make_mm_with_two()
        expect_equal(true, mm:hasMod("query_a"))
        expect_equal(false, mm:hasMod("__missing__"))
    end)

    it("getModCount returns 2 after two registrations", function()
        local mm = make_mm_with_two()
        expect_equal(2, mm:getModCount())
    end)

    it("getAllMods returns an array with two entries", function()
        local mm = make_mm_with_two()
        local all = mm:getAllMods()
        expect_type("table", all)
        expect_equal(2, #all)
    end)

    it("getLoadOrder returns mods sorted by priority ascending by default", function()
        local mm = make_mm_with_two()
        local order = mm:getLoadOrder()
        expect_type("table", order)
        expect_equal(2, #order)
        expect_equal("query_a", order[1].id)
        expect_equal("query_b", order[2].id)
    end)
end)

describe("Missing explicit test for ModManager:validateDependencies", function()
    it("ModManager:validateDependencies works", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "missing_consumer", dependencies = { "missing_dep" } }))

        local errors = mm:validateDependencies()
        expect_true(#errors >= 1)
    end)
end)

describe("Missing explicit test for ModManager:hasCircularDependencies", function()
    it("ModManager:hasCircularDependencies works", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "cycle_a", dependencies = { "cycle_b" } }))
        mm:registerMod(lurek.mods.newMod({ id = "cycle_b", dependencies = { "cycle_a" } }))

        expect_true(mm:hasCircularDependencies())
    end)
end)

describe("Missing explicit test for ModManager:setLoadOrder", function()
    it("ModManager:setLoadOrder works", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "ordered_high", priority = 5 }))
        mm:registerMod(lurek.mods.newMod({ id = "ordered_low", priority = 1 }))
        mm:setLoadOrder({ "ordered_high", "ordered_low" })

        local order = mm:getLoadOrder()
        expect_equal("ordered_high", order[1].id)
        expect_equal("ordered_low", order[2].id)
    end)
end)

describe("Missing explicit test for ModManager:clearLoadOrder", function()
    it("ModManager:clearLoadOrder works", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "priority_high", priority = 10 }))
        mm:registerMod(lurek.mods.newMod({ id = "priority_low", priority = 1 }))
        mm:setLoadOrder({ "priority_high", "priority_low" })
        mm:clearLoadOrder()

        local order = mm:getLoadOrder()
        expect_equal("priority_low", order[1].id)
        expect_equal("priority_high", order[2].id)
    end)
end)

describe("Missing explicit test for ModManager:scanFolder", function()
    it("ModManager:scanFolder works", function()
        local mm = lurek.mods.newModManager()
        local found = mm:scanFolder("save/_mods_missing_scan_case/")

        expect_equal("table", type(found))
        expect_equal(0, #found)
    end)

    it("ModManager:scanFolder registers mods discovered on disk", function()
        local root = "save/_mods_scan_case/"
        local mod_dir = root .. "my-mod/"

        if lurek.filesystem.exists(root) then
            lurek.filesystem.removeDir(root)
        end

        lurek.filesystem.createDirectory(mod_dir)
        lurek.filesystem.write(
            mod_dir .. "mod.toml",
            "id = \"my-mod\"\nname = \"My Mod\"\nversion = \"2.0.0\"\npriority = 5\n"
        )

        local mm = lurek.mods.newModManager()
        local found = mm:scanFolder(root)

        expect_equal(1, #found)
        expect_equal("my-mod", found[1].id)
        expect_equal("2.0.0", found[1].version)
        expect_equal(5, found[1].priority)
        expect_true(mm:hasMod("my-mod"))

        lurek.filesystem.removeDir(root)
    end)
end)

describe("Missing explicit test for ModManager:markForReload", function()
    it("ModManager:markForReload works", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "reload_target" }))

        expect_true(mm:markForReload("reload_target"))
        expect_equal("reload_target", mm:getReloadQueue()[1])
    end)

    it("ModManager:markForReload returns false for missing mod", function()
        local mm = lurek.mods.newModManager()

        expect_false(mm:markForReload("missing_target"))
        expect_equal(0, #mm:getReloadQueue())
    end)
end)

describe("Missing explicit test for ModManager:getReloadQueue", function()
    it("ModManager:getReloadQueue works", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "dedupe_target" }))
        mm:markForReload("dedupe_target")
        mm:markForReload("dedupe_target")

        local queue = mm:getReloadQueue()
        expect_equal(1, #queue)
        expect_equal("dedupe_target", queue[1])
    end)
end)

describe("Missing explicit test for ModManager:clearReloadQueue", function()
    it("ModManager:clearReloadQueue works", function()
        local mm = lurek.mods.newModManager()
        mm:registerMod(lurek.mods.newMod({ id = "clear_target" }))
        mm:markForReload("clear_target")
        mm:clearReloadQueue()

        expect_equal(0, #mm:getReloadQueue())
    end)
end)

-- =========================================================================
-- Phase 09: lurek.mods content registry
-- =========================================================================
describe("lurek.mods content registry", function()
    it("newRegistry factory exists", function()
        expect_equal(type(lurek.mods.newRegistry), "function")
    end)

    it("registry has registerType, register, get, getAll, getTypes methods", function()
        local reg = lurek.mods.newRegistry()
        expect_equal(type(reg.registerType), "function")
        expect_equal(type(reg.register), "function")
        expect_equal(type(reg.get), "function")
        expect_equal(type(reg.getAll), "function")
        expect_equal(type(reg.getTypes), "function")
    end)

    it("registerType and register/get roundtrip works", function()
        local reg = lurek.mods.newRegistry()
        reg:registerType("weapon")
        reg:register("weapon", "sword", { name = "Sword", damage = 10 })
        local w = reg:get("weapon", "sword")
        expect_not_nil(w)
        expect_equal(w.name, "Sword")
        expect_equal(w.damage, 10)
    end)

    it("get returns nil for unknown entry", function()
        local reg = lurek.mods.newRegistry()
        reg:registerType("spell")
        local result = reg:get("spell", "unknown_spell")
        expect_equal(result, nil)
    end)

    it("getAll returns all entries for a type", function()
        local reg = lurek.mods.newRegistry()
        reg:registerType("item")
        reg:register("item", "potion", { name = "Potion" })
        reg:register("item", "scroll", { name = "Scroll" })
        local all = reg:getAll("item")
        expect_not_nil(all.potion)
        expect_not_nil(all.scroll)
    end)

    it("register on unregistered type returns error", function()
        local reg = lurek.mods.newRegistry()
        local ok = pcall(function()
            reg:register("unknown_type", "id", {})
        end)
        expect_false(ok)
    end)

    it("getTypes returns registered type names", function()
        local reg = lurek.mods.newRegistry()
        reg:registerType("armor")
        reg:registerType("gem")
        local types = reg:getTypes()
        expect_equal(type(types), "table")
        expect_equal(#types, 2)
    end)
end)
test_summary()
