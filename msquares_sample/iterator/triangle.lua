--- Some triangle-based iterators over grid regions.

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
local floor = math.floor

-- Modules --
local iterator_utils = require("iterator.utils")

-- Exports --
local M = {}

--
--
--

-- Breaks the result of _a_ / _b_ up into a count and remainder.
local function DivRem (a, b)
    local quot = floor(a / b)

    return quot, a - quot * b
end

-- Has the (possibly degenerate) triangle been traversed?
local function Done (yend, y)
    return y and y >= yend
end

-- Helper to get initial values for a given edge
local function GetValues (edge)
    local dx, dy = edge.dx, edge.dy

    return dx, dy, DivRem(dx, dy)
end

--- Iterator over a triangle on the grid.
-- @function TriangleIter
-- @int x1 Column of point #1.
-- @int y1 Row of point #1.
-- @int x2 Column of point #2.
-- @int y2 Row of point #2.
-- @int x3 Column of point #3.
-- @int y3 Row of point #3.
-- @treturn iterator Supplies row, left and right column at each iteration, top to bottom.
M.TriangleIter = iterator_utils.InstancedAutocacher(function()
    local long, top, low = {}, {}, {}
    local ymid, ledge, redge, lnumer, rnumer, ldx, ldy, lconst, lmod, rdx, rdy, rconst, rmod

    -- Body --
    return function(yend, y)
        local x1, x2 = ledge, redge

        if y then
            y = y + 1

            -- If both current edges are vertical, the third is as well, and updating
            -- the edges can be ignored; otherwise, increment each edge. When the middle
            -- row is crossed, switch the non-long edge state from top to low.
            if ldx ~= 0 or rdx ~= 0 then
                if y == ymid then
                    if ldy < rdy then
                        ldx, ldy, lconst, lmod = GetValues(low)
                    else
                        rdx, rdy, rconst, rmod = GetValues(low)
                    end
                end

                ledge, lnumer = ledge + lconst + floor((lnumer % ldy + lmod) / ldy), lnumer + ldx
                redge, rnumer = redge + rconst + floor((rnumer % rdy + rmod) / rdy), rnumer + rdx
            end
        end

        return y or yend, x1, x2
    end,

    -- Done --
    Done,

    -- Setup --
    function(x1, y1, x2, y2, x3, y3)
        -- Sort the points from top to bottom.
        if y1 > y2 then
            x1, y1, x2, y2 = x2, y2, x1, y1
        end

        if y2 > y3 then
            x2, y2, x3, y3 = x3, y3, x2, y2
        end

        if y1 > y2 then
            x1, y1, x2, y2 = x2, y2, x1, y1
        end

        -- Sort any points on the same row left to right. Mark the middle row.
        if y1 == y2 and x2 < x1 then
            x1, x2 = x2, x1
        end

        if y2 == y3 and x3 < x2 then
            x2, x3 = x3, x2
        end

        ymid = y2

        -- Get the edge deltas: x-deltas are signed, y-deltas are positive whenever put
        -- to use (this is ensured by the one-row special case and middle row test).
        long.dx, long.dy = x3 - x1, y3 - y1
        top.dx, top.dy = x2 - x1, y2 - y1
        low.dx, low.dy = x3 - x2, y3 - y2

        -- Compute the initial edge states. If the low slope is less than the top
        -- slope, the triangle is left-oriented (i.e. the long edge is on the right,
        -- the other two on the left), otherwise right-oriented.
        local lvals, rvals = long, top

        if top.dx * low.dy < low.dx * top.dy then
            lvals, rvals = top, long
        end

        lnumer, ldx, ldy, lconst, lmod = -1, GetValues(lvals)
        rnumer, rdx, rdy, rconst, rmod = -1, GetValues(rvals)

        -- Get the initial edges. If the top row has width, the right edge begins at the
        -- rightmost x-coordinate; otherwise, both edges issue from the same x.
        ledge, redge = x1, y1 ~= y3 and (y1 ~= y2 and x1 or x2) or x3

        -- Iterate until the last row. Handle the case of a one-row triangle.
        return y3, long.dy > 0 and y1 - 1
    end
end)

-- Export the module.
return M
