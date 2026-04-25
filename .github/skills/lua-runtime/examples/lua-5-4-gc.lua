---@diagnostic disable: undefined-global, param-type-mismatch
-- Generational adds "young" generation to reduce full-collection cost
collectgarbage("generational", minor_threshold, major_threshold)
collectgarbage("incremental")  -- revert to incremental
