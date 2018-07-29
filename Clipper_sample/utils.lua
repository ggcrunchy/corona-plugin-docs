--- Utilities for Clipper plugin.

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
local huge = math.huge
local max = math.max
local min = math.min
local sqrt = math.sqrt
local select = select
local unpack = unpack

-- Plugins --
local clipper = require("plugin.clipper")
local libtess2 = require("plugin.libtess2")

-- Corona globals --
local display = display

-- Cached module references --
local _AddTriVert_
local _CloseTri_
local _DrawPolygons_
local _GetTess_

-- Exports --
local M = {}

--
--
--

local Tri = {} -- recycle the triangle

function M.AddTriVert (x, y, offset)
	Tri[offset + 1], Tri[offset + 2] = x, y
end

function M.ClearGroup (group)
	for i = group.numChildren, 1, -1 do
		group:remove(i)
	end
end

function M.CloseTri (group)
	Tri[7] = Tri[1]
	Tri[8] = Tri[2]

	display.newLine(group, unpack(Tri))
end

local Out = clipper.NewPath()

local Points = {}

function M.DrawPolygons (group, paths, params)
    local x, y = params and params.x or 0, params and params.y or 0 -- n.b. fallthrough if x or y nil

    for _, path in paths:Paths(Out) do
        local index, xmax, ymax, xmin, ymin = 0, -huge, -huge, huge, huge

        for _, x, y in path:Points() do
            Points[index + 1] = x
            Points[index + 2] = y

            xmax, ymax = max(xmax, x), max(ymax, y)
            xmin, ymin = min(xmin, x), min(ymin, y)
			index = index + 2
        end

        for i = #Points, index + 1, -1 do
			Points[i] = nil
		end

        local poly = display.newPolygon(group, x + .5 * (xmax + xmin), y + .5 * (ymax + ymin), Points)

        if params then
            poly:setFillColor(params.r or 1, params.g or 1, params.b or 1, params.a or 1)

            if params.stroke then
                poly:setStrokeColor(unpack(params.stroke))

                poly.strokeWidth = params.stroke.width or 1
            end
        end
    end
end

function M.DrawSinglePolygon (group, path, params)
	local paths = clipper.NewPathArray()

	paths:AddPath(path)

	_DrawPolygons_(group, paths, params)
end

-- TODO: DrawPolygonsEx, to handle potentially complex cases that need tessellating

local Tess = libtess2.NewTess()

function M.GetTess ()
	return Tess
end

local Elems, Verts = {}, {}

local MeshOpts = { mode = "indexed", indices = {}, vertices = {} }

function M.Mesh (group, tess, rule)
    if tess:Tesselate(rule, "POLYGONS") then
        local indices, vertices = MeshOpts.indices, MeshOpts.vertices

        tess:GetElements(indices, true)
        tess:GetVertices(vertices)

        for i = #indices, tess:GetElementCount() * 3 + 1, -1 do
            indices[i] = nil
        end

        for i = #vertices, tess:GetVertexCount() * 2 + 1, -1 do
            vertices[i] = nil
        end

        local xmax, ymax, xmin, ymin = -huge, -huge, huge, huge

        for i = 1, #vertices, 2 do
            local x, y = vertices[i], vertices[i + 1]

            xmax, ymax = max(x, xmax), max(y, ymax)
            xmin, ymin = min(x, xmin), min(y, ymin)
        end

        display.newMesh(group, (xmax + xmin) / 2, (ymax + ymin) / 2, MeshOpts)
    end
end

function M.Polygon ()
	local verts, xmax, ymax, xmin, ymin = {}, -huge, -huge, huge, huge

	return function(x, y, offset)
		verts[offset + 1], verts[offset + 2] = x, y

		xmax, ymax = max(x, xmax), max(y, ymax)
		xmin, ymin = min(x, xmin), min(y, ymin)
	end, function(group)
		display.newPolygon(group, (xmax + xmin) / 2, (ymax + ymin) / 2, verts)

		verts, xmax, ymax, xmin, ymin = {}, -huge, -huge, huge, huge
	end
end

function M.PolyTris (group, tess, rule)
	if tess:Tesselate(rule, "POLYGONS") then
		local elems = tess:GetElements()
		local verts = tess:GetVertices()
		local add_vert, close = group.add_vert or _AddTriVert_, group.close or _CloseTri_

		for i = 1, tess:GetElementCount() do
			local base, offset = (i - 1) * 3, 0

			for j = 1, 3 do
				local index = elems[base + j]

				add_vert(verts[index * 2 + 1], verts[index * 2 + 2], offset)

				offset = offset + 2
			end

			close(group)
		end
	end
end

_AddTriVert_ = M.AddTriVert
_CloseTri_ = M.CloseTri
_DrawPolygons_ = M.DrawPolygons
_GetTess_ = M.GetTess

return M
