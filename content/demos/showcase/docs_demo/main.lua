-- examples/docs_demo/main.lua
-- Demonstrates the lurek.docs.* documentation management API
-- Run with: cargo run -- content/demos/showcase/docs_demo

-- lurek.docs is not yet implemented in this build
if not lurek.docs then
    function lurek.init()
        lurek.gfx.setBackgroundColor(0.05, 0.05, 0.1)
    end
    function lurek.render()
        lurek.gfx.setColor(1, 0.6, 0.2)
        lurek.gfx.print("Docs API Demo", 20, 20)
        lurek.gfx.setColor(0.7, 0.7, 0.7)
        lurek.gfx.print("lurek.docs is not available in this build.", 20, 60)
        lurek.gfx.print("(API not yet implemented)", 20, 85)
    end
    return
end

function lurek.init()
    -- Scan the entire luna namespace
    catalog = lurek.docs.scan()
    modules = catalog:getModules()

    -- Compute coverage
    documented, total = lurek.docs.coverage(catalog)

    -- Describe a few entries for quality demo
    lurek.docs.resetCatalog()
    lurek.docs.describe("lurek.gfx.circle", "Draw a circle on screen")
    lurek.docs.setParamInfo("lurek.gfx.circle", {
        { name = "mode", type = "string", description = "Draw mode: 'fill' or 'line'" },
        { name = "x", type = "number", description = "Center X position" },
        { name = "y", type = "number", description = "Center Y position" },
        { name = "radius", type = "number", description = "Circle radius" },
    })
    lurek.docs.setReturnInfo("lurek.gfx.circle", {
        { type = "nil", description = "No return value" },
    })
    internalCat = lurek.docs.getCatalog()
    qualityReport = lurek.docs.quality(internalCat)

    -- Validate against live bindings
    validationReport = lurek.docs.validate()

    -- Search for a function
    searchResults = catalog:search("circle")
end

function lurek.render()
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("=== lurek.docs Demo ===", 20, 20)

    local y = 60

    -- Module list
    lurek.gfx.print("Discovered modules:", 20, y)
    y = y + 25
    local moduleList = table.concat(modules, ", ")
    lurek.gfx.print("  " .. moduleList, 20, y)
    y = y + 40

    -- Entry count
    lurek.gfx.print("Total API entries found: " .. catalog:entryCount(), 20, y)
    y = y + 25

    -- Coverage
    lurek.gfx.print(string.format("Coverage: %d / %d (%.1f%%)", documented, total, (documented / math.max(total, 1)) * 100), 20, y)
    y = y + 40

    -- Quality report
    lurek.gfx.setColor(0.5, 1, 0.5)
    lurek.gfx.print("Quality Report (internal catalog):", 20, y)
    y = y + 25
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print(string.format("  Overall: %s (%.0f%%)", qualityReport:getGrade(), qualityReport:getOverallScore() * 100), 20, y)
    y = y + 40

    -- Validation summary
    lurek.gfx.setColor(1, 0.5, 0.5)
    lurek.gfx.print("Validation Report:", 20, y)
    y = y + 25
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("  " .. validationReport:getSummary(), 20, y)
    y = y + 40

    -- Search results
    lurek.gfx.setColor(0.5, 0.8, 1)
    lurek.gfx.print("Search for 'circle':", 20, y)
    y = y + 25
    lurek.gfx.setColor(1, 1, 1)
    for i = 1, math.min(#searchResults, 5) do
        lurek.gfx.print("  " .. searchResults[i]:getQualifiedName(), 20, y)
        y = y + 20
    end
    y = y + 20

    lurek.gfx.setColor(0.7, 0.7, 0.7)
    lurek.gfx.print("Press ESC to exit", 20, y)
end

function lurek.keypressed(key)
    if key == "escape" then
        lurek.signal.quit()
    end
end
