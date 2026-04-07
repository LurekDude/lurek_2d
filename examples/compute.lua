-- examples/compute.lua
-- luna.compute — Multi-dimensional numerical arrays for batch math operations.
-- Dense NdArray containers backed by typed f32/f64/i32/i64/u8 storage.
-- All luna.compute API methods demonstrated with code and comments.

-- ¦¦ Array Creation ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

-- newArray(shape, dtype?) › Array
-- shape is a table {rows, cols, ...} for N-dimensional arrays.
-- dtype: "f32" (default) | "f64" | "i32" | "i64" | "u8"
local mat2d  = luna.compute.newArray({4, 4}, "f32")     -- 4×4 float matrix
local vec1d  = luna.compute.newArray({100}, "f64")       -- 100-element double vector
local vol3d  = luna.compute.newArray({8, 8, 8}, "i32")  -- 8×8×8 integer volume

-- zeros(shape, dtype?) › Array  — all elements initialised to 0
local zero_mat = luna.compute.zeros({3, 3})       -- 3×3 zero matrix

-- ones(shape, dtype?) › Array  — all elements initialised to 1
local ones_vec = luna.compute.ones({16}, "f32")   -- 16-element vector of ones

-- range(start, stop, step?, dtype?) › Array  — linspace/arange style 1D array
local seq = luna.compute.range(0, 10, 1)          -- {0,1,2,3,4,5,6,7,8,9}
local lin = luna.compute.range(0.0, 1.0, 0.1)     -- 10 evenly spaced floats

-- fromTable(data, shape?, dtype?) › Array  — create from a flat or nested Lua table
local a = luna.compute.fromTable({1,2,3,4,5,6}, {2,3})   -- 2×3 matrix
local b = luna.compute.fromTable({1.5, 2.5, 3.5})         -- flat 1D array

-- ¦¦ Shape and Metadata ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

-- getShape() › table  — {dim0, dim1, ...}
local shape = mat2d:getShape()        -- {4, 4}

-- getDimensions() › integer...  — unpacks shape components
local rows, cols = mat2d:getDimensions()   -- 4, 4

-- getSize() › integer  — total element count (product of all dimensions)
local sz = mat2d:getSize()            -- 16

-- getDataType() › string  — "f32", "f64", "i32", "i64", or "u8"
local dtype = mat2d:getDataType()     -- "f32"

-- isOnGPU() › boolean  (future compute offload; always false in current builds)
local gpu = mat2d:isOnGPU()

-- ¦¦ Element Access ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

-- get(idx0, idx1, ...) › number  — 0-based multi-dimensional index
mat2d:set(0, 0, 1.0)   -- top-left element
mat2d:set(1, 2, 5.0)   -- row 1, col 2
local v = mat2d:get(1, 2)   -- 5.0

-- For 1D arrays:
vec1d:set(0, 3.14)
local pi = vec1d:get(0)   -- 3.14

-- ¦¦ Conversion ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

-- toTable() › table  — flat Lua table of all values in row-major order
local flat = a:toTable()   -- { 1, 2, 3, 4, 5, 6 }

-- ¦¦ Shape Operations ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

-- reshape(shape) › Array  — new view with different shape (element count must match)
local row_vec = a:reshape({6})        -- 1×6 from 2×3
local col_mat = row_vec:reshape({3, 2})  -- 3×2

-- clone() › Array  — deep copy
local copy = mat2d:clone()

-- transpose() › Array  — swap all dimensions (2D: swap rows/cols)
local transposed = a:transpose()   -- shape {3, 2}

-- ¦¦ In-Place Modification ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

-- fill(value) › nil  — overwrite every element
mat2d:fill(0.0)   -- zero out the matrix
mat2d:fill(1.0)   -- set to identity base

-- ¦¦ Element-Wise Arithmetic (returns new Array) ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

-- add(other) — other is a scalar number or another compatible Array
local m2 = mat2d:add(5.0)       -- add 5 to every element
local m3 = mat2d:sub(2.0)       -- subtract 2
local m4 = mat2d:mul(0.5)       -- multiply by 0.5
local m5 = mat2d:div(2.0)       -- divide by 2

-- Or array + array (same shape required):
local sum = mat2d:add(copy)

-- ¦¦ Math Functions (returns new Array) ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

-- pow(exponent) › Array
local squared = mat2d:pow(2)

-- sqrt() › Array  — element-wise square root
local roots = squared:sqrt()

-- abs() › Array  — absolute value
local mag = mat2d:abs()

-- neg() › Array  — negate all elements
local neg = mat2d:neg()

-- clamp(min, max) › Array  — element-wise clamp
local clamped = mat2d:clamp(0.0, 1.0)

-- threshold(value) › Array  — binary mask: 1.0 where element > value, else 0.0
local mask = mat2d:threshold(0.5)

-- ¦¦ Typical Use Cases ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

-- Heatmap / probability grid
local heatmap = luna.compute.zeros({64, 64})
heatmap:set(32, 32, 1.0)   -- set centre to max

-- Normalised float buffer for custom shader upload
local weights = luna.compute.fromTable({0.25, 0.5, 1.0, 0.75})
local norm = weights:div(weights:getSize())  -- normalise

-- Batch distance calculation
local xs = luna.compute.range(0, 10)
local ds = xs:mul(xs)   -- squared distances from origin

-- Intensity array for a 3×3 blur kernel
local kernel = luna.compute.fromTable({
    1, 2, 1,
    2, 4, 2,
    1, 2, 1,
}, {3, 3})
local norm_kernel = kernel:div(16.0)  -- normalise to sum=1
local flat_k = norm_kernel:toTable()
