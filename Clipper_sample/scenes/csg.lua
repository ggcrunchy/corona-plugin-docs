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
local abs = math.abs
local cos = math.cos
local huge = math.huge
local ipairs = ipairs
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

local FillTypeOpts = { fill_type = "NonZero" }

local function BuildStar (cx, cy, radius)
	local path = clipper.NewPath()

	for i = 1, 5 do
		local angle = (i - 1) * 4 * pi / 5 -- 144 degree steps (two-fifths of the circle)
		local x, y = round(cx + radius * cos(angle)), round(cy + radius * sin(angle))

		path:AddPoint(x, y)
	end

	return clipper.SimplifyPolygon(path, FillTypeOpts)
end

-- Create --
function Scene:create ()
	self.sgroup, self.pgroup, self.rgroup = display.newGroup(), display.newGroup(), display.newGroup()

	self.view:insert(self.pgroup)
	self.view:insert(self.rgroup)

	self.lcannon, self.rcannon = { x = -50, vx = 1 }, { x = display.contentWidth + 50, vx = -1 }

    self.clipper = clipper.NewClipper()
end

Scene:addEventListener("create")

local Gravity = 70

local Speed = 145

local KillY = display.contentHeight + 100

local function Fire (cannon)
    cannon.projectile, cannon.time = true, 0

    local angle = pi / 3 + random() * pi / 8

	cannon.ca, cannon.sa, cannon.speed = cos(angle), sin(angle), (.95 + random() * .1) * Speed
end

local Slices = 60

local ProjectilePath = clipper.NewPath()

local ProjectileOpts = { r = .2, g = .2, b = .8, stroke = { .7, width = 2 }}

local function UpdateProjectile (scene, cannon, dt)
	if not cannon.projectile then
		Fire(cannon)
	end

    dt = dt / Slices

    local t, px, py = cannon.time

    ProjectilePath:Clear()

    for _ = 0, Slices do
        local dist = cannon.speed * t
        local x = round(cannon.x + cannon.vx * cannon.ca * dist)
        local y = round(display.contentCenterY - cannon.sa * dist + Gravity * t^2 / 2)

        if x ~= px or y ~= py then
            ProjectilePath:AddPoint(x, y)

            px, py = x, y

            if y > KillY then
                cannon.projectile = false

                break
            end
        end

        t = t + dt
    end

	local proj = BuildStar(0, 0, 15)

    scene.clipper:Clear()
    scene.clipper:AddPaths(scene.star, "SubjectClosed")

    for _, ppath in proj:Paths() do
        local sweep = clipper.MinkowskiSum(ppath, ProjectilePath)

        scene.clipper:AddPaths(sweep, "Clip")
    end

    scene.star = scene.clipper:Execute("Difference")

    clipper.SimplifyPolygons(scene.star)

    if cannon.projectile then
		utils.DrawPolygons(scene.pgroup, BuildStar(px, py, 15), ProjectileOpts)
    end

    cannon.time = t
end

local Drop = { -4, -4, 4, -4, 4, 4, -4, 4 }

local DropSpeed = 50

local DropVX, DropVY = -4, 3

do
    local scale = DropSpeed / math.sqrt(DropVX^2 + DropVY^2)

    DropVX, DropVY = DropVX * scale, DropVY * scale
end

local DropPath = clipper.NewPath()

local DiffOpts = { out = clipper.NewPathArray() }

local Out1, Out2 = clipper.NewPath(), clipper.NewPath()

local function Collided (paths, path)
    local collided = false -- use flag rather than return to let iterators reset

    for _, p in paths:Paths(Out1) do
        local solution = clipper.MinkowskiDiff(p, path, DiffOpts)

        for _, spath in solution:Paths(Out2) do
            if clipper.PointInPolygon(0, 0, spath) then
                collided = true
            end
        end
    end

    return collided
end

local NumSlots = 15

local Left, Right = 5, 1.75 * display.contentWidth

local Space = (Right - Left) / NumSlots

local RainOpts = { r = .7, g = .7, b = .7, stroke = { .4 } }

local function UpdateRain (scene, dt)
    scene.clipper:Clear()
    scene.clipper:AddPaths(scene.star, "SubjectClosed")

    local any = false

    for _, drop in ipairs(scene.drops) do
        if not drop.active then
            drop.x, drop.y, drop.active = Left + random(0, NumSlots) * Space, -10, true
        end

        local x, y = round(drop.x + DropVX * dt), round(drop.y + DropVY * dt)

        if x < -10 or y > KillY then
            drop.active = false
        else
            DropPath:Clear()

            for j = 1, #Drop, 2 do
                DropPath:AddPoint(x + Drop[j], y + Drop[j + 1])
            end

            if Collided(scene.star, DropPath) then
                scene.clipper:AddPath(DropPath, "SubjectClosed")

                drop.active, any = false, true
            else
                utils.DrawSinglePolygon(scene.rgroup, DropPath, RainOpts)

                drop.x, drop.y = x, y
            end
        end
    end

    if any then
        scene.star = scene.clipper:Execute("Union", FillTypeOpts)

        clipper.SimplifyPolygons(scene.star)
    end
end

local StarOpts = { r = .8, g = .8, b = .8, stroke = { .3, .1, .4, width = 1 } }

local function Update (scene, dt)
    utils.ClearGroup(scene.sgroup)
	utils.ClearGroup(scene.pgroup)
	utils.ClearGroup(scene.rgroup)

	UpdateProjectile(scene, scene.lcannon, dt)
	UpdateProjectile(scene, scene.rcannon, dt)
	UpdateRain(scene, dt)

    utils.DrawPolygons(scene.sgroup, scene.star, StarOpts)
end

local DropCount = 40

-- Show --
function Scene:show (event)
	if event.phase == "did" then
        self.drops, self.star = {}, BuildStar(display.contentCenterX, display.contentCenterY, 150)

        for i = 1, DropCount do
            self.drops[i] = {}
        end

		Update(self, 0)

		self.update = timer.performWithDelay(50, function(event)
			local now = event.time / 1000

			Update(self, now - (self.before or now))

			self.before = now
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

        self.lcannon.projectile, self.rcannon.projectile = false, false

        for _, drop in ipairs(self.drops) do
            drop.active = false
        end

        self.before = nil
	end
end

Scene:addEventListener("hide")

return Scene
