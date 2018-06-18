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

-- Modules --
local utils = require("utils")

-- Corona globals --
local timer = timer
local transition = transition

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local CX, CY = display.contentCenterX - 100, display.contentCenterY + 50

local Count, XScale, YScale = 3, .175, -.175

local FadeParams = { alpha = 1, time = 950 }

local Index

local function DrawCharacter (group, tess)
	for i = group.numChildren, 1, -1 do
		group:remove(i)
	end

	local ti, points, px, py = Index

	repeat
		local what, draw, done = Glyphs[ti]

		if what == "curve_to" then
			local qx, cx = Glyphs[ti + 1], Glyphs[ti + 3]
			local qy, cy = Glyphs[ti + 2], Glyphs[ti + 4]

			for k = 1, Count do
				local t = k / Count
				local s = 1 - t
				local a, b, c = s^2, 2 * s * t, t^2

				points[#points + 1] = CX + (a * px + b * cx + c * qx) * XScale
				points[#points + 1] = CY + (a * py + b * cy + c * qy) * YScale
			end

			ti, px, py = ti + 5, qx, qy
		elseif what == "line_to" then
			ti, px, py = ti + 3, Glyphs[ti + 1], Glyphs[ti + 2]

			points[#points + 1] = CX + px * XScale
			points[#points + 1] = CY + py * YScale
		elseif what == "move_to" then
			ti, px, py = ti + 3, Glyphs[ti + 1], Glyphs[ti + 2]
			draw, points = points, { CX + px * XScale, CY + py * YScale } -- on first move will draw nothing, when points is nil
		else -- 'what' is a character or nil
			done = points -- ignored on opening, when points is nil
			ti, points = ti + 1
		end

		if draw or done then
			tess:AddContour(draw or done)

			if done then
				utils.PolyTris(group, tess, "POSITIVE")

				group.alpha = 0

				transition.to(group, FadeParams)

				Index = what and ti - 1 or 1 -- back up or rewind to put index at next character
			end
		end
	until done
end

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		local tess = utils.GetTess()

		tess:SetOption("CONSTRAINED_DELAUNAY_TRIANGULATION", true) -- can do in any scene, but only showing in this one

		local group = display.newGroup()

		self.view:insert(group)

		self.m_text_group = group

		Index = 1

		self.m_update = timer.performWithDelay(1500, function()
			DrawCharacter(group, tess)
		end, 0)

		DrawCharacter(group, tess)
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		utils.GetTess():SetOption("CONSTRAINED_DELAUNAY_TRIANGULATION", false)

		timer.cancel(self.m_update)

		self.m_text_group:removeSelf()
	end
end

Scene:addEventListener("hide")

return Scene