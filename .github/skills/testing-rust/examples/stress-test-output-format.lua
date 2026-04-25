---@diagnostic disable: undefined-global
print(string.format("[PERF] %s: %d ops in %.3fs (%.0f ops/sec)",
    name, count, elapsed, count / elapsed))
