-- examples/compute.lua
-- luna.compute � Multi-dimensional numerical arrays for batch math operations.
-- Dense NdArray containers backed by typed f32/f64/i32/i64/u8 storage.
-- All luna.compute API methods demonstrated with code and comments.
-- This file is documentation code, not a runnable game.

-- �� Array Creation ������������������������������������������������������������

-- newArray(shape, dtype?) � Array
-- shape is a table {rows, cols, ...} for N-dimensional arrays.
-- dtype: "f32" (default) | "f64" | "i32" | "i64" | "u8"
local mat2d  = luna.compute.newArray({4, 4}, "f32")     -- 4�4 float matrix
local vec1d  = luna.compute.newArray({100}, "f64")       -- 100-element double vector
local vol3d  = luna.compute.newArray({8, 8, 8}, "i32")  -- 8�8�8 integer volume

-- zeros(shape, dtype?) � Array  � all elements initialised to 0
local zero_mat = luna.compute.zeros({3, 3})       -- 3�3 zero matrix

-- ones(shape, dtype?) � Array  � all elements initialised to 1
local ones_vec = luna.compute.ones({16}, "f32")   -- 16-element vector of ones

-- range(start, stop, step?, dtype?) � Array  � linspace/arange style 1D array
local seq = luna.compute.range(0, 10, 1)          -- {0,1,2,3,4,5,6,7,8,9}
local lin = luna.compute.range(0.0, 1.0, 0.1)     -- 10 evenly spaced floats

-- fromTable(data, shape?, dtype?) � Array  � create from a flat or nested Lua table
local a = luna.compute.fromTable({1,2,3,4,5,6}, {2,3})   -- 2�3 matrix
local b = luna.compute.fromTable({1.5, 2.5, 3.5})         -- flat 1D array

-- �� Shape and Metadata ��������������������������������������������������������

-- getShape() � table  � {dim0, dim1, ...}
local shape = mat2d:getShape()        -- {4, 4}

-- getDimensions() � integer...  � unpacks shape components
local rows, cols = mat2d:getDimensions()   -- 4, 4

-- getSize() � integer  � total element count (product of all dimensions)
local sz = mat2d:getSize()            -- 16

-- getDataType() � string  � "f32", "f64", "i32", "i64", or "u8"
local dtype = mat2d:getDataType()     -- "f32"

-- isOnGPU() � boolean  (future compute offload; always false in current builds)
local gpu = mat2d:isOnGPU()

-- �� Element Access ������������������������������������������������������������

-- get(idx0, idx1, ...) � number  � 0-based multi-dimensional index
mat2d:set(0, 0, 1.0)   -- top-left element
mat2d:set(1, 2, 5.0)   -- row 1, col 2
local v = mat2d:get(1, 2)   -- 5.0

-- For 1D arrays:
vec1d:set(0, 3.14)
local pi = vec1d:get(0)   -- 3.14

-- �� Conversion ����������������������������������������������������������������

-- toTable() � table  � flat Lua table of all values in row-major order
local flat = a:toTable()   -- { 1, 2, 3, 4, 5, 6 }

-- �� Shape Operations ����������������������������������������������������������

-- reshape(shape) � Array  � new view with different shape (element count must match)
local row_vec = a:reshape({6})        -- 1�6 from 2�3
local col_mat = row_vec:reshape({3, 2})  -- 3�2

-- clone() � Array  � deep copy
local copy = mat2d:clone()

-- transpose() � Array  � swap all dimensions (2D: swap rows/cols)
local transposed = a:transpose()   -- shape {3, 2}

-- �� In-Place Modification ����������������������������������������������������

-- fill(value) � nil  � overwrite every element
mat2d:fill(0.0)   -- zero out the matrix
mat2d:fill(1.0)   -- set to identity base

-- �� Element-Wise Arithmetic (returns new Array) �������������������������������

-- add(other) � other is a scalar number or another compatible Array
local m2 = mat2d:add(5.0)       -- add 5 to every element
local m3 = mat2d:sub(2.0)       -- subtract 2
local m4 = mat2d:mul(0.5)       -- multiply by 0.5
local m5 = mat2d:div(2.0)       -- divide by 2

-- Or array + array (same shape required):
local sum = mat2d:add(copy)

-- �� Math Functions (returns new Array) ���������������������������������������

-- pow(exponent) � Array
local squared = mat2d:pow(2)

-- sqrt() � Array  � element-wise square root
local roots = squared:sqrt()

-- abs() � Array  � absolute value
local mag = mat2d:abs()

-- neg() � Array  � negate all elements
local neg = mat2d:neg()

-- clamp(min, max) � Array  � element-wise clamp
local clamped = mat2d:clamp(0.0, 1.0)

-- threshold(value) � Array  � binary mask: 1.0 where element > value, else 0.0
local mask = mat2d:threshold(0.5)

-- �� Typical Use Cases ���������������������������������������������������������

-- Heatmap / probability grid
local heatmap = luna.compute.zeros({64, 64})
heatmap:set(32, 32, 1.0)   -- set centre to max

-- Normalised float buffer for custom shader upload
local weights = luna.compute.fromTable({0.25, 0.5, 1.0, 0.75})
local norm = weights:div(weights:getSize())  -- normalise

-- Batch distance calculation
local xs = luna.compute.range(0, 10)
local ds = xs:mul(xs)   -- squared distances from origin

-- Intensity array for a 3�3 blur kernel
local kernel = luna.compute.fromTable({
    1, 2, 1,
    2, 4, 2,
    1, 2, 1,
}, {3, 3})
local norm_kernel = kernel:div(16.0)  -- normalise to sum=1
local flat_k = norm_kernel:toTable()

-- ─── Array ─────────────────────────────────────────────────────────────────────

local all = array:all()  -- Returns true if all elements are nonzero
local any = array:any()  -- Returns true if any element is nonzero
local argmax = array:argmax()  -- Returns the 1-based flat index of the maximum element
local argmin = array:argmin()  -- Returns the 1-based flat index of the minimum element
local bitwise_and = array:bitwiseAnd(array)  -- Bitwise AND of two Int32 arrays
local bitwise_l_shift = array:bitwiseLShift(1)  -- Bitwise left shift of an Int32 array
local bitwise_not = array:bitwiseNot()  -- Bitwise NOT of an Int32 array
local bitwise_or = array:bitwiseOr(array)  -- Bitwise OR of two Int32 arrays
local bitwise_r_shift = array:bitwiseRShift(1)  -- Bitwise right shift of an Int32 array
local bitwise_xor = array:bitwiseXor(array)  -- Bitwise XOR of two Int32 arrays
local convolve2_d = array:convolve2D(array)  -- 2D convolution with zero-padding
local count_non_zero = array:countNonZero()  -- Returns the count of nonzero elements
local dilate = array:dilate(1)  -- Morphological dilation with a diamond structuring element
local dot = array:dot(array)  -- Dot product of two 1D arrays
local erode = array:erode(1)  -- Morphological erosion with a diamond structuring element
local matmul = array:matmul(array)  -- Matrix multiplication of two 2D arrays
local max = array:max()  -- Maximum of all elements, or along an axis (1-based)
local mean = array:mean()  -- Mean of all elements, or along an axis (1-based)
local min = array:min()  -- Minimum of all elements, or along an axis (1-based)
local sum = array:sum()  -- Sum of all elements, or along an axis (1-based)
array:type()
array:typeOf("myName")
