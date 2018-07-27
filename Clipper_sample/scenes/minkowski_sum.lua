--- Scene that demonstrates tessellation as polygons with more than three sides.

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
local sqrt = math.sqrt
local unpack = unpack

-- Plugins --
local clipper = require("plugin.clipper")

-- Modules --
local utils = require("utils")

-- Corona extensions --
local round = math.round

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local YOffset = -150

local Sigma = { 300, 400, 100, 400, 200, 300, 100, 200, 300, 200 }

function Scene:create ()
	self.brush = { 4, -6 } .. { 6, -6 } .. { -4, 6 } .. { -6, 6 } .. clipper.ToPath

	local segments, length, px, py = {}, 0, Sigma[1], Sigma[2]

	for i = 3, #Sigma, 2 do
		local qx, qy = Sigma[i], Sigma[i + 1]
		local seg_length = sqrt((qx - px)^2 + (qy - py)^2)

		segments[#segments + 1] = seg_length
		length, px, py = length + seg_length, qx, qy
	end

	self.segments, segments.total_length = segments, length

	local path = display.newLine(self.view, unpack(Sigma))

	path:setStrokeColor(1, 0, 0)
	path:translate(0, YOffset)

	self.pgroup = display.newGroup()

	self.view:insert(self.pgroup)
end

Scene:addEventListener("create")

local Speed = 75

local BrushOpts = { r = 0, b = 0, a = .3 }
local SigmaOpts = { a = .7, y = YOffset, stroke = { .2 } }

local function Update (event)
	local pgroup = Scene.pgroup

	utils.ClearGroup(pgroup)

	local segments, seconds, sigma, bx, by = Scene.segments, event.time / 1000
	local dist, px, py = (seconds * Speed) % segments.total_length, Sigma[1], Sigma[2]

	for i = 3, #Sigma, 2 do
		local qx, qy, length = Sigma[i], Sigma[i + 1], segments[.5 * (i - 1)]

		if dist < length then
			local t = dist / length
			local s = 1 - t

			bx, by = round(px * s + qx * t), round(py * s + qy * t)

			if not sigma and abs(bx - Sigma[1]) + abs(by - Sigma[2]) > 3 then -- forgo sigma when very close to start
				sigma = clipper.NewPath()

				sigma:AddPoint(px, py)
			end

			break
		elseif not sigma then
			sigma = clipper.NewPath()

			sigma:AddPoint(px, py)
		end

		dist, px, py = dist - length, qx, qy
		bx, by = qx, qy -- just in case it lands on very end (and we leave the loop)

		sigma:AddPoint(qx, qy)
	end

	if sigma then
		sigma:AddPoint(bx, by)

		utils.DrawPolygons(pgroup, clipper.MinkowskiSum(Scene.brush, sigma), SigmaOpts)
	end

	BrushOpts.x, BrushOpts.y = bx, by + YOffset

	utils.DrawSinglePolygon(pgroup, Scene.brush, BrushOpts)
end

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		Runtime:addEventListener("enterFrame", Update)
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		Runtime:removeEventListener("enterFrame", Update)

		utils.ClearGroup(self.pgroup)
	end
end

Scene:addEventListener("hide")

return Scene
