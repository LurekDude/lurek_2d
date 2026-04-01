# testing_tools — In-Game Testing & Coverage Module

> **Lua namespace:** `luna.testing`
> **C++ module:** `src/modules/testing/`
> **Purpose:** Provides an in-game test framework for game developers to define, discover, run, and report on tests within their Luna2D projects. Supports test scanning with file/tag/marker filtering, assertion helpers, coverage tracking, log analysis, and structured report generation. Designed to integrate with the Luna2D Extension Test Runner extension panel.

## Reimplementation Notes

- Test files are Lua scripts that register test functions via annotations or naming convention (functions starting with `test_` prefix)
- Test scanning walks directories recursively via `luna.filesystem` — only `.lua` files are inspected
- Tags/markers are specified as `-- @tag tagname` comments in test files — multiple tags per file allowed
- Running tests creates an isolated Lua environment per test function to prevent state leakage between tests
- Assertion functions push structured result records onto a results stack — they do NOT throw errors (soft assertions by default)
- Hard assertions (`assertHard*`) throw on failure, aborting the current test immediately
- Coverage tracking instruments loaded test files by counting executed lines — NOT branch coverage
- Log capture redirects `print()` and `io.write()` during test runs into a per-test log buffer
- Report output supports multiple formats: plain text, Lua table, JSON, and DataFrame (if `luna.dataframe` is available)
- The module fires `luna.event` callbacks for test lifecycle events: `teststart`, `testpass`, `testfail`, `testsuitedone`
- Max test files per scan is 10,000 and max test functions per file is 1,000 (CSF-010 guard)
- File paths are validated through `luna.filesystem` (CSF-002 — no raw OS paths)

## Dependencies

- `luna.filesystem` (scanning test directories)
- `luna.event` (test lifecycle events)
- `luna.timer` (timing individual tests)
- `luna.dataframe` (optional — for DataFrame report generation)
- `luna.data` (optional — for JSON export via `encodeJson()`)

---

## Module Functions

### Test Discovery

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `scan` | `directory: string, options?: table` | `TestSuite` | Scan a directory for test files. Options: `{recursive=true, pattern="test_*.lua", tags={}}` |
| `scanFile` | `path: string` | `TestSuite` | Scan a single file for test functions |
| `addTest` | `name: string, fn: function, tags?: table` | `TestSuite` | Manually register a test function with optional tags |
| `fromTable` | `tests: table` | `TestSuite` | Create a suite from a table of `{name, fn, tags?}` entries |

### Test Execution

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `run` | `suite: TestSuite, options?: table` | `TestResults` | Run all tests in a suite. Options: `{tags={}, exclude={}, parallel=false, timeout=30, stopOnFail=false, verbose=false}` |
| `runOne` | `suite: TestSuite, name: string` | `TestResult` | Run a single named test from a suite |
| `runTagged` | `suite: TestSuite, tags: table` | `TestResults` | Run only tests matching ALL specified tags |

### Assertions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `assertEqual` | `actual: any, expected: any, msg?: string` | `boolean` | Soft assert: values are equal (deep comparison for tables) |
| `assertNotEqual` | `actual: any, expected: any, msg?: string` | `boolean` | Soft assert: values differ |
| `assertTrue` | `value: any, msg?: string` | `boolean` | Soft assert: value is truthy |
| `assertFalse` | `value: any, msg?: string` | `boolean` | Soft assert: value is falsy |
| `assertNil` | `value: any, msg?: string` | `boolean` | Soft assert: value is nil |
| `assertNotNil` | `value: any, msg?: string` | `boolean` | Soft assert: value is not nil |
| `assertType` | `value: any, typename: string, msg?: string` | `boolean` | Soft assert: `type(value) == typename` |
| `assertError` | `fn: function, msg?: string` | `boolean` | Soft assert: function throws an error |
| `assertNoError` | `fn: function, msg?: string` | `boolean` | Soft assert: function runs without error |
| `assertApprox` | `actual: number, expected: number, tolerance?: number, msg?: string` | `boolean` | Soft assert: numbers within tolerance (default 1e-6) |
| `assertHardEqual` | `actual: any, expected: any, msg?: string` | — | Hard assert: throws on failure, aborting current test |
| `assertHardTrue` | `value: any, msg?: string` | — | Hard assert: throws if not truthy |

