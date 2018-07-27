--- Scene that demonstrates constructive solid geometry.

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
local random = math.random
local sin = math.sin

-- Modules --
local utils = require("utils")

-- Plugins --
local clipper = require("plugin.clipper")

-- Corona extensions --
local round = math.round

-- Corona globals --
local timer = timer

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local function BuildStar (cx, cy, radius)
	local path = clipper.NewPath()

	for i = 1, 5 do
		local angle = (i - 1) * 4 * pi / 5 -- 144 degree steps (two-fifths of the circle)
		local x, y = round(cx + radius * cos(angle)), round(cy + radius * sin(angle))

		path:AddPoint(x, y)
	end

	return clipper.SimplifyPolygon(path)
end

-- Create --
function Scene:create ()
	self.sgroup, self.pgroup, self.rgroup = display.newGroup(), display.newGroup(), display.newGroup()

	self.view:insert(self.pgroup)
	self.view:insert(self.rgroup)

	self.lcannon, self.rcannon = { x = -50, vx = 1 }, { display.contentWidth + 50, vx = -1 }
end

Scene:addEventListener("create")

local Gravity = 10

local Speed = 500

local KillY = display.contentHeight + 100

local function Fire (cannon)
	cannon.projectile, cannon.time = true, 0
	cannon.angle, cannon.speed = pi / 3 + random() * pi / 8, (.95 + random() * .1) * Speed
end

local function UpdateProjectile (scene, cannon, dt)
	if not cannon.projectile then
		Fire(cannon)
	end

	-- traj: minkowski sum of star over range
	-- update star: star - traj
	-- below KillY? remove
end

local function UpdateRain (scene, dt)
	-- iterate
		-- move small particles
		-- minkowski diff with star
			-- contains origin?
				-- union with star
				-- kill
		-- below KillY? remove
end

local function Update (scene, dt)
	utils.ClearGroup(scene.pgroup)
	utils.ClearGroup(scene.rgroup)

	UpdateProjectile(scene, scene.lcannon, dt)
	UpdateProjectile(scene, scene.rcannon, dt)
	UpdateRain(scene, dt)

	-- redraw star
end

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		self.star = BuildStar(display.contentCenterX, display.contentCenterY, 150)

		utils.DrawPolygons(self.sgroup, self.star)

		self.now = 0

		Update(self, 0)

		self.update = timer.performWithDelay(150, function(event)
			local now = event.time / 1000

			Update(self, now - self.now)

			self.now = now
		end, 0)
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		utils.ClearGroup(self.sgroup)
		utils.ClearGroup(self.pgroup)
		utils.ClearGroup(self.rgroup)
		timer.cancel(self.update)
	end
end

Scene:addEventListener("hide")

return Scene