--- Some line-based iterators over grid regions.

--
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
--

-- Standard library imports --
local abs = math.abs
local floor = math.floor

-- Modules --
local iterator_utils = require("iterator.utils")

-- Exports --
local M = {}

--
--
--

--- Iterator over a line on the grid, using [Bresenham's algorithm](http://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm).
-- @function LineIter
-- @int col1 Start column.
-- @int row1 Start row.
-- @int col2 End column.
-- @int row2 End row.
-- @treturn iterator Supplies column, row at each iteration, in order.
M.LineIter = iterator_utils.InstancedAutocacher(function()
    local adx, ady, curx, cury, endx, err, steep, xstep, ystep

    -- Body --
    return function()
        local x, y = curx, cury

        curx = curx + xstep

        if steep then
            x, y = y, x
        end

        err = err - ady

        if err < 0 then
            err, cury = err + adx, cury + ystep
        end

        return x, y
    end,

    -- Done --
    function()
        return curx == endx
    end,

    -- Setup --
    function(x1, y1, x2, y2)
        steep = abs(y2 - y1) > abs(x2 - x1)

        if steep then
            x1, y1 = y1, x1
            x2, y2 = y2, x2
        end

        adx, ady = abs(x2 - x1), abs(y2 - y1)
        curx, cury = x1, y1
        err = floor(adx / 2)

        xstep = x1 <= x2 and 1 or -1
        ystep = y1 <= y2 and 1 or -1

        endx = x2 + xstep
    end
end)

-- Export the module.
return M
