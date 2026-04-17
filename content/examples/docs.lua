-- content/examples/docs.lua
-- Lurek2D lurek.docs API Reference
-- Run with: cargo run -- content/examples/docs

-- =============================================================================
-- STUBS: 50 uncovered lurek.docs API item(s)
-- =============================================================================

-- ---- Stub: lurek.docs.scan -----------------------------------------------
--@api-stub: lurek.docs.scan
-- Build a full API catalog from the live lurek.* bindings so the
-- VS Code extension can offer hover docs without an external file.
local catalog = lurek.docs.scan()
print("catalog modules:", #catalog:getModules())

-- ---- Stub: lurek.docs.scanModule -----------------------------------------
--@api-stub: lurek.docs.scanModule
-- Scan only the math module to benchmark per-module scan time during
-- the docs pipeline profiling run.
local math_cat = lurek.docs.scanModule("math")
print("math entries:", math_cat:entryCount())

-- ---- Stub: lurek.docs.loadToml -------------------------------------------
--@api-stub: lurek.docs.loadToml
-- Load a hand-authored TOML doc file that supplements the scanned
-- catalog with parameter descriptions and examples.
local toml_cat = lurek.docs.loadToml("docs/api/math.toml")
print("toml catalog:", toml_cat ~= nil)

-- ---- Stub: lurek.docs.loadAll --------------------------------------------
--@api-stub: lurek.docs.loadAll
-- Load every .toml file in the docs/api directory and merge them into
-- a combined catalog for the full API reference export.
local all_cat = lurek.docs.loadAll("docs/api/")
print("all_cat modules:", #all_cat:getModules())

-- ---- Stub: lurek.docs.describe -------------------------------------------
--@api-stub: lurek.docs.describe
-- Inject a description for a live-scanned entry that has no TOML
-- companion file so it shows up in hover without a separate doc pass.
lurek.docs.describe("lurek.math.clamp", "Clamp value between lo and hi, inclusive.")
print("description set")

-- ---- Stub: lurek.docs.setParamInfo ---------------------------------------
--@api-stub: lurek.docs.setParamInfo
-- Provide parameter metadata for a function that lacks annotations
-- so the VS Code signature helper can show argument names and types.
lurek.docs.setParamInfo("lurek.math.clamp", {
    { name = "x",  type = "number", description = "Value to clamp." },
    { name = "lo", type = "number", description = "Lower bound." },
    { name = "hi", type = "number", description = "Upper bound." },
})
print("param info set")

-- ---- Stub: lurek.docs.setReturnInfo --------------------------------------
--@api-stub: lurek.docs.setReturnInfo
-- Document the return type for an entry so the hover tooltip shows
-- the expected value type alongside the description.
lurek.docs.setReturnInfo("lurek.math.clamp", {
    { type = "number", description = "Clamped value in [lo, hi]." },
})
print("return info set")

-- ---- Stub: lurek.docs.getCatalog -----------------------------------------
--@api-stub: lurek.docs.getCatalog
-- Retrieve the engine's internal catalog built at startup to inspect
-- current coverage without running a new scan.
local internal = lurek.docs.getCatalog()
print("internal catalog:", internal ~= nil)

-- ---- Stub: lurek.docs.resetCatalog ----------------------------------------
--@api-stub: lurek.docs.resetCatalog
-- Flush the internal catalog between hot-reload cycles so stale
-- entries from a previous script run do not persist.
lurek.docs.resetCatalog()
print("catalog reset")

-- ---- Stub: lurek.docs.validate -------------------------------------------
--@api-stub: lurek.docs.validate
-- Run a full validation pass after loading the TOML catalog to ensure
-- every live API entry has documentation before shipping.
local vrep = lurek.docs.validate(catalog)
print("missing entries:", vrep:missingCount())

-- ---- Stub: lurek.docs.validateModule -------------------------------------
--@api-stub: lurek.docs.validateModule
-- Validate only the physics module to report gaps quickly during
-- iterative documentation of new physics bindings.
local vrep_phys = lurek.docs.validateModule("physics", catalog)
print("physics missing:", vrep_phys:missingCount())

-- ---- Stub: lurek.docs.checkStaleness -------------------------------------
--@api-stub: lurek.docs.checkStaleness
-- Scan the Rust source directory for functions that are no longer
-- in the live API to prune phantom entries from the TOML files.
local stale = lurek.docs.checkStaleness(catalog, "src/lua_api/")
print("stale entries:", #stale)

-- ---- Stub: lurek.docs.quality --------------------------------------------
--@api-stub: lurek.docs.quality
-- Compute a quality score for the whole catalog to set a baseline
-- grade before starting the documentation sprint.
local qrep = lurek.docs.quality(catalog)
print(string.format("quality grade: %s (%.2f)", qrep:getGrade(), qrep:getOverallScore()))

-- ---- Stub: lurek.docs.qualityModule --------------------------------------
--@api-stub: lurek.docs.qualityModule
-- Compute a quality score for just the render module to prioritise
-- which binding module to document next.
local qrep_render = lurek.docs.qualityModule("render", catalog)
print("render grade:", qrep_render:getGrade())

-- ---- Stub: lurek.docs.coverage -------------------------------------------
--@api-stub: lurek.docs.coverage
-- Read the total documented count versus live API count to calculate
-- what percentage of the API has documentation.
local covered, total = lurek.docs.coverage(catalog)
print(string.format("coverage: %d / %d (%.0f%%)", covered, total, covered/total*100))

-- ---- Stub: lurek.docs.coverageModule -------------------------------------
--@api-stub: lurek.docs.coverageModule
-- Read per-module coverage to identify the worst-covered binding
-- module and route it to the Doc-Writer agent.
local mc, mt = lurek.docs.coverageModule("audio", catalog)
print(string.format("audio coverage: %d / %d", mc, mt))

-- ---- Stub: lurek.docs.exportCompletions ----------------------------------
--@api-stub: lurek.docs.exportCompletions
-- Write the completions JSON file consumed by the VS Code extension's
-- IntelliSense provider after a full API scan.
lurek.docs.exportCompletions(catalog, "work/temp/completions.json")
print("completions exported")

-- ---- Stub: lurek.docs.exportHover ----------------------------------------
--@api-stub: lurek.docs.exportHover
-- Write the hover JSON file so the VS Code extension shows parameter
-- descriptions and return type on hover.
lurek.docs.exportHover(catalog, "work/temp/hover.json")
print("hover exported")

-- ---- Stub: lurek.docs.exportSignatures -----------------------------------
--@api-stub: lurek.docs.exportSignatures
-- Write the signature-help JSON so the editor shows argument hints
-- while the user types a function call.
lurek.docs.exportSignatures(catalog, "work/temp/signatures.json")
print("signatures exported")

-- ---- Stub: lurek.docs.exportAll ------------------------------------------
--@api-stub: lurek.docs.exportAll
-- Export completions, hover, and signatures in one call to simplify
-- the VS Code extension build pipeline.
lurek.docs.exportAll(catalog, "work/temp/vscode/")
print("all VS Code JSON exported")

-- ---- Stub: lurek.docs.exportMarkdown -------------------------------------
--@api-stub: lurek.docs.exportMarkdown
-- Generate a Markdown reference page from the catalog to include in
-- the docs site and the GitHub wiki.
lurek.docs.exportMarkdown(catalog, "work/temp/lua-api.md")
print("markdown exported")

-- ---- Stub: lurek.docs.exportCheatsheet -----------------------------------
--@api-stub: lurek.docs.exportCheatsheet
-- Export a one-line-per-function cheat sheet so testers can quickly
-- look up a signature without opening the full API reference.
lurek.docs.exportCheatsheet(catalog, "work/temp/cheatsheet.txt")
print("cheatsheet exported")

-- ---- Stub: lurek.docs.schema ---------------------------------------------
--@api-stub: lurek.docs.schema
-- Create a schema validator for the conf.toml table so Configurator
-- can give a descriptive error when a required field is missing.
local sch = lurek.docs.schema({
    title   = { type = "string",  required = true  },
    version = { type = "string",  required = true  },
    width   = { type = "integer", required = false },
}, "GameConfig")
print("schema created:", sch:getName())

-- ---- Stub: lurek.docs.reflectLive ----------------------------------------
--@api-stub: lurek.docs.reflectLive
-- Walk the live lurek.* table at startup to build a mirror of all
-- registered namespaces for the devtools auto-completion panel.
local reflection = lurek.docs.reflectLive("lurek")
print("reflection keys:", reflection ~= nil)

-- ---- Stub: lurek.docs.reflectTable ---------------------------------------
--@api-stub: lurek.docs.reflectTable
-- Reflect an arbitrary Lua configuration table to enumerate its fields
-- and auto-generate TOML doc stubs for unknown config options.
local tbl = { width = 1280, height = 720, title = "My Game" }
local reflected = lurek.docs.reflectTable(tbl, "WindowConf")
print("reflected:", reflected ~= nil)

-- -----------------------------------------------------------------------------
-- ApiCatalog methods
-- -----------------------------------------------------------------------------

-- ---- Stub: ApiCatalog:getModules -----------------------------------------
--@api-stub: ApiCatalog:getModules
-- List all documented module names so the docs site generator can
-- produce one page per module in alphabetical order.
local mods = catalog:getModules()
print("modules:", #mods)
for i = 1, math.min(3, #mods) do print("  module:", mods[i]) end

-- ---- Stub: ApiCatalog:getEntries -----------------------------------------
--@api-stub: ApiCatalog:getEntries
-- Retrieve all physics entries to generate a physics-only reference
-- cheat sheet for the level design team.
local phys_entries = catalog:getEntries("physics")
print("physics entries:", #phys_entries)

-- ---- Stub: ApiCatalog:getEntry -------------------------------------------
--@api-stub: ApiCatalog:getEntry
-- Look up the `lurek.math.lerp` entry to confirm its description was
-- correctly imported from the TOML file.
local lerp_entry = catalog:getEntry("lurek.math.lerp")
print("lerp entry found:", lerp_entry ~= nil)

-- ---- Stub: ApiCatalog:getTypes -------------------------------------------
--@api-stub: ApiCatalog:getTypes
-- List the user-visible types in the animation module to build the
-- type index page of the API reference.
local anim_types = catalog:getTypes("animation")
print("animation types:", #anim_types)

-- ---- Stub: ApiCatalog:getTypeMethods -------------------------------------
--@api-stub: ApiCatalog:getTypeMethods
-- Retrieve all methods on Animation to generate the methods table in
-- the Animation class documentation page.
local anim_methods = catalog:getTypeMethods("lurek.animation.Animation")
print("Animation methods:", #anim_methods)

-- ---- Stub: ApiCatalog:entryCount -----------------------------------------
--@api-stub: ApiCatalog:entryCount
-- Read the total entry count to log a coverage summary headline at
-- the start of each CI documentation pipeline run.
print("total entries:", catalog:entryCount())
print("math entries:", catalog:entryCount("math"))

-- ---- Stub: ApiCatalog:merge ----------------------------------------------
--@api-stub: ApiCatalog:merge
-- Merge the hand-authored TOML catalog into the scanned catalog so
-- parameter descriptions override the auto-generated ones.
local merged_cat = catalog:merge(toml_cat)
print("merged entries:", merged_cat:entryCount())

-- ---- Stub: ApiCatalog:filter ---------------------------------------------
--@api-stub: ApiCatalog:filter
-- Extract only deprecated entries from the catalog to produce a
-- migration guide listing everything scheduled for removal.
local deprecated = catalog:filter(function(e)
    return e:getDeprecated() ~= nil
end)
print("deprecated entries:", deprecated:entryCount())

-- ---- Stub: ApiCatalog:search ---------------------------------------------
--@api-stub: ApiCatalog:search
-- Search the catalog for "lerp" to verify that both math.lerp and
-- tween.lerp entries are returned for the search results panel.
local results = catalog:search("lerp")
print("search 'lerp':", #results)

-- ---- Stub: ApiCatalog:toTable --------------------------------------------
--@api-stub: ApiCatalog:toTable
-- Serialise the catalog to a plain table for piping into the TOML
-- serialiser that generates per-module .toml companion files.
local cat_tbl = catalog:toTable()
print("toTable row count:", #cat_tbl)

-- ---- Stub: ApiCatalog:toJSON ---------------------------------------------
--@api-stub: ApiCatalog:toJSON
-- Convert the catalog to JSON for writing the completions.json file
-- consumed by the VS Code IntelliSense provider.
local cat_json = catalog:toJSON()
print("catalog JSON size:", #cat_json, "bytes")

-- -----------------------------------------------------------------------------
-- DocEntry methods
-- -----------------------------------------------------------------------------

local entry = catalog:getEntry("lurek.math.lerp")
if not entry then
    -- Provide a fallback entry when math.lerp is not yet in the catalog
    local tmp = catalog:getEntries()
    entry = tmp[1]
end

-- ---- Stub: DocEntry:getName ----------------------------------------------
--@api-stub: DocEntry:getName
-- Read the simple name from the entry so the doc site renderer can
-- display it as the function heading without the module prefix.
if entry then print("entry name:", entry:getName()) end

-- ---- Stub: DocEntry:getQualifiedName -------------------------------------
--@api-stub: DocEntry:getQualifiedName
-- Read the qualified name to produce the anchor slug for the API
-- reference page so deep links work across the whole site.
if entry then print("qualified name:", entry:getQualifiedName()) end

-- ---- Stub: DocEntry:getModule --------------------------------------------
--@api-stub: DocEntry:getModule
-- Read the module name to sort entries into the correct section
-- when building the module index page.
if entry then print("module:", entry:getModule()) end

-- ---- Stub: DocEntry:getKind ----------------------------------------------
--@api-stub: DocEntry:getKind
-- Check whether the entry is a function, method, or type so the
-- template knows which rendering layout to apply.
if entry then print("kind:", entry:getKind()) end

-- ---- Stub: DocEntry:getDescription ---------------------------------------
--@api-stub: DocEntry:getDescription
-- Read the description text to populate the hover tooltip in the
-- VS Code extension without loading a separate file.
if entry then print("description:", entry:getDescription()) end

-- ---- Stub: DocEntry:getParameters ----------------------------------------
--@api-stub: DocEntry:getParameters
-- Read the parameter table to generate the Parameters section of the
-- per-function API reference page.
if entry then
    local params = entry:getParameters()
    print("param count:", #params)
end

-- ---- Stub: DocEntry:getReturns -------------------------------------------
--@api-stub: DocEntry:getReturns
-- Read the return table to populate the Returns section of the
-- API reference and VS Code hover card.
if entry then
    local rets = entry:getReturns()
    print("return count:", #rets)
end

-- ---- Stub: DocEntry:getExample -------------------------------------------
--@api-stub: DocEntry:getExample
-- Read the example snippet to embed it in the hover tooltip so
-- developers can see a usage sample without opening the docs site.
if entry then
    local ex = entry:getExample()
    print("has example snippet:", ex ~= nil)
end

-- ---- Stub: DocEntry:getSince ---------------------------------------------
--@api-stub: DocEntry:getSince
-- Read the since version to generate a "New in X.Y" badge on the
-- API reference page for recently added functions.
if entry then
    local since = entry:getSince()
    print("since:", since or "unset")
end

-- ---- Stub: DocEntry:getDeprecated ----------------------------------------
--@api-stub: DocEntry:getDeprecated
-- Read the deprecation message to add a warning banner on the entry
-- page and route it into the migration guide.
if entry then
    local dep = entry:getDeprecated()
    print("deprecated:", dep or "no")
end

-- ---- Stub: DocEntry:getScore ---------------------------------------------
--@api-stub: DocEntry:getScore
-- Read the quality score to rank entries in the worst-coverage
-- report produced by the Doc-Writer agent.
if entry then
    print(string.format("score: %.3f", entry:getScore()))
end

-- ---- Stub: DocEntry:hasDescription ---------------------------------------
--@api-stub: DocEntry:hasDescription
-- Guard rendering so the description section is only emitted when
-- the entry actually has content and not an empty string.
if entry then
    if entry:hasDescription() then
        print("description present")
    else
        print("description missing")
    end
end

-- ---- Stub: DocEntry:hasParameters ----------------------------------------
--@api-stub: DocEntry:hasParameters
-- Skip the Parameters table in the doc template when the entry has
-- no declared parameters to avoid empty section headings.
if entry then
    print("has parameters:", entry:hasParameters())
end

-- ---- Stub: DocEntry:hasReturnType ----------------------------------------
--@api-stub: DocEntry:hasReturnType
-- Skip the Returns section in the doc template when the entry has
-- no declared return type.
if entry then
    print("has return type:", entry:hasReturnType())
end

-- ---- Stub: DocEntry:hasExample -------------------------------------------
--@api-stub: DocEntry:hasExample
-- Guard the "Example" section so it only appears in the rendered page
-- when an actual snippet was supplied.
if entry then
    print("has example:", entry:hasExample())
end

-- -----------------------------------------------------------------------------
-- QualityReport methods
-- -----------------------------------------------------------------------------

-- ---- Stub: QualityReport:getOverallScore ---------------------------------
--@api-stub: QualityReport:getOverallScore
-- Read the overall score to set the documentation quality threshold
-- badge that blocks the CI pipeline when coverage drops below 0.7.
print(string.format("overall score: %.3f", qrep:getOverallScore()))

-- ---- Stub: QualityReport:getGrade ----------------------------------------
--@api-stub: QualityReport:getGrade
-- Read the letter grade to display it in the quality summary banner
-- at the top of the generated Markdown report.
print("grade:", qrep:getGrade())

-- ---- Stub: QualityReport:getModuleScores ---------------------------------
--@api-stub: QualityReport:getModuleScores
-- Read per-module scores to build a sorted ranking of the most and
-- least documented modules for the Doc-Writer sprint board.
local scores = qrep:getModuleScores()
for mod, score in pairs(scores) do
    print(string.format("  %s: %.2f", mod, score))
end

-- ---- Stub: QualityReport:getWorst ----------------------------------------
--@api-stub: QualityReport:getWorst
-- Retrieve the ten worst-scored entries to generate a prioritised
-- work list for the next documentation sprint.
local worst = qrep:getWorst(10)
print("worst entries:", #worst)

-- ---- Stub: QualityReport:getBest -----------------------------------------
--@api-stub: QualityReport:getBest
-- Retrieve the best-scored entries as a set of examples to send to
-- the Player agent for user-experience review.
local best = qrep:getBest(5)
print("best entries:", #best)

-- ---- Stub: QualityReport:getByGrade -------------------------------------
--@api-stub: QualityReport:getByGrade
-- Find all D-grade entries to generate the critical defect list
-- that must be resolved before the next milestone.
local d_grade = qrep:getByGrade("D")
print("D-grade entries:", #d_grade)

-- ---- Stub: QualityReport:getSummary --------------------------------------
--@api-stub: QualityReport:getSummary
-- Read the multi-line summary to embed it in the weekly team report
-- email sent after the documentation pipeline runs.
print("quality summary:\n" .. qrep:getSummary())

-- ---- Stub: QualityReport:toTable -----------------------------------------
--@api-stub: QualityReport:toTable
-- Convert the quality report to a plain table to feed into the
-- analytics dataframe for trend tracking over multiple releases.
local q_tbl = qrep:toTable()
print("quality table rows:", #q_tbl)

-- ---- Stub: QualityReport:toJSON ------------------------------------------
--@api-stub: QualityReport:toJSON
-- Serialise the quality report to JSON to write it to the CI artefacts
-- folder where the dashboard tool reads it.
local q_json = qrep:toJSON()
print("quality JSON size:", #q_json, "bytes")

-- -----------------------------------------------------------------------------
-- Schema methods
-- -----------------------------------------------------------------------------

local conf_data = { title = "Dungeon Run", version = "1.0", width = 1280 }
local bad_data  = { version = "1.0" }  -- missing required `title`

-- ---- Stub: Schema:validate -----------------------------------------------
--@api-stub: Schema:validate
-- Validate the game configuration table on load so a missing required
-- field produces a clear, structured error message.
local result = sch:validate(conf_data)
print("validate conf_data:", result ~= nil)

-- ---- Stub: Schema:check --------------------------------------------------
--@api-stub: Schema:check
-- Quick-check a config table and return a boolean so the boot sequence
-- can branch to a defaults path without catching errors.
print("check good:", sch:check(conf_data))
print("check bad:", sch:check(bad_data))

-- ---- Stub: Schema:assert -------------------------------------------------
--@api-stub: Schema:assert
-- Assert the config table in debug builds to crash early with a clear
-- message if a developer passes a malformed config.
local ok_assert, err = pcall(function() sch:assert(conf_data) end)
print("assert conf_data:", ok_assert and "ok" or err)

-- ---- Stub: Schema:getName ------------------------------------------------
--@api-stub: Schema:getName
-- Read the schema name to include it in the validation error message
-- so developers know which schema rejected their data.
print("schema name:", sch:getName())

-- ---- Stub: Schema:getFields ----------------------------------------------
--@api-stub: Schema:getFields
-- List all declared schema fields to build the auto-generated TOML
-- template that developers fill in for new game configurations.
local fields = sch:getFields()
print("schema fields:", #fields)
for _, f in ipairs(fields) do print("  field:", f) end

-- -----------------------------------------------------------------------------
-- ValidationReport methods
-- -----------------------------------------------------------------------------

-- ---- Stub: ValidationReport:isValid --------------------------------------
--@api-stub: ValidationReport:isValid
-- Check whether the catalog covers the full live API so the CI gate
-- fails the build when documentation has gaps.
print("catalog valid:", vrep:isValid())

-- ---- Stub: ValidationReport:getMissing -----------------------------------
--@api-stub: ValidationReport:getMissing
-- Read the missing-entry list to generate TODO stubs in the TOML
-- companion files for the Doc-Writer to fill in.
local missing = vrep:getMissing()
print("missing:", #missing)
if #missing > 0 then print("  first:", missing[1]) end

-- ---- Stub: ValidationReport:getPhantom -----------------------------------
--@api-stub: ValidationReport:getPhantom
-- Read phantom entries — catalog entries that no longer exist in the
-- live API — to prune stale TOML files.
local phantom = vrep:getPhantom()
print("phantom:", #phantom)

-- ---- Stub: ValidationReport:getIncomplete --------------------------------
--@api-stub: ValidationReport:getIncomplete
-- Read incomplete entries (exist in catalog but have no description or
-- params) to route them to the Doc-Writer sprint backlog.
local incomplete = vrep:getIncomplete()
print("incomplete:", #incomplete)

-- ---- Stub: ValidationReport:missingCount ---------------------------------
--@api-stub: ValidationReport:missingCount
-- Read the count before iterating so the loop can pre-allocate a
-- Lua table of exactly the right size.
print("missing count:", vrep:missingCount())

-- ---- Stub: ValidationReport:phantomCount ---------------------------------
--@api-stub: ValidationReport:phantomCount
-- Read the phantom count to determine whether to run the TOML pruning
-- step or skip it when there is nothing to clean up.
print("phantom count:", vrep:phantomCount())

-- ---- Stub: ValidationReport:incompleteCount ------------------------------
--@api-stub: ValidationReport:incompleteCount
-- Read the incomplete count to set the "incomplete docs" badge on the
-- repository README before a release.
print("incomplete count:", vrep:incompleteCount())

-- ---- Stub: ValidationReport:getSummary -----------------------------------
--@api-stub: ValidationReport:getSummary
-- Read the one-line summary to embed it in the commit message when the
-- CI pipeline auto-commits generated doc stubs.
print("validation summary:", vrep:getSummary())

-- ---- Stub: ValidationReport:toTable --------------------------------------
--@api-stub: ValidationReport:toTable
-- Convert the validation report to a plain table to pipe into a
-- Lua sorting and deduplication routine.
local v_tbl = vrep:toTable()
print("validation table:", #v_tbl)

-- ---- Stub: ValidationReport:toJSON ---------------------------------------
--@api-stub: ValidationReport:toJSON
-- Serialise the report to JSON to write it to the CI artefacts folder
-- where the docs dashboard reads validation status.
local v_json = vrep:toJSON()
print("validation JSON size:", #v_json, "bytes")
