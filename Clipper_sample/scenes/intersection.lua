--- Scene that demonstrates basic shape intersection.

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
local cos = math.cos
local pi = math.pi
local sin = math.sin

-- Corona extensions --
local round = math.round

-- Plugins --
local clipper = require("plugin.clipper")

-- Corona globals --
local display = display

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local function GetEllipsePoints (x1, y1, x2, y2)
print("B")
	local path = clipper.NewPath()
print("C", path)
	local cx, cy = .5 * (x1 + x2), .5 * (y1 + y2)
	local ax, ay, px, py = x2 - cx, y2 - cy, cx, cy -- set previous to center, which should be "not the same"
print("E")
	for i = 1, 50 do
		local angle = 2 * i * pi / 50
		local x, y = round(cx + ax * cos(angle)), round(cy + ay * sin(angle))

		if (x - px)^2 + (y - py)^2 > 5 then -- moved at least a few pixels?
			path:AddPoint(x, y)

			px, py = x, y
		end
	end

	return path
end
 
local function DrawPolygons (group, paths, r, g, b, a)
	for i = 1, #paths do
		local path = paths:GetPath(i) -- n.b. copy of path
		local points = {}

		for j = 1, #path do
			local x, y = path:GetPoint(j)

			points[#points + 1] = x
			points[#points + 1] = y
		end

		display.newPolygon(group, display.contentCenterX, display.contentCenterY, points)
	end
end
 
-- Show --
function Scene:show (event)
	if event.phase == "did" then
		-- set up the subject and clip polygons ...
		local sub = clipper.NewPathArray()

	print("A")
		sub:AddPath(GetEllipsePoints(100, 100, 300, 300))
		sub:AddPath(GetEllipsePoints(125, 130, 275, 180))
		sub:AddPath(GetEllipsePoints(125, 220, 275, 270))

	print("A")
		local clp = clipper.NewPathArray()

		clp:AddPath(GetEllipsePoints(140, 70, 220, 320))

	print("A")
		-- display the subject and clip polygons ...
		DrawPolygons(sub, 0x33 / 0xFF, 1, 1, .5)
		DrawPolygons(clp, 1, 1, 0x33 / 0xFF, .5)
		print("B")
--[[
  //get the intersection of the subject and clip polygons ...
  Clipper clpr;
  clpr.AddPaths(sub, ptSubject, true);
  clpr.AddPaths(clp, ptClip, true);
  Paths solution;
  clpr.Execute(ctIntersection, solution, pftEvenOdd, pftEvenOdd);
   
  //finally draw the intersection polygons ...
  DrawPolygons(solution, 0x40808080);
]]
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		
	end
end

Scene:addEventListener("hide")

return Scene