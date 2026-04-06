-- examples/docs_demo/main.lua
-- Demonstrates the luna.docs.* documentation management API

function luna.load()
    -- Scan the entire luna namespace
    catalog = luna.docs.scan()
    modules = catalog:getModules()

    -- Compute coverage
    documented, total = luna.docs.coverage(catalog)

    -- Describe a few entries for quality demo
    luna.docs.resetCatalog()
    luna.docs.describe("luna.graphics.circle", "Draw a circle on screen")
    luna.docs.setParamInfo("luna.graphics.circle", {
        { name = "mode", type = "string", description = "Draw mode: 'fill' or 'line'" },
        { name = "x", type = "number", description = "Center X position" },
        { name = "y", type = "number", description = "Center Y position" },
        { name = "radius", type = "number", description = "Circle radius" },
    })
    luna.docs.setReturnInfo("luna.graphics.circle", {
        { type = "nil", description = "No return value" },
    })
    internalCat = luna.docs.getCatalog()
    qualityReport = luna.docs.quality(internalCat)

    -- Validate against live bindings
    validationReport = luna.docs.validate()

    -- Search for a function
    searchResults = catalog:search("circle")
end

function luna.draw()
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print("=== luna.docs Demo ===", 20, 20)

    local y = 60

    -- Module list
    luna.graphics.print("Discovered modules:", 20, y)
    y = y + 25
    local moduleList = table.concat(modules, ", ")
    luna.graphics.print("  " .. moduleList, 20, y)
    y = y + 40

    -- Entry count
    luna.graphics.print("Total API entries found: " .. catalog:entryCount(), 20, y)
    y = y + 25

    -- Coverage
    luna.graphics.print(string.format("Coverage: %d / %d (%.1f%%)", documented, total, (documented / math.max(total, 1)) * 100), 20, y)
    y = y + 40

    -- Quality report
    luna.graphics.setColor(0.5, 1, 0.5)
    luna.graphics.print("Quality Report (internal catalog):", 20, y)
    y = y + 25
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print(string.format("  Overall: %s (%.0f%%)", qualityReport:getGrade(), qualityReport:getOverallScore() * 100), 20, y)
    y = y + 40

    -- Validation summary
    luna.graphics.setColor(1, 0.5, 0.5)
    luna.graphics.print("Validation Report:", 20, y)
    y = y + 25
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print("  " .. validationReport:getSummary(), 20, y)
    y = y + 40

    -- Search results
    luna.graphics.setColor(0.5, 0.8, 1)
    luna.graphics.print("Search for 'circle':", 20, y)
    y = y + 25
    luna.graphics.setColor(1, 1, 1)
    for i = 1, math.min(#searchResults, 5) do
        luna.graphics.print("  " .. searchResults[i]:getQualifiedName(), 20, y)
        y = y + 20
    end
    y = y + 20

    luna.graphics.setColor(0.7, 0.7, 0.7)
    luna.graphics.print("Press ESC to exit", 20, y)
end

function luna.keypressed(key)
    if key == "escape" then
        luna.event.quit()
    end
end
