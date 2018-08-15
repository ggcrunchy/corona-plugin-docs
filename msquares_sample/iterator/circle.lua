--- Some circle-based iterators over grid regions.

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
local ipairs = ipairs
local max = math.max
local sort = table.sort

-- Modules --
local iterator_utils = require("iterator.utils")

-- Cached module references --
local _CircleOctant_

-- Exports --
local M = {}

--
--
--

--
local function NegateX (coords, n)
    for i = 1, n, 2 do
        coords[i] = -coords[i]
    end
end

--
local function SwapXY (coords, n)
    for i = 1, n, 2 do
        coords[i], coords[i + 1] = coords[i + 1], coords[i]
    end
end

--
local function SwapXY_Negate (coords, n)
    for i = 1, n, 2 do
        coords[i], coords[i + 1] = -coords[i + 1], -coords[i]
    end
end

-- --
local InitOctantFunc = {
    -- (+y, +x) --
    SwapXY,

    -- (-y, +x) --
    NegateX,

    -- (-x, +y) --
    SwapXY_Negate,

    -- (-x, -y) --
    function(coords, n)
        for i = 2, n, 2 do
            coords[i] = -coords[i]
        end
    end,

    -- (-y, -x) --
    SwapXY,

    -- (+y, -x) --
    NegateX,

    -- (+x, -y) --
    SwapXY_Negate
}

-- --
local Coords

-- --
local SortOctantFunc = {
    -- (+y, +x) --
    { pref = "x", pref_op = ">", alt_op = "<" },

    -- (-y, +x) --
    { pref = "x", pref_op = ">", alt_op = ">" },

    -- (-x, +y) --
    { pref = "y", pref_op = ">", alt_op = ">" },

    -- (-x, -y) --
    { pref = "y", pref_op = ">", alt_op = "<" },

    -- (-y, -x) --
    { pref = "x", pref_op = "<", alt_op = ">" },

    -- (+y, -x) --
    { pref = "x", pref_op = "<", alt_op = "<" },

    -- (+x, -y) --
    { pref = "y", pref_op = "<", alt_op = "<" }
}

--
local function LT (a, b)
    return a < b
end

--
local function GT (a, b)
    return a > b
end

--
for i, form in ipairs(SortOctantFunc) do
    local pdiff, pop = form.pref == "x" and 1 or 0, form.pref_op == "<" and LT or GT
    local adiff, aop = 1 - pdiff, form.alt_op == "<" and LT or GT

    SortOctantFunc[i] = function(i1, i2)
        local pc1, pc2 = Coords[i1 - pdiff], Coords[i2 - pdiff]

        if pc1 == pc2 then
            local ac1, ac2 = Coords[i1 - adiff], Coords[i2 - adiff]

            return aop(ac1, ac2)
        else
            return pop(pc1, pc2)
        end
    end
end

--- DOCME
-- @function Circle
-- @uint radius
-- @treturn iterator X
M.Circle = iterator_utils.InstancedAutocacher(function()
    local coords, indices, oi, i, imax, n, prevx, prevy = {}, {}

    -- Body --
    return function()
        local x, y

        repeat
            i = i + 1

            local index = indices[i]

            x, y = coords[index - 1], coords[index]
        until x ~= prevx or y ~= prevy

        prevx, prevy = x, y

        return x, -y
    end,

    -- Done --
    function()
        if i == imax then
            if n == 0 or oi == 8 then
                return true
            else
                InitOctantFunc[oi](coords, n)

                Coords = coords

                sort(indices, SortOctantFunc[oi])

                oi, i, Coords = oi + 1, 0

                if oi == 8 then
                    imax = imax - 1
                end
            end
        end
    end,

    -- Setup --
    function(radius)
        i, n = 0, 0

        --
        if radius > 1 then
            oi, imax, prevx, prevy = 1, 0

            for x, y in _CircleOctant_(radius) do
                coords[n + 1], coords[n + 2], n = x, -y, n + 2
                indices[imax + 1], imax = n, imax + 1
            end

        --
        else
            if radius == 0 then
                coords[1], coords[2], indices[1], imax = 0, 0, 2, 1
            else
                coords[1], coords[2], indices[1] = 1, 0, 2
                coords[3], coords[4], indices[2] = 0, 1, 4
                coords[5], coords[6], indices[3] = -1, 0, 6
                coords[7], coords[8], indices[4] = 0, -1, 8

                imax = 4
            end
        end

        for i = #indices, imax + 1, -1 do
            indices[i] = nil
        end
    end
end)

--- Iterator over the circular octant from 0 to (approximately) 45 degrees, using the
-- [midpoint circle method](http://en.wikipedia.org/wiki/Midpoint_circle_algorithm).
-- @function CircleOctant
-- @uint radius Circle radius.
-- @treturn iterator Supplies column, row at each iteration, in order.
M.CircleOctant = iterator_utils.InstancedAutocacher(function()
    local x, y, diff, dx, dy

    -- Body --
    return function()
        local xwas, ywas = x, y

        y = y + 1

        if diff >= 0 then
            x, diff, dx = x - 1, diff - dx, dx - 2
        end

        diff, dy = diff + dy, dy + 2

        return xwas, -ywas
    end,

    -- Done --
    function()
        return x < y
    end,

    -- Setup --
    function(radius)
        x, y, diff, dx, dy = radius, 0, 1 - radius, 2 * (radius - 1), 3
    end
end)

--- DOCME
M.CircleSpans = iterator_utils.InstancedAutocacher(function()
    local edges, row = {}

    -- Body --
    return function()
        local ri, edge = row, edges[abs(row) + 1]

        row = row + 1

        if ri >= 0 then
            edges[row] = 0
        end

        return ri, edge
    end,

    -- Done --
    function(radius)
        return row > radius
    end,

    -- Setup --
    function(radius)
        for x, y in _CircleOctant_(radius) do
            y = -y

            edges[x + 1] = max(edges[x + 1] or 0, y)
            edges[y + 1] = max(edges[y + 1] or 0, x)
        end

        row = -radius

        return radius
    end,

    -- Reclaim --
    function(radius)
        for i = max(row, 0), radius do
            edges[i + 1] = 0
        end
    end
end)

-- Cache module members --
_CircleOctant_ = M.CircleOctant

-- Export the module.
return M
