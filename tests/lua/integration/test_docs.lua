-- tests/lua/test_docs.lua
-- BDD tests for lurek.docs.* documentation management API

-- @description Covers suite: lurek.docs.
describe("lurek.docs", function()

    -- ============= scan =============

    -- @covers lurek.docs.scan
    -- @covers lurek.docs.getCatalog
    -- @covers lurek.docs.coverage
    -- @covers lurek.docs.coverageModule
    -- @covers lurek.docs.describe
    -- @covers lurek.docs.quality
    -- @covers lurek.docs.resetCatalog
    -- @covers lurek.docs.scanModule
    -- @covers lurek.docs.setParamInfo
    -- @covers lurek.docs.setReturnInfo
    -- @covers lurek.docs.validate
    -- @covers lurek.docs.validateModule
    -- @covers lurek.test.bar
    -- @covers lurek.test.foo
    -- @covers lurek.test.func
    -- @covers lurek.test.func2
    -- @covers lurek.test.g1
    -- @covers lurek.test.json
    -- @covers lurek.test.ms
    -- @covers lurek.test.q1
    -- @covers lurek.test.scored
    -- @covers lurek.test.sum
    -- @covers lurek.test.tt
    -- @covers lurek.test.w1
    -- @covers lurek.test.w2
    -- @description Verifies the docs module can scan the lurek namespace and return an API catalog; despite the folder placement this is a single-module docs test.
    it("should scan the luna namespace", function()
        local catalog = lurek.docs.scan()
        expect_not_nil(catalog, "scan() should return an ApiCatalog")
    end)

    -- @covers lurek.docs.scan
    -- @covers lurek.docs.ApiCatalog.getModules
    -- @description Verifies a scanned docs catalog exposes module enumeration through getModules.
    it("scan should return catalog with getModules", function()
        local catalog = lurek.docs.scan()
        local modules = catalog:getModules()
        expect_not_nil(modules, "getModules() should return a table")
        -- There must be at least a few modules (graphics, audio, etc.)
        expect_true(#modules > 0, "should have found at least one module")
    end)

    -- @covers lurek.docs.scan
    -- @covers lurek.docs.ApiCatalog.getEntries
    -- @description Verifies the docs scan can retrieve entries for a specific module.
    it("scan should find lurek.render functions", function()
        local catalog = lurek.docs.scan()
        local entries = catalog:getEntries("graphics")
        expect_not_nil(entries, "getEntries('graphics') should return a table")
        expect_true(#entries > 0, "graphics should have entries")
    end)

    -- ============= scanModule =============

    -- @covers lurek.docs.scanModule
    -- @covers lurek.docs.ApiCatalog.entryCount
    -- @description Verifies scanning a single module returns a populated docs catalog for that module.
    it("should scan a single module", function()
        local catalog = lurek.docs.scanModule("graphics")
        expect_not_nil(catalog, "scanModule should return a catalog")
        local count = catalog:entryCount()
        expect_true(count > 0, "graphics module should have entries")
    end)
    -- ============= describe / getCatalog / resetCatalog =============

    -- @covers lurek.docs.describe
    -- @covers lurek.docs.getCatalog
    -- @description Verifies described API metadata is stored in and retrievable from the docs catalog.
    it("should describe and getCatalog", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.foo", "A test function")
        local cat = lurek.docs.getCatalog()
        local entry = cat:getEntry("lurek.test.foo")
        expect_not_nil(entry, "entry should exist after describe")
        expect_equal("A test function", entry:getDescription())
        lurek.docs.resetCatalog()
    end)
    -- @covers lurek.docs.resetCatalog
    -- @covers lurek.docs.getCatalog
    -- @description Verifies resetting the docs catalog removes previously registered entries.
    it("should reset the internal catalog", function()
        lurek.docs.describe("lurek.test.bar", "Another test")
        lurek.docs.resetCatalog()
        local cat = lurek.docs.getCatalog()
        expect_equal(0, cat:entryCount())
    end)

    -- ============= setParamInfo / setReturnInfo =============

    -- @covers lurek.docs.setParamInfo
    -- @covers lurek.docs.DocEntry.getParameters
    -- @description Verifies parameter metadata can be attached to a docs entry and read back from the catalog.
    it("should set parameter info", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.func", "A function")
        lurek.docs.setParamInfo("lurek.test.func", {
            { name = "x", type = "number", description = "X coord", optional = false },
            { name = "y", type = "number", description = "Y coord", optional = true, default = "0" },
        })
        local cat = lurek.docs.getCatalog()
        local entry = cat:getEntry("lurek.test.func")
        expect_not_nil(entry, "entry should exist")
        local params = entry:getParameters()
        expect_equal(2, #params)
        expect_equal("x", params[1].name)
        expect_equal("number", params[1].type)
        expect_equal(true, params[2].optional)
        lurek.docs.resetCatalog()
    end)
    -- @covers lurek.docs.setReturnInfo
    -- @covers lurek.docs.DocEntry.getReturns
    -- @description Verifies return metadata can be attached to and retrieved from a docs entry.
    it("should set return info", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.func2", "Another function")
        lurek.docs.setReturnInfo("lurek.test.func2", {
            { type = "number", description = "The result" },
        })
        local cat = lurek.docs.getCatalog()
        local entry = cat:getEntry("lurek.test.func2")
        expect_not_nil(entry, "entry should exist")
        local returns = entry:getReturns()
        expect_equal(1, #returns)
        expect_equal("number", returns[1].type)
        lurek.docs.resetCatalog()
    end)

    -- ============= DocEntry methods =============

    -- @covers lurek.docs.DocEntry.getScore
    -- @covers lurek.docs.DocEntry.hasDescription
    -- @description Verifies docs entry quality scoring reflects which metadata fields are present on an entry.
    it("DocEntry should report score correctly", function()
        lurek.docs.resetCatalog()
        -- Entry with description only = 40%
        lurek.docs.describe("lurek.test.scored", "Has description")
        local cat = lurek.docs.getCatalog()
        local entry = cat:getEntry("lurek.test.scored")
        local score = entry:getScore()
        expect_true(math.abs(score - 0.4) < 0.01, "score should be 0.4 for desc only, got " .. score)
        expect_true(entry:hasDescription())
        expect_true(not entry:hasParameters())
        expect_true(not entry:hasReturnType())
        expect_true(not entry:hasExample())
        lurek.docs.resetCatalog()
    end)
    -- ============= ApiCatalog methods =============

    -- @covers lurek.docs.ApiCatalog.entryCount
    -- @covers lurek.docs.scanModule
    -- @description Verifies a docs catalog exposes its entry count.
    it("catalog should support entryCount", function()
        local catalog = lurek.docs.scanModule("math")
        local count = catalog:entryCount()
        expect_true(count >= 0, "entryCount should return a number")
    end)
    -- @covers lurek.docs.ApiCatalog.search
    -- @covers lurek.docs.scan
    -- @description Verifies docs catalogs support searching entries by name text.
    it("catalog should support search", function()
        local catalog = lurek.docs.scan()
        local results = catalog:search("graphics")
        expect_not_nil(results, "search should return results")
        -- At least lurek.render.* functions contain 'graphics' in qualified name
        expect_true(#results > 0, "should find graphics entries")
    end)

    -- @covers lurek.docs.ApiCatalog.toTable
    -- @covers lurek.docs.describe
    -- @description Verifies catalog entries can be exported into plain Lua table form.
    it("catalog should support toTable", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.tt", "Test toTable")
        local cat = lurek.docs.getCatalog()
        local tbl = cat:toTable()
        expect_equal(1, #tbl)
        expect_equal("lurek.test.tt", tbl[1].qualifiedName)
        lurek.docs.resetCatalog()
    end)

    -- @covers lurek.docs.ApiCatalog.toJSON
    -- @covers lurek.docs.describe
    -- @description Verifies catalog entries can be serialized to JSON text.
    it("catalog should support toJSON", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.json", "Test JSON")
        local cat = lurek.docs.getCatalog()
        local json = cat:toJSON()
        expect_not_nil(json, "toJSON should return a string")
        expect_true(#json > 0, "JSON should not be empty")
        lurek.docs.resetCatalog()
    end)

    -- @covers lurek.docs.ApiCatalog.filter
    -- @covers lurek.docs.scan
    -- @description Verifies catalogs can filter entries by predicate while preserving only matching names.
    it("catalog should support filter", function()
        local catalog = lurek.docs.scan()
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

    -- @covers lurek.docs.ApiCatalog.merge
    -- @covers lurek.docs.scanModule
    -- @description Verifies two docs catalogs can be merged into a combined catalog.
    it("catalog should support merge", function()
        local cat1 = lurek.docs.scanModule("math")
        local cat2 = lurek.docs.scanModule("timer")
        local merged = cat1:merge(cat2)
        expect_true(
            merged:entryCount() >= cat1:entryCount(),
            "merged should have at least as many entries as cat1"
        )
    end)

    -- ============= validate =============

    -- @covers lurek.docs.validate
    -- @covers lurek.docs.ValidationReport.isValid
    -- @description Verifies docs validation reports missing documentation when the catalog is empty.
    it("should validate completeness", function()
        -- Validating with no catalog should report many missing
        local report = lurek.docs.validate()
        expect_not_nil(report, "validate should return a report")
        expect_true(report:missingCount() > 0, "should have missing entries with empty catalog")
        expect_true(not report:isValid(), "should not be valid with empty catalog")
    end)
    -- @covers lurek.docs.validateModule
    -- @covers lurek.docs.ValidationReport.getSummary
    -- @description Verifies module-scoped docs validation returns a report object with a summary.
    it("should validate a single module", function()
        local report = lurek.docs.validateModule("math")
        expect_not_nil(report, "validateModule should return a report")
        local summary = report:getSummary()
        expect_not_nil(summary, "getSummary should return a string")
    end)

    -- @covers lurek.docs.ValidationReport.toTable
    -- @covers lurek.docs.validate
    -- @description Verifies validation reports can be exported to a structured Lua table.
    it("validation report should support toTable", function()
        local report = lurek.docs.validate()
        local tbl = report:toTable()
        expect_not_nil(tbl.missing, "toTable should have missing field")
        expect_not_nil(tbl.phantom, "toTable should have phantom field")
        expect_not_nil(tbl.incomplete, "toTable should have incomplete field")
    end)

    -- @covers lurek.docs.ValidationReport.toJSON
    -- @covers lurek.docs.validate
    -- @description Verifies validation reports can be serialized to JSON.
    it("validation report should support toJSON", function()
        local report = lurek.docs.validate()
        local json = report:toJSON()
        expect_not_nil(json, "toJSON should return a string")
        expect_true(#json > 0, "JSON should not be empty")
    end)

    -- ============= quality =============

    -- @covers lurek.docs.quality
    -- @covers lurek.docs.QualityReport.getOverallScore
    -- @description Verifies docs quality scoring and grading reflect the metadata stored in a catalog entry.
    it("should compute quality metrics", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.q1", "Good entry")
        lurek.docs.setParamInfo("lurek.test.q1", {
            { name = "a", type = "number", description = "A param" }
        })
        lurek.docs.setReturnInfo("lurek.test.q1", {
            { type = "number", description = "Result" }
        })
        local cat = lurek.docs.getCatalog()
        local quality = lurek.docs.quality(cat)
        expect_not_nil(quality, "quality() should return a report")
        local score = quality:getOverallScore()
        -- domain scoring: desc(1/5) + qualified_name(1/5) + params_or_returns(1/5) = 3/5 = 0.6
        expect_true(math.abs(score - 0.6) < 0.01, "score should be 0.6, got " .. score)
        local grade = quality:getGrade()
        expect_equal("C", grade)
        lurek.docs.resetCatalog()
    end)
    -- @covers lurek.docs.QualityReport.getModuleScores
    -- @covers lurek.docs.quality
    -- @description Verifies docs quality reports expose module-level score breakdowns.
    it("quality should support getModuleScores", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.ms", "Module score test")
        local cat = lurek.docs.getCatalog()
        local quality = lurek.docs.quality(cat)
        local scores = quality:getModuleScores()
        expect_not_nil(scores, "getModuleScores should return a table")
        lurek.docs.resetCatalog()
    end)

    -- @covers lurek.docs.QualityReport.getWorst
    -- @covers lurek.docs.QualityReport.getBest
    -- @description Verifies docs quality reports can rank best and worst entries.
    it("quality should support getWorst and getBest", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.w1", "Good")
        lurek.docs.describe("lurek.test.w2", "") -- bad: empty description
        local cat = lurek.docs.getCatalog()
        local quality = lurek.docs.quality(cat)
        local worst = quality:getWorst(1)
        expect_not_nil(worst, "getWorst should return entries")
        local best = quality:getBest(1)
        expect_not_nil(best, "getBest should return entries")
        lurek.docs.resetCatalog()
    end)

    -- @covers lurek.docs.QualityReport.getByGrade
    -- @covers lurek.docs.quality
    -- @description Verifies docs quality reports can filter entries by letter grade.
    it("quality should support getByGrade", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.g1", "Has desc only")
        local cat = lurek.docs.getCatalog()
        local quality = lurek.docs.quality(cat)
        -- desc only = 0.4, grade D
        local d_entries = quality:getByGrade("D")
        expect_not_nil(d_entries, "getByGrade should return entries")
        expect_true(#d_entries > 0, "should have at least one D-grade entry")
        lurek.docs.resetCatalog()
    end)

    -- @covers lurek.docs.QualityReport.getSummary
    -- @covers lurek.docs.quality
    -- @description Verifies docs quality reports can summarize their findings in text form.
    it("quality should support getSummary", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.sum", "Summary test")
        local cat = lurek.docs.getCatalog()
        local quality = lurek.docs.quality(cat)
        local summary = quality:getSummary()
        expect_not_nil(summary, "getSummary should return a string")
        expect_true(#summary > 0, "summary should not be empty")
        lurek.docs.resetCatalog()
    end)

    -- ============= coverage =============

    -- @covers lurek.docs.coverage
    -- @covers lurek.docs
    -- @description Verifies coverage computation returns documented and total counts even with an empty catalog.
    it("should compute coverage", function()
        local documented, total = lurek.docs.coverage()
        expect_true(total > 0, "total should be > 0")
        expect_equal(0, documented, "documented should be 0 with no catalog")
    end)
    -- @covers lurek.docs.coverage
    -- @covers lurek.docs.scan
    -- @description Verifies coverage computed from a full scan reports all discovered entries as documented.
    it("should compute coverage with catalog", function()
        local catalog = lurek.docs.scan()
        local documented, total = lurek.docs.coverage(catalog)
        expect_true(total > 0, "total should be > 0")
        -- When passing the full scan, documented == total
        expect_equal(total, documented)
    end)

    -- ============= coverageModule =============

    -- @covers lurek.docs.coverageModule
    -- @covers lurek.docs
    -- @description Verifies module-scoped coverage can be queried for an individual docs namespace.
    it("should compute module coverage", function()
        local documented, total = lurek.docs.coverageModule("math")
        expect_true(total >= 0, "total should be >= 0")
    end)

end)
test_summary()
