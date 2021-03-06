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
local char = string.char
local floor = math.floor
local random = math.random

-- Modules --
local line = require("iterator.line")

-- Corona globals --
local display = display
local graphics = graphics
local native = native
local timer = timer

-- Exports --
local M = {}

--
--
--

function M.Button (view, text, x, y, action, r, g, b)
    local bgroup = display.newGroup()
    local button = display.newRoundedRect(bgroup, x, y, 100, 25, 12)

    button:addEventListener("touch", function(event)
        if event.phase == "began" then
            action()
        end

        return true
    end)
    button:setFillColor(r, g, b)

    local str = display.newText(bgroup, text, 0, button.y, native.systemFontBold, 15)

    str.anchorX, str.x = 0, x - 35

    view:insert(bgroup)

    return button
end

local function DefRowFunc () end

local function RenderStencil (nrows, c0, r0, w, h, stencil, row_func, touch)
    local index = 1

    for roff = 1, nrows do
        local row = r0 + roff

        if row > h then
            break
        elseif row >= 1 then
            local rbase = (row - 1) * w

            row_func(row)

            for coff = 1, stencil.w do
                local col = c0 + coff

                if col >= 1 and col <= w and stencil[index] == 1 then
                    touch(rbase + col, col, row)
                end

                index = index + 1
            end
        else
            index = index + stencil.w
        end
    end
end

function M.CanvasTouchFunc (w, h, stencil, prep, touch, finish, row_func)
    assert(#stencil % stencil.w == 0, "Missing values")

    local nrows = #stencil / stencil.w
    local col_offset = floor(stencil.w / 2)
    local row_offset = floor(nrows / 2)

    row_func = row_func or DefRowFunc

    return function(event)
        local phase, target = event.phase, event.target

        if phase == "began" or phase == "moved" then
            if phase == "began" then
                display.getCurrentStage():setFocus(target)

                target.touched = true
            elseif not target.touched then
                return false
            end

            local bounds = target.contentBounds
            local c0_cur, c0_prev = floor(event.x - bounds.xMin) - col_offset
            local r0_cur, r0_prev = floor(event.y - bounds.yMin) - row_offset

            prep(target)

            if phase == "moved" then
                c0_prev, r0_prev = target.m_old_c0, target.m_old_r0
            end

            target.m_old_c0, target.m_old_r0 = c0_cur, r0_cur

            for c0, r0 in line.LineIter(c0_prev or c0_cur, r0_prev or r0_cur, c0_cur, r0_cur) do
                RenderStencil(nrows, c0, r0, w, h, stencil, row_func, touch)
            end

            finish(target)
        elseif phase == "ended" or phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)

            target.touched = false
        end

        return true
    end
end

function M.ColorValueFromOctets (r, g, b)
	return {
		bytes = char(r, g, b),
		uint = r * 2^16 + g * 2^8 + b,
		r = r / 0xFF,
		g = g / 0xFF,
		b = b / 0xFF
	}
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

function M.SelectionStrokeHighlighter ()
    local current

    return timer.performWithDelay(150, function()
        if current then
            current:setStrokeColor(random(), random(), random())
        end
    end, 0), function(target, unselect)
        if current and current ~= target then
            unselect(current)
        end

        current = target
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

function M.ShowButton (button, show)
    button.parent.isVisible = not not show
end

return M