### Coverage

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `enableCoverage` | `directories?: table` | — | Enable line coverage tracking for specified directories (or all loaded test files) |
| `disableCoverage` | — | — | Disable coverage tracking |
| `getCoverage` | — | `CoverageReport` | Get the current coverage data |
| `resetCoverage` | — | — | Clear all coverage data |

### Reporting

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `report` | `results: TestResults, format?: string` | `string \| table` | Generate report. Format: `"text"` (default), `"json"`, `"table"`, `"dataframe"` |
| `summary` | `results: TestResults` | `string` | One-line summary: `"12/15 passed, 2 failed, 1 skipped (0.34s)"` |
| `logAnalysis` | `results: TestResults` | `table` | Analyze test logs: `{warnings={}, errors={}, patterns={}}` |

### Configuration

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `setDefaults` | `options: table` | — | Set default options for `run()`. Options: `{timeout=30, verbose=false, stopOnFail=false}` |
| `getDefaults` | — | `table` | Get current default options |
| `setOutputDir` | `path: string` | — | Set output directory for report files (via `luna.filesystem`) |
| `getOutputDir` | — | `string` | Get current output directory |

---

## Type: TestSuite

A collection of discovered test functions ready for execution.

**Created by:** `luna.testing.scan()`, `luna.testing.scanFile()`, `luna.testing.addTest()`, `luna.testing.fromTable()`

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getTests` | — | `table` | List all test entries: `{name, file, line, tags}` |
| `getTestCount` | — | `number` | Number of tests in the suite |
| `getTestNames` | — | `table<string>` | List of test names |
| `filterByTag` | `tags: table` | `TestSuite` | Return a new suite containing only tests with ALL specified tags |
| `filterByName` | `pattern: string` | `TestSuite` | Return a new suite filtering by Lua pattern on test name |
| `exclude` | `names: table` | `TestSuite` | Return a new suite excluding tests with these names |
| `merge` | `other: TestSuite` | `TestSuite` | Combine two suites into a new suite |
| `getTags` | — | `table<string>` | List all unique tags across all tests |
| `getFiles` | — | `table<string>` | List all unique source files |

---

## Type: TestResults

Aggregated results from running a test suite.

**Created by:** `luna.testing.run()`, `luna.testing.runTagged()`

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getAll` | — | `table<TestResult>` | Get all individual test results |
| `getPassed` | — | `table<TestResult>` | Get only passing results |
| `getFailed` | — | `table<TestResult>` | Get only failing results |
| `getSkipped` | — | `table<TestResult>` | Get only skipped results |
| `getErrors` | — | `table<TestResult>` | Get results that errored (exception during test) |
| `passCount` | — | `number` | Number of passed tests |
| `failCount` | — | `number` | Number of failed tests |
| `skipCount` | — | `number` | Number of skipped tests |
| `errorCount` | — | `number` | Number of errored tests |
| `totalCount` | — | `number` | Total tests executed |
| `totalTime` | — | `number` | Total wall-clock time in seconds |
| `passRate` | — | `number` | Pass percentage (0.0–1.0) |
| `toTable` | — | `table` | Serialize all results to a Lua table |
| `toJSON` | — | `string` | Export results as JSON string |
| `toDataFrame` | — | `DataFrame \| nil` | Convert to DataFrame (requires `luna.dataframe`). Columns: name, status, time, assertions, file, tags |

---

## Type: TestResult

Result of a single test function execution.

**Created by:** `luna.testing.runOne()`

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName` | — | `string` | Test function name |
| `getStatus` | — | `string` | `"pass"`, `"fail"`, `"skip"`, `"error"` |
| `getTime` | — | `number` | Execution time in seconds |
| `getAssertions` | — | `table` | List of assertion results: `{passed, message, actual, expected, line}` |
| `getAssertionCount` | — | `number` | Total assertions checked |
| `getFailedAssertions` | — | `table` | Only failed assertion records |
| `getLog` | — | `string` | Captured stdout/print output during the test |
| `getError` | — | `string \| nil` | Error message if status is `"error"` |
| `getFile` | — | `string` | Source file path |
| `getLine` | — | `number` | Line number of the test function |
| `getTags` | — | `table<string>` | Tags assigned to this test |

---

## Type: CoverageReport

Line coverage data from instrumented test runs.

**Created by:** `luna.testing.getCoverage()`

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getFiles` | — | `table<string>` | List of files with coverage data |
| `getFileCoverage` | `path: string` | `table` | Per-file data: `{totalLines, coveredLines, percentage, uncoveredLineNumbers}` |
| `getTotalCoverage` | — | `number` | Overall coverage percentage (0.0–1.0) |
| `getUncovered` | — | `table` | List of `{file, line}` entries for all uncovered lines |
| `toTable` | — | `table` | Serialize coverage data to a Lua table |
| `toJSON` | — | `string` | Export as JSON |
| `toDataFrame` | — | `DataFrame \| nil` | Convert to DataFrame. Columns: file, totalLines, coveredLines, percentage |

