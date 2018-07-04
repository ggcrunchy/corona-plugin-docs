--- Scene that demonstrates glyph contours.

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
local random = math.random

-- Modules --
local utils = require("utils")

-- Corona globals --
local display = display
local transition = transition

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local CX, CY = display.contentCenterX - 100, display.contentCenterY + 50

local Count, XScale, YScale = 3, .175, -.175

local FadeInParams = { alpha = 1 }
local FadeOutParams = { alpha = 0, onComplete = display.remove }

local function NewPoint (group, x, y)
	local point = display.newCircle(group, x, y, 2)

	point:setFillColor(random(), random(), random())

	point.alpha, FadeInParams.delay = 0, FadeInParams.delay + 125

	transition.to(point, FadeInParams)
end

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		local tgroup = display.newGroup()

		self.view:insert(tgroup)

		self.m_text_group = tgroup

		local font = utils.FontFromText("Mayan")
        local scale = font:ScaleForPixelHeight(15)
        local text = "3d!7g8mMne"
        local n, xpos, ypos = #text, 50, 200
		local vis_index = 1

		FadeInParams.delay = 0

        for char_index = 1, n do
            local ch, cgroup = text:byte(char_index), display.newGroup()
            local advance, lsb = font:GetCodepointHMetrics(ch)
			local shape = font:GetCodepointShape(ch)
			local points, px, py

			tgroup:insert(cgroup)

			for shape_index = 1, #(shape or "") do -- account for non-shapes e.g. spaces
				local what, x, y, cx, cy = shape:GetVertex(shape_index)

				if what == "line_to" then
					local xk, yk, dx, dy = xpos + px * XScale, ypos + py * YScale, (x - px) / Count, (y - py) / Count

					for _ = 1, Count do
						NewPoint(cgroup, xk, yk)

						xk, yk = xk + dx * XScale, yk + dy * YScale
					end
				elseif what == "curve_to" then
					for i = 1, Count - 1 do
						local t = i / Count
						local s = 1 - t
						local a, b, c = s^2, 2 * s * t, t^2
						local xx, yy = a * px + b * cx + c * x, a * py + b * cy + c * y

						NewPoint(cgroup, xpos + xx * XScale, ypos + yy * YScale)
					end
				else
					NewPoint(cgroup, xpos + x, ypos + y)
				end

				px, py = x, y
			end

			FadeOutParams.delay = FadeInParams.delay + 75

			transition.to(cgroup, FadeOutParams)

            xpos = xpos + advance * scale

            if char_index < n then
                xpos = xpos + scale * font:GetCodepointKernAdvance(ch, text:byte(char_index + 1))
            end
		end
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		self.m_text_group:removeSelf()
	end
end

Scene:addEventListener("hide")

return Scene