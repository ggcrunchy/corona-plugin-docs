--- Utilities for libtess2 plugin.

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
local assert = assert
local floor = math.floor
local huge = math.huge
local max = math.max
local min = math.min
local sqrt = math.sqrt
local unpack = unpack

-- Plugins --
local libtess2 = require("plugin.libtess2")

-- Corona globals --
local display = display
local graphics = graphics
local system = system
local timer = timer

-- Cached module references --
local _AddTriVert_
local _CancelTimers_
local _CloseTri_
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

function M.CloseTri (group)
	Tri[7] = Tri[1]
	Tri[8] = Tri[2]

	display.newLine(group, unpack(Tri))
end

local function AuxEncode (x, y)
    assert(x >= 0 and x <= 1024, "Invalid x")
    assert(y >= 0 and y <= 1024, "Invalid y")

    x, y = floor(x + .5), floor(y + .5)

    local signed = y == 1024

    if signed then
        y = 1023
    end

    local xhi = floor(x / 64)
    local xlo = x - xhi * 64
    local xy = (1 + (xlo * 1024 + y) * 2^-16) * 2^xhi

    return signed and -xy or xy
end

function M.EncodeTenBitsPair (x, y)
    return AuxEncode(x * 1024, y * 1024)
end

local Tess = libtess2.NewTess()

function M.GetTess ()
	return Tess
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
			local base, offset = (i - 1) * 3, 0 -- for an interesting error (good to know for debugging), hoist offset out of the loop

			for j = 1, 3 do
				local index = elems[base + j]

				add_vert(verts[index * 2 + 1], verts[index * 2 + 2], offset)

				offset = offset + 2
			end

			close(group)
		end
	end
end

local Kernel

function M.SetVertexColorShader (mesh)
	if not Kernel then
		Kernel = { category = "generator", name = "vertex_colors" }

		Kernel.vertex = [[
			P_DEFAULT vec2 TenBitsPair (P_DEFAULT float xy)
			{          
				P_DEFAULT float axy = abs(xy);
				P_DEFAULT float bin = floor(log2(axy));
				P_DEFAULT float num = exp2(16. - bin) * axy - 65536.;
				P_DEFAULT float rest = floor(num / 1024.);
				P_DEFAULT float y = num - rest * 1024.;
				P_DEFAULT float y_bias = step(0., -xy);

				return vec2(bin * 64. + rest, y + y_bias);
			}

			P_DEFAULT vec2 UnitPair (P_DEFAULT float xy)
			{
				return TenBitsPair(xy) / 1024.;
			}

			varying P_COLOR vec4 v_RGBA;

			P_POSITION vec2 VertexKernel (P_POSITION vec2 pos)
			{
				v_RGBA.rg = UnitPair(CoronaTexCoord.x);
				v_RGBA.ba = UnitPair(CoronaTexCoord.y);

				return pos;
			}
		]]

		Kernel.fragment = [[
			varying P_COLOR vec4 v_RGBA;

			P_COLOR vec4 FragmentKernel (P_UV vec2 uv)
			{
				return v_RGBA;
			}
		]]

		graphics.defineEffect(Kernel)
	end

	mesh.fill.effect = "generator.custom.vertex_colors"
end


_AddTriVert_ = M.AddTriVert
_CancelTimers_ = M.CancelTimers
_CloseTri_ = M.CloseTri
_GetTess_ = M.GetTess

return M