---

## Enums

### Test Status

| Value | Description |
|---|---|
| `"pass"` | All assertions passed |
| `"fail"` | One or more assertions failed |
| `"skip"` | Test was skipped (via `luna.testing.skip()` call) |
| `"error"` | Unhandled error/exception during test execution |

---

## Usage Example

### Basic Test Suite

```lua
-- tests/test_player.lua
-- @tag gameplay
-- @tag unit

function test_player_health()
    local player = Player.new(100)
    luna.testing.assertEqual(player:getHealth(), 100, "initial health")
    player:takeDamage(30)
    luna.testing.assertEqual(player:getHealth(), 70, "after damage")
    player:heal(10)
    luna.testing.assertEqual(player:getHealth(), 80, "after heal")
end

function test_player_death()
    local player = Player.new(50)
    player:takeDamage(100)
    luna.testing.assertTrue(player:isDead(), "should be dead")
    luna.testing.assertEqual(player:getHealth(), 0, "health clamped to 0")
end

function test_player_name()
    local player = Player.new(100)
    player:setName("Hero")
    luna.testing.assertEqual(player:getName(), "Hero")
    luna.testing.assertType(player:getName(), "string")
end
```

### Running Tests

```lua
-- Discover and run all tests
local suite = luna.testing.scan("tests", { recursive = true })
local results = luna.testing.run(suite)
print(luna.testing.summary(results))
-- "3/3 passed, 0 failed, 0 skipped (0.02s)"

-- Run only gameplay-tagged tests
local gameplay = suite:filterByTag({ "gameplay" })
local results2 = luna.testing.run(gameplay)

-- Run a single test
local result = luna.testing.runOne(suite, "test_player_health")
print(result:getStatus())  -- "pass"
```

### Coverage Analysis

```lua
luna.testing.enableCoverage({ "src/" })
local suite = luna.testing.scan("tests")
local results = luna.testing.run(suite)

local coverage = luna.testing.getCoverage()
print(string.format("Total coverage: %.1f%%", coverage:getTotalCoverage() * 100))

for _, file in ipairs(coverage:getFiles()) do
    local fc = coverage:getFileCoverage(file)
    print(string.format("  %s: %.1f%% (%d/%d lines)",
        file, fc.percentage * 100, fc.coveredLines, fc.totalLines))
end
```

### Report Generation

```lua
local suite = luna.testing.scan("tests")
local results = luna.testing.run(suite, { verbose = true })

-- Text report to console
print(luna.testing.report(results, "text"))

-- JSON export
local json = luna.testing.report(results, "json")
luna.filesystem.write("test-results.json", json)

-- DataFrame for further analysis
local df = results:toDataFrame()
if df then
    local failed = df:filter("status", "fail")
    local slowest = df:sortBy("time", true):head(5)
    print("Slowest tests:", slowest:toString())
end

-- Log analysis
local analysis = luna.testing.logAnalysis(results)
for _, warning in ipairs(analysis.warnings) do
    print("WARNING in " .. warning.test .. ": " .. warning.message)
end
```

### Extension Integration

The **Test Runner** panel (`luna2d.editor.testRunner`) provides a visual interface for discovering and running tests.

**Panel features:**
- Scans `testing/tests/*.lua` for test methods via `-- @test` annotations and `function test_*` pattern
- Displays test list grouped by module/file
- Run All, Run Module, Run Single Test buttons
- Generate Test Skeleton for new modules
- Real-time test output streaming

**CLI integration:**
```bash
luna testing --all --isRunner           # Run all tests
luna testing --modules graphics         # Run one module
luna testing --id graphics.newImage     # Run single test
luna testing --all --console            # Console output mode
```

The extension executes tests via `luna testing` CLI commands and parses the structured output to display pass/fail status in the panel.
