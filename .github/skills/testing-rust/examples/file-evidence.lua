-- Verify file I/O by writing and reading back
lurek.filesystem.write("test_output.txt", "hello")
local content = lurek.filesystem.read("test_output.txt")
expect_equal("hello", content)
