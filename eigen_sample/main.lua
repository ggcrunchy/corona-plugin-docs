--- Test for Eigen plugin.

-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]

-- Plugins --
local eigen = require("plugin.eigen")

local float = eigen.float
local constant = float.Constant(3, 8, 21.2)
local ones = float.Ones(3)
local rand = float.Random(3, 7)
local zero = float.Zero(4)
local b = float.Random(rand:rows(), 1)

print(constant)
print("")
print(ones)
print("")
print(rand)
print("")

local half = rand:cwiseLessThan(.5)

print("Any less than 1/2?", half:any())
print("All less than 1/2?", half:all())
print("")
print(half)
print("")
print("Column-wise, all less than 1/2?")
print(half:all("colwise"))
print("")

print(rand:transpose())
print("")
print(zero)
print("")
local rr = rand:transpose() * rand
print("???", rr:rows(), rr:cols())
print(rr)
print("")
print(b)
print("")

-- local bad = rand * rand (uncomment to trigger assert)

local x = rand:qr_solve(b)

print("!!!", x:rows(), x:cols())
print(x)
print("")
print("?~~", (rand * x):isApprox(b))
print(rand * x)
print("")