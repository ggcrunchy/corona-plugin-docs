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
local graphics = graphics
local timer = timer

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local FillTypeOpts = { fill_type = "NonZero" }

local function BuildStar (cx, cy, radius, how)
	local path = clipper.NewPath()

	for i = 1, 5 do
		local angle = (i - 1) * 4 * pi / 5 -- 144 degree steps (two-fifths of the circle)
		local x, y = round(cx + radius * cos(angle)), round(cy + radius * sin(angle))

		path:AddPoint(x, y)
	end

	return how == "raw" and path or clipper.SimplifyPolygon(path, FillTypeOpts)
end

local DropCount = 60

local HalfDim = 4

-- Create --
function Scene:create ()
	self.sgroup, self.pgroup, self.rgroup = display.newGroup(), display.newGroup(), display.newGroup()

	self.view:insert(self.sgroup)
	self.view:insert(self.pgroup)
	self.view:insert(self.rgroup)

	for i = 1, DropCount do
		local drop = display.newRect(self.rgroup, 0, 0, 2 * HalfDim, 2 * HalfDim)

		drop:setFillColor(.7)
		drop:setStrokeColor(.4)

		drop.strokeWidth = 1
	end
	
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

local Slices = 10

local ProjectilePath = clipper.NewPath()

local ProjectileOpts = { r = .2, g = .2, b = .8, stroke = { .7, width = 2 }}

local MinkowskiOpts = { out = clipper.NewPathArray() }

local function AuxUpdateProjectiles (scene, cannon, dt)
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

	local proj = BuildStar(0, 0, 15, "raw")
    local sweep = clipper.MinkowskiSum(proj, ProjectilePath, MinkowskiOpts)

    scene.clipper:AddPaths(sweep, "ClipClosed")

    if cannon.projectile then
		utils.DrawPolygons(scene.pgroup, BuildStar(px, py, 15), ProjectileOpts)
    end

    cannon.time = t
end

local function UpdateProjectiles (scene, dt)
    scene.clipper:Clear()
    scene.clipper:AddPaths(scene.star, "SubjectClosed")

	AuxUpdateProjectiles(scene, scene.lcannon, dt)
	AuxUpdateProjectiles(scene, scene.rcannon, dt)

	scene.star = scene.clipper:Execute("Difference")
end

local Drop = { -HalfDim, -HalfDim, HalfDim, -HalfDim, HalfDim, HalfDim, -HalfDim, HalfDim }

local DropSpeed = 70

local DropVX, DropVY = -4, 3

do
    local scale = DropSpeed / math.sqrt(DropVX^2 + DropVY^2)

    DropVX, DropVY = DropVX * scale, DropVY * scale
end

local DropPath = clipper.NewPath()

local DiffOpts = { out = clipper.NewPathArray() }

local Out1, Out2 = clipper.NewPath(), clipper.NewPath()

local function Collided (paths, x, y)
    local collided = false -- use flag rather than return to let iterator reset

    for _, p in paths:Paths(Out1) do
		collided = collided or clipper.PointInPolygon(x, y, p) -- somewhat crude but MinkowskiDiff() hits the frame rate pretty hard
							or clipper.PointInPolygon(x - HalfDim, y - HalfDim, p)
							or clipper.PointInPolygon(x + HalfDim, y - HalfDim, p)
							or clipper.PointInPolygon(x - HalfDim, y + HalfDim, p)
							or clipper.PointInPolygon(x + HalfDim, y + HalfDim, p)
    end

    return collided
end

local NumSlots = 25

local Left, Right = 5, 1.75 * display.contentWidth

local Space = (Right - Left) / NumSlots

local RainOpts = { r = .7, g = .7, b = .7, stroke = { .4 } }

local function UpdateRain (scene, dt)
    scene.clipper:Clear()
    scene.clipper:AddPaths(scene.star, "SubjectClosed")

    local any = false

    for i = 1, scene.rgroup.numChildren do
		local drop = scene.rgroup[i]

        if not drop.isVisible then
            drop.x, drop.y, drop.isVisible = Left + random(0, NumSlots) * Space, -10, true
			drop.vx, drop.vy = (.75 + random() * .5) * DropVX, (.75 + random() * .5) * DropVY
        end

        local x, y = round(drop.x + drop.vx * dt), round(drop.y + drop.vy * dt)

        if x < -10 or y > KillY then
            drop.isVisible = false
        elseif Collided(scene.star, x, y) then
			DropPath:Clear()

			for j = 1, #Drop, 2 do
				DropPath:AddPoint(x + Drop[j], y + Drop[j + 1])
			end

			scene.clipper:AddPath(DropPath, "SubjectClosed")

			drop.isVisible, any = false, true
		else
			drop.x, drop.y = x, y
		end
    end

    if any then
        scene.star = scene.clipper:Execute("Union", FillTypeOpts)
    end
end

local StarOpts = { r = .8, g = .8, b = .8, stroke = { .3, .1, .4, width = 1 } }

local Tess = utils.GetTess()

local ShadeMesh

local function MakeShadeMesh ()
    local kernel = { category = "generator", name = "shade_mesh" }

    kernel.fragment = [[
		// Created by inigo quilez - iq/2013
		// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
		P_POSITION float hash1 (P_UV float n)
		{
		#if !defined(GL_ES) || defined(GL_FRAGMENT_PRECISION_HIGH)
			return fract(sin(n) * 43758.5453);
		#else
			return fract(sin(n) * 43.7585453);
		#endif
			// TODO: Find a way to detect the precision and tune these!
		}
		// Created by inigo quilez - iq/2013
		// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
		P_POSITION float IQ (P_POSITION vec2 x)
		{
			P_POSITION vec2 p = floor(x);
			P_POSITION vec2 f = fract(x);
			f = f * f * (3.0 - 2.0 * f);
			P_POSITION float n = p.x + p.y * 57.0;
			return mix(mix(hash1(n +  0.0), hash1(n +  1.0), f.x),
					   mix(hash1(n + 57.0), hash1(n + 58.0), f.x), f.y);
		}
		
        P_COLOR vec4 FragmentKernel (P_UV vec2 uv)
        {
            return vec4(IQ(gl_FragCoord.xy), IQ(uv.yx), IQ(gl_FragCoord.zw), 1.);
        }
    ]]

    graphics.defineEffect(kernel)

    return "generator.custom.shade_mesh"
end

local Buffer = clipper.NewBuffer()

local function Update (scene, dt)
    utils.ClearGroup(scene.sgroup)
	utils.ClearGroup(scene.pgroup)

	UpdateProjectiles(scene, dt)
	UpdateRain(scene, dt)

    clipper.SimplifyPolygons(scene.star)

    for _, path in scene.star:Paths(Out1) do -- n.b. will not conflict with use above
        Buffer:Convert(path, "float") -- MUCH faster than gathering points into arrays
        Tess:AddContour(Buffer)
    end

    utils.Mesh(scene.sgroup, Tess, "ODD")

    ShadeMesh = ShadeMesh or MakeShadeMesh()

    for i = 1, scene.sgroup.numChildren do
        scene.sgroup[i].fill.effect = ShadeMesh
    end
end

-- Show --
function Scene:show (event)
	if event.phase == "did" then
        self.star = BuildStar(display.contentCenterX, display.contentCenterY, 150)

        for i = 1, self.rgroup.numChildren do
			self.rgroup[i].isVisible = false
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
		timer.cancel(self.update)

        self.lcannon.projectile, self.rcannon.projectile = false, false

        self.before = nil
	end
end

Scene:addEventListener("hide")

return Scene
