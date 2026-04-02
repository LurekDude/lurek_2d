-- tests/lua/test_docs.lua
-- BDD tests for luna.docs.* documentation management API

describe("luna.docs", function()

    -- ============= scan =============

    it("should scan the luna namespace", function()
        local catalog = luna.docs.scan()
        expect_not_nil(catalog, "scan() should return an ApiCatalog")
    end)

    it("scan should return catalog with getModules", function()
        local catalog = luna.docs.scan()
        local modules = catalog:getModules()
        expect_not_nil(modules, "getModules() should return a table")
        -- There must be at least a few modules (graphics, audio, etc.)
        expect_true(#modules > 0, "should have found at least one module")
    end)

    it("scan should find luna.graphics functions", function()
        local catalog = luna.docs.scan()
        local entries = catalog:getEntries("graphics")
        expect_not_nil(entries, "getEntries('graphics') should return a table")
        expect_true(#entries > 0, "graphics should have entries")
    end)

    -- ============= scanModule =============

    it("should scan a single module", function()
        local catalog = luna.docs.scanModule("graphics")
        expect_not_nil(catalog, "scanModule should return a catalog")
        local count = catalog:entryCount()
        expect_true(count > 0, "graphics module should have entries")
    end)

    -- ============= describe / getCatalog / resetCatalog =============

    it("should describe and getCatalog", function()
        luna.docs.resetCatalog()
        luna.docs.describe("luna.test.foo", "A test function")
        local cat = luna.docs.getCatalog()
        local entry = cat:getEntry("luna.test.foo")
        expect_not_nil(entry, "entry should exist after describe")
        expect_equal("A test function", entry:getDescription())
        luna.docs.resetCatalog()
    end)

    it("should reset the internal catalog", function()
        luna.docs.describe("luna.test.bar", "Another test")
        luna.docs.resetCatalog()
        local cat = luna.docs.getCatalog()
        expect_equal(0, cat:entryCount())
    end)

    -- ============= setParamInfo / setReturnInfo =============

    it("should set parameter info", function()
        luna.docs.resetCatalog()
        luna.docs.describe("luna.test.func", "A function")
        luna.docs.setParamInfo("luna.test.func", {
            { name = "x", type = "number", description = "X coord", optional = false },
            { name = "y", type = "number", description = "Y coord", optional = true, default = "0" },
        })
        local cat = luna.docs.getCatalog()
        local entry = cat:getEntry("luna.test.func")
        expect_not_nil(entry, "entry should exist")
        local params = entry:getParameters()
        expect_equal(2, #params)
        expect_equal("x", params[1].name)
        expect_equal("number", params[1].type)
        expect_equal(true, params[2].optional)
        luna.docs.resetCatalog()
    end)

    it("should set return info", function()
        luna.docs.resetCatalog()
        luna.docs.describe("luna.test.func2", "Another function")
        luna.docs.setReturnInfo("luna.test.func2", {
            { type = "number", description = "The result" },
        })
        local cat = luna.docs.getCatalog()
        local entry = cat:getEntry("luna.test.func2")
        expect_not_nil(entry, "entry should exist")
        local returns = entry:getReturns()
        expect_equal(1, #returns)
        expect_equal("number", returns[1].type)
        luna.docs.resetCatalog()
    end)

    -- ============= DocEntry methods =============

    it("DocEntry should report score correctly", function()
        luna.docs.resetCatalog()
        -- Entry with description only = 40%
        luna.docs.describe("luna.test.scored", "Has description")
        local cat = luna.docs.getCatalog()
        local entry = cat:getEntry("luna.test.scored")
        local score = entry:getScore()
        expect_true(math.abs(score - 0.4) < 0.01, "score should be 0.4 for desc only, got " .. score)
        expect_true(entry:hasDescription())
        expect_true(not entry:hasParameters())
        expect_true(not entry:hasReturnType())
        expect_true(not entry:hasExample())
        luna.docs.resetCatalog()
    end)

    -- ============= ApiCatalog methods =============

    it("catalog should support entryCount", function()
        local catalog = luna.docs.scanModule("math")
        local count = catalog:entryCount()
        expect_true(count >= 0, "entryCount should return a number")
    end)

    it("catalog should support search", function()
        local catalog = luna.docs.scan()
        local results = catalog:search("graphics")
        expect_not_nil(results, "search should return results")
        -- At least luna.graphics.* functions contain 'graphics' in qualified name
        expect_true(#results > 0, "should find graphics entries")
    end)

    it("catalog should support toTable", function()
        luna.docs.resetCatalog()
        luna.docs.describe("luna.test.tt", "Test toTable")
        local cat = luna.docs.getCatalog()
        local tbl = cat:toTable()
        expect_equal(1, #tbl)
        expect_equal("luna.test.tt", tbl[1].qualifiedName)
        luna.docs.resetCatalog()
    end)

    it("catalog should support toJSON", function()
        luna.docs.resetCatalog()
        luna.docs.describe("luna.test.json", "Test JSON")
        local cat = luna.docs.getCatalog()
        local json = cat:toJSON()
        expect_not_nil(json, "toJSON should return a string")
        expect_true(#json > 0, "JSON should not be empty")
        luna.docs.resetCatalog()
    end)

    it("catalog should support filter", function()
        local catalog = luna.docs.scan()
        local filtered = catalog:filter(function(entry)
            return entry:getName() == "setColor"
        end)
        expect_not_nil(filtered, "filter should return a catalog")
        -- Every entry should be named setColor
        local entries = filtered:getEntries()
        for i = 1, #entries do
            expect_equal("setColor", entries[i]:getName())
        end
    end)

    it("catalog should support merge", function()
        local cat1 = luna.docs.scanModule("math")
        local cat2 = luna.docs.scanModule("timer")
        local merged = cat1:merge(cat2)
        expect_true(
            merged:entryCount() >= cat1:entryCount(),
            "merged should have at least as many entries as cat1"
        )
    end)

    -- ============= validate =============

    it("should validate completeness", function()
        -- Validating with no catalog should report many missing
        local report = luna.docs.validate()
        expect_not_nil(report, "validate should return a report")
        expect_true(report:missingCount() > 0, "should have missing entries with empty catalog")
        expect_true(not report:isValid(), "should not be valid with empty catalog")
    end)

    it("should validate a single module", function()
        local report = luna.docs.validateModule("math")
        expect_not_nil(report, "validateModule should return a report")
        local summary = report:getSummary()
        expect_not_nil(summary, "getSummary should return a string")
    end)

    it("validation report should support toTable", function()
        local report = luna.docs.validate()
        local tbl = report:toTable()
        expect_not_nil(tbl.missing, "toTable should have missing field")
        expect_not_nil(tbl.phantom, "toTable should have phantom field")
        expect_not_nil(tbl.incomplete, "toTable should have incomplete field")
    end)

    it("validation report should support toJSON", function()
        local report = luna.docs.validate()
        local json = report:toJSON()
        expect_not_nil(json, "toJSON should return a string")
        expect_true(#json > 0, "JSON should not be empty")
    end)

    -- ============= quality =============

    it("should compute quality metrics", function()
        luna.docs.resetCatalog()
        luna.docs.describe("luna.test.q1", "Good entry")
        luna.docs.setParamInfo("luna.test.q1", {
            { name = "a", type = "number", description = "A param" }
        })
        luna.docs.setReturnInfo("luna.test.q1", {
            { type = "number", description = "Result" }
        })
        local cat = luna.docs.getCatalog()
        local quality = luna.docs.quality(cat)
        expect_not_nil(quality, "quality() should return a report")
        local score = quality:getOverallScore()
        -- desc(0.4) + params(0.25) + returns(0.2) = 0.85
        expect_true(math.abs(score - 0.85) < 0.01, "score should be 0.85, got " .. score)
        local grade = quality:getGrade()
        expect_equal("B", grade)
        luna.docs.resetCatalog()
    end)

    it("quality should support getModuleScores", function()
        luna.docs.resetCatalog()
        luna.docs.describe("luna.test.ms", "Module score test")
        local cat = luna.docs.getCatalog()
        local quality = luna.docs.quality(cat)
        local scores = quality:getModuleScores()
        expect_not_nil(scores, "getModuleScores should return a table")
        luna.docs.resetCatalog()
    end)

    it("quality should support getWorst and getBest", function()
        luna.docs.resetCatalog()
        luna.docs.describe("luna.test.w1", "Good")
        luna.docs.describe("luna.test.w2", "") -- bad: empty description
        local cat = luna.docs.getCatalog()
        local quality = luna.docs.quality(cat)
        local worst = quality:getWorst(1)
        expect_not_nil(worst, "getWorst should return entries")
        local best = quality:getBest(1)
        expect_not_nil(best, "getBest should return entries")
        luna.docs.resetCatalog()
    end)

    it("quality should support getByGrade", function()
        luna.docs.resetCatalog()
        luna.docs.describe("luna.test.g1", "Has desc only")
        local cat = luna.docs.getCatalog()
        local quality = luna.docs.quality(cat)
        -- desc only = 0.4, grade D
        local d_entries = quality:getByGrade("D")
        expect_not_nil(d_entries, "getByGrade should return entries")
        expect_true(#d_entries > 0, "should have at least one D-grade entry")
        luna.docs.resetCatalog()
    end)

    it("quality should support getSummary", function()
        luna.docs.resetCatalog()
        luna.docs.describe("luna.test.sum", "Summary test")
        local cat = luna.docs.getCatalog()
        local quality = luna.docs.quality(cat)
        local summary = quality:getSummary()
        expect_not_nil(summary, "getSummary should return a string")
        expect_true(#summary > 0, "summary should not be empty")
        luna.docs.resetCatalog()
    end)

    -- ============= coverage =============

    it("should compute coverage", function()
        local documented, total = luna.docs.coverage()
        expect_true(total > 0, "total should be > 0")
        expect_equal(0, documented, "documented should be 0 with no catalog")
    end)

    it("should compute coverage with catalog", function()
        local catalog = luna.docs.scan()
        local documented, total = luna.docs.coverage(catalog)
        expect_true(total > 0, "total should be > 0")
        -- When passing the full scan, documented == total
        expect_equal(total, documented)
    end)

    -- ============= coverageModule =============

    it("should compute module coverage", function()
        local documented, total = luna.docs.coverageModule("math")
        expect_true(total >= 0, "total should be >= 0")
    end)

end)

test_summary()
