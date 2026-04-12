-- Lurek2D Fuzz Tests (Sandbox Boundary)

describe("sandbox boundary fuzzing", function()
    it("handles random inputs without crashing the engine", function()
        -- Extract a few engine API tables
        local namespaces = {lurek.math, lurek.graphics, lurek.physics}
        
        -- Generate random Lua types
        local garbage = {
            1, -1, 0, 3.14, "hello", "", string.rep("A", 10000),
            {}, {a=1}, {1, 2, 3},
            function() end, true, false, nil
        }
        
        for _, ns in ipairs(namespaces) do
            if ns then
                for func_name, func in pairs(ns) do
                    if type(func) == "function" then
                        -- Fuzz each function with 1-3 garbage args
                        for i = 1, 10 do
                            local a1 = garbage[math.random(#garbage)]
                            local a2 = garbage[math.random(#garbage)]
                            local a3 = garbage[math.random(#garbage)]
                            
                            -- We expect this to either succeed or throw a Lua error (which is caught by pcall)
                            -- What MUST NOT happen is a Rust panic (which crashes the test process)
                            pcall(func, a1, a2, a3)
                        end
                    end
                end
            end
        end
        expect_true(true, "survived fuzzing without a Rust panic")
    end)
end)

test_summary()
