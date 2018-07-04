--- Scene that demonstrates glyph meshes.

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
local unpack = unpack

-- Modules --
local utils = require("utils")

-- Plugins --
local libtess2 = require("plugin.libtess2")

-- Corona globals --
local display = display
local transition = transition

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local Tess

-- Create --
function Scene:create ()
	Tess = libtess2.NewTess()

	Tess:SetOption("CONSTRAINED_DELAUNAY_TRIANGULATION", true)
end

Scene:addEventListener("create")

-- Destroy --
function Scene:destroy ()
	Tess = nil
end

Scene:addEventListener("destroy")

local CX, CY = display.contentCenterX - 100, display.contentCenterY + 50

local FadeInParams = { alpha = 1 }
local FadeOutParams = { alpha = 0, onComplete = display.remove }

local Count, XScale, YScale = 3, .1, -.1

local Line = {}

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		local tgroup = display.newGroup()

		self.view:insert(tgroup)

		self.m_text_group = tgroup

		local font = utils.FontFromText("Mayan")
        local scale = font:ScaleForPixelHeight(15)
        local text = "Mil7kst 88 or 3?!"
        local n, xpos, ypos = #text, 50, 100
		local vis_index = 1

        for char_index = 1, n do
            local ch = text:byte(char_index)
            local advance, lsb = font:GetCodepointHMetrics(ch)
			local shape = font:GetCodepointShape(ch)
			local points, px, py

			for shape_index = 1, #(shape or "") do -- account for non-shapes e.g. spaces
				local what, x, y, cx, cy = shape:GetVertex(shape_index)

				if what == "line_to" then
					local xk, yk = xpos + px * XScale, ypos + py * YScale

					points[#points + 1] = xk
					points[#points + 1] = yk
				elseif what == "curve_to" then
					for i = 1, Count - 1 do
						local t = i / Count
						local s = 1 - t
						local a, b, c = s^2, 2 * s * t, t^2
						local xx, yy = a * px + b * cx + c * x, a * py + b * cy + c * y
						local xk, yk = xpos + xx * XScale, ypos + yy * YScale

						points[#points + 1] = xk
						points[#points + 1] = yk
					end
				else
					if points and #points > 0 then
						Tess:AddContour(points)
					end

					points = {}
				end

				px, py = x, y
			end

			if points and #points > 0 then
				Tess:AddContour(points)
			end

			if Tess:Tesselate("POSITIVE", "POLYGONS", 3) then
				local elems = Tess:GetElements()
				local verts = Tess:GetVertices()
				local polys = display.newGroup()

				tgroup:insert(polys)

				for i = 1, Tess:GetElementCount() do
					local line, base = {}, (i - 1) * 3

					for j = 1, 3 do
						local index = elems[base + j]
						local offset = (j - 1) * 2

						line[offset + 1] = verts[index * 2 + 1] * 2
						line[offset + 2] = verts[index * 2 + 2] * 2
					end

					line[7] = line[1]
					line[8] = line[2]

					display.newLine(polys, unpack(line))
				end

				polys.alpha = 0

				FadeInParams.delay = (vis_index - 1) * 1200
				FadeOutParams.delay = FadeInParams.delay + 950
				
				transition.to(polys, FadeInParams)
				transition.to(polys, FadeOutParams)

				vis_index = vis_index + 1
			end

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