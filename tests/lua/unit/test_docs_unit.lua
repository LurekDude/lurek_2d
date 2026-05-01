-- tests/lua/test_docs.lua
-- BDD tests for lurek.docs.* documentation management API

local function unique_docs_id(stem)
    return table.concat({
        stem,
        tostring(os.time()),
        tostring(math.floor(os.clock() * 1000000)),
    }, "_")
end

local function docs_temp_path(stem, ext)
    return "save/_fs_tests/" .. unique_docs_id(stem) .. ext
end

local function write_text_file(path, content)
    lurek.filesystem.write(path, content)
end

local function read_text_file(path)
    return lurek.filesystem.read(path)
end

local function file_exists(path)
    return lurek.filesystem.exists(path)
end

local function seed_catalog_entry(qualified_name, description)
    lurek.docs.describe(qualified_name, description)
    lurek.docs.setParamInfo(qualified_name, {
        { name = "value", type = "number", description = "input value", optional = false },
    })
    lurek.docs.setReturnInfo(qualified_name, {
        { type = "number", description = "result value" },
    })
end

local function sample_docs_toml(entries)
    return table.concat(entries, "\n")
end

describe("lurek.docs", function()

    -- ============= scan =============

    -- @covers lurek.docs.coverage
    -- @covers lurek.docs.coverageModule
    -- @covers lurek.docs.describe
    -- @covers lurek.docs.getCatalog
    -- @covers lurek.docs.quality
    -- @covers lurek.docs.resetCatalog
    -- @covers lurek.docs.scan
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
    it("should scan the lurek namespace", function()
        local catalog = lurek.docs.scan()
        expect_not_nil(catalog, "scan() should return an ApiCatalog")
    end)

    it("scan should return catalog with getModules", function()
        local catalog = lurek.docs.scan()
        local modules = catalog:getModules()
        expect_not_nil(modules, "getModules() should return a table")
        -- There must be at least a few modules (graphics, audio, etc.)
        expect_true(#modules > 0, "should have found at least one module")
    end)

    it("scan should find lurek.render functions", function()
        local catalog = lurek.docs.scan()
        local entries = catalog:getEntries("render")
        expect_not_nil(entries, "getEntries('graphics') should return a table")
        expect_true(#entries > 0, "graphics should have entries")
    end)

    -- ============= scanModule =============

    it("should scan a single module", function()
        local catalog = lurek.docs.scanModule("render")
        expect_not_nil(catalog, "scanModule should return a catalog")
        local count = catalog:entryCount()
        expect_true(count > 0, "graphics module should have entries")
    end)
    -- ============= describe / getCatalog / resetCatalog =============

    it("should describe and getCatalog", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.foo", "A test function")
        local cat = lurek.docs.getCatalog()
        local entry = cat:getEntry("lurek.test.foo")
        expect_not_nil(entry, "entry should exist after describe")
        expect_equal("A test function", entry:getDescription())
        lurek.docs.resetCatalog()
    end)
    it("should reset the internal catalog", function()
        lurek.docs.describe("lurek.test.bar", "Another test")
        lurek.docs.resetCatalog()
        local cat = lurek.docs.getCatalog()
        expect_equal(0, cat:entryCount())
    end)

    -- ============= setParamInfo / setReturnInfo =============

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

    it("catalog should support entryCount", function()
        local catalog = lurek.docs.scanModule("math")
        local count = catalog:entryCount()
        expect_true(count >= 0, "entryCount should return a number")
    end)
    it("catalog should support search", function()
        local catalog = lurek.docs.scan()
        local results = catalog:search("render")
        expect_not_nil(results, "search should return results")
        -- At least lurek.render.* functions contain 'graphics' in qualified name
        expect_true(#results > 0, "should find graphics entries")
    end)

    it("catalog should support toTable", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.tt", "Test toTable")
        local cat = lurek.docs.getCatalog()
        local tbl = cat:toTable()
        expect_equal(1, #tbl)
        expect_equal("lurek.test.tt", tbl[1].qualifiedName)
        lurek.docs.resetCatalog()
    end)

    it("catalog should support toJSON", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.json", "Test JSON")
        local cat = lurek.docs.getCatalog()
        local json = cat:toJSON()
        expect_not_nil(json, "toJSON should return a string")
        expect_true(#json > 0, "JSON should not be empty")
        lurek.docs.resetCatalog()
    end)

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

    it("should validate completeness", function()
        -- Validating with no catalog should report many missing
        local report = lurek.docs.validate()
        expect_not_nil(report, "validate should return a report")
        expect_true(report:missingCount() > 0, "should have missing entries with empty catalog")
        expect_true(not report:isValid(), "should not be valid with empty catalog")
    end)
    it("should validate a single module", function()
        local report = lurek.docs.validateModule("math")
        expect_not_nil(report, "validateModule should return a report")
        local summary = report:getSummary()
        expect_not_nil(summary, "getSummary should return a string")
    end)

    it("validation report should support toTable", function()
        local report = lurek.docs.validate()
        local tbl = report:toTable()
        expect_not_nil(tbl.missing, "toTable should have missing field")
        expect_not_nil(tbl.phantom, "toTable should have phantom field")
        expect_not_nil(tbl.incomplete, "toTable should have incomplete field")
    end)

    it("validation report should support toJSON", function()
        local report = lurek.docs.validate()
        local json = report:toJSON()
        expect_not_nil(json, "toJSON should return a string")
        expect_true(#json > 0, "JSON should not be empty")
    end)

    -- ============= quality =============

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
        expect_true(math.abs(score - 0.6) < 0.01, "score should be 0.6, got " .. score)
        local grade = quality:getGrade()
        expect_equal("C", grade)
        lurek.docs.resetCatalog()
    end)
    it("quality should support getModuleScores", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.ms", "Module score test")
        local cat = lurek.docs.getCatalog()
        local quality = lurek.docs.quality(cat)
        local scores = quality:getModuleScores()
        expect_not_nil(scores, "getModuleScores should return a table")
        lurek.docs.resetCatalog()
    end)

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

    it("should compute coverage", function()
        local documented, total = lurek.docs.coverage()
        expect_true(total > 0, "total should be > 0")
        expect_equal(0, documented, "documented should be 0 with no catalog")
    end)
    it("should compute coverage with catalog", function()
        local catalog = lurek.docs.scan()
        local documented, total = lurek.docs.coverage(catalog)
        expect_true(total > 0, "total should be > 0")
        -- When passing the full scan, documented == total
        expect_equal(total, documented)
    end)

    -- ============= coverageModule =============

    it("should compute module coverage", function()
        local documented, total = lurek.docs.coverageModule("math")
        expect_true(total >= 0, "total should be >= 0")
    end)

end)

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @covers lurek.docs.loadToml
    it("covers lurek.docs.loadToml", function()
        local path = docs_temp_path("docs_load_toml", ".toml")
        write_text_file(path, sample_docs_toml({
            "[[entries]]",
            'name = "play"',
            'qualifiedName = "lurek.audio.play"',
            'module = "audio"',
            'kind = "function"',
            'description = "Plays a sound"',
        }))

        local catalog = lurek.docs.loadToml(path)
        local entry = catalog:getEntry("lurek.audio.play")

        expect_not_nil(entry)
        expect_equal(1, catalog:entryCount())
        expect_equal("Plays a sound", entry:getDescription())

        os.remove(path)
    end)

    -- @covers lurek.docs.loadAll
    it("covers lurek.docs.loadAll", function()
        local suffix = unique_docs_id("docs_load_all")
        local path_a = "save/_fs_tests/" .. suffix .. "_a.toml"
        local path_b = "save/_fs_tests/" .. suffix .. "_b.toml"

        write_text_file(path_a, sample_docs_toml({
            "[[entries]]",
            'name = "one"',
            'qualifiedName = "lurek.test.' .. suffix .. '.one"',
            'module = "test"',
            'kind = "function"',
            'description = "First entry"',
        }))
        write_text_file(path_b, sample_docs_toml({
            "[[entries]]",
            'name = "two"',
            'qualifiedName = "lurek.test.' .. suffix .. '.two"',
            'module = "test"',
            'kind = "function"',
            'description = "Second entry"',
        }))

        local catalog = lurek.docs.loadAll("save/_fs_tests")
        expect_not_nil(catalog:getEntry("lurek.test." .. suffix .. ".one"))
        expect_not_nil(catalog:getEntry("lurek.test." .. suffix .. ".two"))

        os.remove(path_a)
        os.remove(path_b)
    end)

    -- @covers lurek.docs.checkStaleness
    it("covers lurek.docs.checkStaleness", function()
        local catalog = lurek.docs.scanModule("docs")
        local report = lurek.docs.checkStaleness(catalog, "src/docs")

        expect_type("table", report)
        expect_type("table", report.stale)
        expect_type("table", report.current)
        expect_type("table", report.missing)
        expect_true(#report.current > 0)
    end)

    -- @covers lurek.docs.qualityModule
    it("covers lurek.docs.qualityModule", function()
        local module_name = "lurek.docsbatch." .. unique_docs_id("quality_module")

        lurek.docs.resetCatalog()
        seed_catalog_entry(module_name .. ".alpha", "Alpha entry")
        seed_catalog_entry(module_name .. ".beta", "Beta entry")

        local cat = lurek.docs.getCatalog()
        local quality = lurek.docs.qualityModule(module_name, cat)

        expect_type("number", quality:getOverallScore())
        expect_equal("C", quality:getGrade())
        lurek.docs.resetCatalog()
    end)

    -- @covers lurek.docs.exportCompletions
    it("covers lurek.docs.exportCompletions", function()
        local path = docs_temp_path("docs_export_completions", ".json")
        lurek.docs.resetCatalog()
        seed_catalog_entry("lurek.test.exportCompletions", "Completion entry")

        local cat = lurek.docs.getCatalog()
        lurek.docs.exportCompletions(cat, path)

        expect_true(file_exists(path))
        expect_true(string.find(read_text_file(path), "exportCompletions", 1, true) ~= nil)

        os.remove(path)
        lurek.docs.resetCatalog()
    end)

    -- @covers lurek.docs.exportHover
    it("covers lurek.docs.exportHover", function()
        local path = docs_temp_path("docs_export_hover", ".json")
        lurek.docs.resetCatalog()
        seed_catalog_entry("lurek.test.exportHover", "Hover entry")

        local cat = lurek.docs.getCatalog()
        lurek.docs.exportHover(cat, path)

        expect_true(file_exists(path))
        expect_true(string.find(read_text_file(path), "lurek.test.exportHover", 1, true) ~= nil)

        os.remove(path)
        lurek.docs.resetCatalog()
    end)

    -- @covers lurek.docs.exportSignatures
    it("covers lurek.docs.exportSignatures", function()
        local path = docs_temp_path("docs_export_signatures", ".json")
        lurek.docs.resetCatalog()
        seed_catalog_entry("lurek.test.exportSignatures", "Signature entry")

        local cat = lurek.docs.getCatalog()
        lurek.docs.exportSignatures(cat, path)

        expect_true(file_exists(path))
        expect_true(string.find(read_text_file(path), "value", 1, true) ~= nil)

        os.remove(path)
        lurek.docs.resetCatalog()
    end)

    -- @covers lurek.docs.exportAll
    it("covers lurek.docs.exportAll", function()
        local dir = "save/_fs_tests/" .. unique_docs_id("docs_export_all")
        local completions = dir .. "/completions.json"
        local hover = dir .. "/hover.json"
        local signatures = dir .. "/signatures.json"

        lurek.docs.resetCatalog()
        seed_catalog_entry("lurek.test.exportAll", "Export all entry")

        local cat = lurek.docs.getCatalog()
        lurek.docs.exportAll(cat, dir)

        expect_true(file_exists(completions))
        expect_true(file_exists(hover))
        expect_true(file_exists(signatures))

        os.remove(completions)
        os.remove(hover)
        os.remove(signatures)
        lurek.docs.resetCatalog()
    end)

    -- @covers lurek.docs.exportMarkdown
    it("covers lurek.docs.exportMarkdown", function()
        local path = docs_temp_path("docs_export_markdown", ".md")
        lurek.docs.resetCatalog()
        seed_catalog_entry("lurek.test.exportMarkdown", "Markdown entry")

        local cat = lurek.docs.getCatalog()
        lurek.docs.exportMarkdown(cat, path)

        local content = read_text_file(path)
        expect_true(string.find(content, "# API Reference", 1, true) ~= nil)
        expect_true(string.find(content, "lurek.test.exportMarkdown", 1, true) ~= nil)

        os.remove(path)
        lurek.docs.resetCatalog()
    end)

    -- @covers lurek.docs.exportCheatsheet
    it("covers lurek.docs.exportCheatsheet", function()
        local path = docs_temp_path("docs_export_cheatsheet", ".txt")
        lurek.docs.resetCatalog()
        seed_catalog_entry("lurek.test.exportCheatsheet", "Cheatsheet entry")

        local cat = lurek.docs.getCatalog()
        lurek.docs.exportCheatsheet(cat, path)

        local content = read_text_file(path)
        expect_true(string.find(content, "lurek.test.exportCheatsheet(value)", 1, true) ~= nil)
        expect_true(string.find(content, "Cheatsheet entry", 1, true) ~= nil)

        os.remove(path)
        lurek.docs.resetCatalog()
    end)

    -- @covers lurek.docs.reflectLive
    it("covers lurek.docs.reflectLive", function()
        local reflected = lurek.docs.reflectLive("math")
        expect_type("table", reflected)
        expect_type("table", reflected.math)
        expect_true(#reflected.math > 0)
        expect_type("string", reflected.math[1].name)
        expect_type("string", reflected.math[1].type)
    end)

    -- @covers lurek.docs.reflectTable
    it("covers lurek.docs.reflectTable", function()
        local reflected = lurek.docs.reflectTable({
            alpha = 1,
            beta = function() end,
        }, "demo")

        local seen_alpha = false
        local seen_beta = false
        for _, item in ipairs(reflected) do
            if item.name == "alpha" then
                seen_alpha = true
                expect_equal("demo.alpha", item.qualifiedName)
                expect_equal("integer", item.type)
            elseif item.name == "beta" then
                seen_beta = true
                expect_equal("demo.beta", item.qualifiedName)
                expect_equal("function", item.type)
            end
        end

        expect_true(seen_alpha)
        expect_true(seen_beta)
    end)

    -- @covers Schema:getFields
    it("covers Schema:getFields", function()
        local schema = lurek.docs.schema({
            zeta = "string",
            alpha = { type = "number", required = true },
        }, "field_schema")

        local fields = schema:getFields()
        expect_equal(2, #fields)
        expect_equal("alpha", fields[1])
        expect_equal("zeta", fields[2])
    end)

    -- @covers DocEntry:getQualifiedName
    -- @covers DocEntry:getModule
    -- @covers DocEntry:getKind
    -- @covers DocEntry:getExample
    -- @covers DocEntry:getSince
    -- @covers DocEntry:getDeprecated
    it("DocEntry exposes qualified name kind and optional metadata", function()
        lurek.docs.resetCatalog()
        lurek.docs.describe("lurek.test.meta", "Meta entry")
        local entry = lurek.docs.getCatalog():getEntry("lurek.test.meta")

        expect_not_nil(entry)
        expect_equal("lurek.test.meta", entry:getQualifiedName())
        expect_equal("lurek.test", entry:getModule())
        expect_equal("function", entry:getKind())
        expect_nil(entry:getExample())
        expect_nil(entry:getSince())
        expect_nil(entry:getDeprecated())

        lurek.docs.resetCatalog()
    end)

    -- @covers ApiCatalog:getTypeMethods
    it("covers ApiCatalog:getTypeMethods", function()
        local path = docs_temp_path("docs_type_methods", ".toml")
        write_text_file(path, sample_docs_toml({
            "[[entries]]",
            'name = "Vector"',
            'qualifiedName = "lurek.test.Vector"',
            'module = "test"',
            'kind = "type"',
            'description = "Vector type"',
            "",
            "[[entries]]",
            'name = "len"',
            'qualifiedName = "lurek.test.Vector:len"',
            'module = "test"',
            'kind = "method"',
            'description = "Length method"',
        }))

        local catalog = lurek.docs.loadToml(path)
        local type_names = catalog:getTypes("test")
        local methods = catalog:getTypeMethods("lurek.test.Vector")

        expect_equal(1, #type_names)
        expect_equal("Vector", type_names[1])
        expect_equal(1, #methods)
        expect_equal("len", methods[1]:getName())

        os.remove(path)
    end)

    -- @covers ValidationReport:getMissing
    -- @covers ValidationReport:getPhantom
    -- @covers ValidationReport:getIncomplete
    -- @covers ValidationReport:phantomCount
    -- @covers ValidationReport:incompleteCount
    it("ValidationReport exposes issue lists and count helpers", function()
        local report = lurek.docs.validate()
        local missing = report:getMissing()
        local phantom = report:getPhantom()
        local incomplete = report:getIncomplete()

        expect_type("table", missing)
        expect_type("table", phantom)
        expect_type("table", incomplete)
        expect_true(#missing > 0)
        expect_equal(#phantom, report:phantomCount())
        expect_equal(#incomplete, report:incompleteCount())
    end)

end)

describe("Missing explicit test for lurek.docs.schema", function()
    it("lurek.docs.schema works", function()
        -- @covers lurek.docs.schema
        local schema = lurek.docs.schema({
            name = "string",
        }, "player")
        expect_equal("player", schema:getName())
    end)
end)

describe("Missing explicit test for Schema:validate", function()
    it("Schema:validate works", function()
        -- @covers Schema:validate
        local schema = lurek.docs.schema({
            name = { type = "string", required = true },
        }, "validate_schema")
        local ok, errors = schema:validate({})
        expect_false(ok)
        expect_equal(1, #errors)
        expect_true(string.find(errors[1].message, "required", 1, true) ~= nil)
    end)
end)

describe("Missing explicit test for Schema:check", function()
    it("Schema:check works", function()
        -- @covers Schema:check
        local schema = lurek.docs.schema({
            age = { type = "number", required = true, min = 1, max = 100 },
            class = { type = "string", required = true, enum = { "warrior", "mage" } },
        }, "check_schema")

        expect_false(schema:check({ age = "old", class = "rogue" }))
        expect_true(schema:check({ age = 50, class = "mage" }))
    end)
end)

describe("Missing explicit test for Schema:assert", function()
    it("Schema:assert works", function()
        -- @covers Schema:assert
        local schema = lurek.docs.schema({
            __strict = true,
            level = { type = "integer", required = true, max = 10 },
        }, "assert_schema")

        expect_error(function()
            schema:assert({ level = 11, extra = true })
        end)

        schema:assert({ level = 5 })
    end)
end)

describe("Missing explicit test for Schema:getName", function()
    it("Schema:getName works", function()
        -- @covers Schema:getName
        local schema = lurek.docs.schema({ hp = "number" }, "hero_schema")
        expect_equal("hero_schema", schema:getName())
    end)
end)

test_summary()
