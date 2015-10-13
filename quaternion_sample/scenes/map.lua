--- Scene that shows a map, using quaternions to update pieces of the world.

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
local sin = math.sin

-- Modules --
local shapes = require("utils.shapes")
local stream = require("classes.stream")
local trackball = require("utils.trackball")
local world = require("classes.world")

-- Corona globals --
local display = display
local native = native
local Runtime = Runtime

-- Corona modules --
local composer = require("composer")

-- Map scene.
local Scene = composer.newScene()

-- Polygon stream singleton --
local Polygons = stream.New()

-- Shorthand for center coordinates --
local CX, CY = display.contentCenterX, display.contentCenterY

-- Scene dimensions --
local SceneW, SceneH = 400, 400

-- Helper to load a point in the ground geometry
local function GroundPoint (xfrac, y, zfrac)
	return { x = -SceneW / 2 + xfrac * SceneW, y = y, z = -SceneH / 2 + zfrac * SceneH }
end

-- Common move touch body
local function MoveTouch (event)
	local phase, target = event.phase, event.target

	-- Began --
	if phase == "began" then
		display.getCurrentStage():setFocus(target, event.id)

		target.m_since = event.time

	-- Ended / Cancelled --
	elseif phase == "ended" or phase == "cancelled" then
		display.getCurrentStage():setFocus(target, nil)

		target.m_since = nil
	end

	return true
end

-- Touch button factory
local function TouchButton (group, str, y)
	local button = display.newCircle(group, 1.75 * CX, y, 25)

	button:addEventListener("touch", MoveTouch)
	button:setStrokeColor(random(), random(), .7, .7)

	button.fill, button.strokeWidth = {
		type = "gradient",
		color1 = { .3, .1, .2 },
		color2 = { .4, .1, .7 },
		direction = "down"
	}, 2

	local text = display.newText(group, str, button.x, y, native.systemFontBold, 12)

	text:setTextColor(.7, .2, .1)

	return button
end

-- Create --
function Scene:create ()
	-- Models to update and draw in scene --
	-- TODO: Skinning?
	self.m_world = world.New(self.view, 0, -15, 0, {
		-- Ground --
		{
			points = {
				-- Corners --
				nw = GroundPoint(0, 0, 0), ne = GroundPoint(1, 0, 0), sw = GroundPoint(0, 0, 1), se = GroundPoint(1, 0, 1),

				-- "North" --
				n1 = GroundPoint(.15, 0, 0), n2 = GroundPoint(.3, 0, 0), n3 = GroundPoint(.5, 0, 0),
				n4 = GroundPoint(.7, 0, 0), n5 = GroundPoint(.85, 0, 0),

				-- "West" --
				w1 = GroundPoint(0, 0, .11), w2 = GroundPoint(0, 0, .25), w3 = GroundPoint(0, 0, .39),
				w4 = GroundPoint(0, 0, .52), w5 = GroundPoint(0, 0, .77),

				-- "East" --
				e1 = GroundPoint(1, 0, .13), e2 = GroundPoint(1, 0, .4), e3 = GroundPoint(1, 0, .6), e4 = GroundPoint(1, 0, .81),

				-- "South" --
				s1 = GroundPoint(.11, 0, 1), s2 = GroundPoint(.22, 0, 1), s3 = GroundPoint(.31, 0, 1),
				s4 = GroundPoint(.5, 0, 1), s5 = GroundPoint(.78, 0, 1),

				-- Row 1 --
				-- These "rows" correspond roughly to the drawing I used to make this map.
				p1 = GroundPoint(.08, -7.1, .11), p2 = GroundPoint(.21, 11.9, .21), p3 = GroundPoint(.33, 10, .14),
				p4 = GroundPoint(.55, 0, .12), p5 = GroundPoint(.76, 0, .12),

				-- Row 2 --
				p6 = GroundPoint(.05, 0, .28), p7 = GroundPoint(.17, 2.9, .4), p8 = GroundPoint(.48, -15.3, .41),
				p9 = GroundPoint(.7, 0, .39), p10 = GroundPoint(.86, 0, .37),

				-- Row 3 --
				p11 = GroundPoint(.09, 0, .54), p12 = GroundPoint(.29, -31.3, .53), p13 = GroundPoint(.68, 0, .51), p14 = GroundPoint(.84, 0, .5),

				-- Row 4 --
				p15 = GroundPoint(.07, 0, .78), p16 = GroundPoint(.21, -4.9, .75), p17 = GroundPoint(.47, 0, .78), p18 = GroundPoint(.49, -11.9, .61),
				p19 = GroundPoint(.74, 20, .7), p20 = GroundPoint(.87, 0, .69),

				-- Row 5 --
				p21 = GroundPoint(.16, 16.3, .83), p22 = GroundPoint(.67, 10, .87), p23 = GroundPoint(.8, 0, .87)
			}, lines = Polygons:Begin()
				:AddTri("nw", "n1", "p1")
				:AddTri("nw", "p1", "w1")
				:AddTri("p1", "n1", "p2")
				:AddTri("n1", "n2", "p2")
				:AddTri("p2", "n2", "p3")
				:AddTri("n2", "n3", "p3")
				:AddTri("p3", "n3", "p4")
				:AddTri("n3", "n4", "p4")
				:AddTri("p4", "n4", "p5")
				:AddTri("n4", "n5", "p5")
				:AddTri("p5", "n5", "e1")
				:AddTri("n5", "ne", "e1")
				:AddTri("w1", "w2", "p6")
				:AddTri("w1", "p1", "p6")
				:AddTri("p6", "p1", "p7")
				:AddTri("p1", "p2", "p7")
				:AddTri("p2", "p3", "p7")
				:AddTri("p7", "p3", "p8")
				:AddTri("p3", "p9", "p8")
				:AddTri("p3", "p4", "p9")
				:AddTri("p4", "p5", "p9")
				:AddTri("p9", "p5", "p10")
				:AddTri("p5", "e1", "p10")
				:AddTri("p10", "e1", "e2")
				:AddTri("w2", "p6", "w3")
				:AddTri("w4", "w3", "p11")
				:AddTri("w3", "p6", "p11")
				:AddTri("p6", "p7", "p11")
				:AddTri("p11", "p7", "p12")
				:AddTri("p7", "p8", "p12")
				:AddTri("p8", "p9", "p13")
				:AddTri("p13", "p9", "p14")
				:AddTri("p9", "p10", "p14")
				:AddTri("p10", "e2", "p14")
				:AddTri("p14", "e2", "e3")
				:AddTri("w4", "p11", "w5")
				:AddTri("w5", "p11", "p15")
				:AddTri("p15", "p11", "p16")
				:AddTri("p11", "p12", "p16")
				:AddTri("p16", "p12", "p17")
				:AddTri("p12", "p18", "p17")
				:AddTri("p12", "p8", "p18")
				:AddTri("p8", "p13", "p18")
				:AddTri("p18", "p13", "p19")
				:AddTri("p13", "p14", "p19")
				:AddTri("p19", "p14", "p20")
				:AddTri("p14", "e3", "p20")
				:AddTri("p20", "e3", "e4")
				:AddTri("w5", "p15", "sw")
				:AddTri("sw", "p15", "s1")
				:AddTri("p15", "p21", "s1")
				:AddTri("p15", "p16", "p21")
				:AddTri("s1", "p21", "s2")
				:AddTri("s2", "p21", "s3")
				:AddTri("p21", "p16", "s3")
				:AddTri("p16", "p17", "s3")
				:AddTri("s3", "p17", "s4")
				:AddTri("p17", "p18", "s4")
				:AddTri("p18", "p22", "s4")
				:AddTri("p18", "p19", "p22")
				:AddTri("s4", "p22", "s5")
				:AddTri("p22", "p19", "p23")
				:AddTri("p22", "p23", "s5")
				:AddTri("p19", "p20", "p23")
				:AddTri("p20", "e4", "p23")
				:AddTri("p23", "e4", "se")
				:AddTri("s5", "p23", "se")
			:End()
		},

		-- A human... --
		(function()
			--
			local torso, torso_radius, head_radius = GroundPoint(.3, -25, .7), 8, 4
			local head = { x = torso.x, y = torso.y - torso_radius - head_radius, z = torso.z }
			local left_shoulder = { x = torso.x - .8 * torso_radius, y = torso.y - .8 * torso_radius, z = torso.z }
			local left_elbow = { x = left_shoulder.x - 11, y = left_shoulder.y - 2, z = left_shoulder.z }
			local right_shoulder = { x = torso.x + .7 * torso_radius, y = torso.y - .9 * torso_radius, z = torso.z }
			local right_elbow = { x = right_shoulder.x + 9, y = right_shoulder.y + 3.8, z = right_shoulder.z }
			local left_hip = { x = torso.x - .7 * torso_radius, y = torso.y + .8 * torso_radius, z = torso.z }
			local left_knee = { x = left_hip.x - 2, y = left_hip.y + 5, z = left_hip.z }
			local right_hip = { x = torso.x + .9 * torso_radius, y = torso.y + .7 * torso_radius, z = torso.z }
			local right_knee = { x = right_hip.x, y = right_hip.y + 4.5, z = right_hip.z }

			-- Add the torso and head...
			local points = {}

			shapes.SpherePoints("Torso", torso, torso_radius, points)
			shapes.SpherePoints("Head", head, head_radius, points)

			-- ...the arms...
			shapes.CylinderPoints("UpperLeftArm", left_shoulder, left_elbow, 1.9, points)
			shapes.CylinderPoints("LowerLeftArm", left_elbow, { x = left_elbow.x - 1, y = left_elbow.y - 6, z = left_elbow.z }, 1.7, points)
			shapes.CylinderPoints("UpperRightArm", right_shoulder, right_elbow, 2, points)
			shapes.CylinderPoints("LowerRightArm", right_elbow, { x = right_elbow.x, y = right_elbow.y + 5, z = right_elbow.z }, 2.1, points)

			--- ...and the legs.
			shapes.CylinderPoints("UpperLeftLeg", left_hip, left_knee, 2, points)
			shapes.CylinderPoints("LowerLeftLeg", left_knee, { x = left_knee.x + 1, y = left_knee.y + 6, z = left_knee.z }, 1.8, points)
			shapes.CylinderPoints("UpperRightLeg", right_hip, right_knee, 2, points)
			shapes.CylinderPoints("LowerRightLeg", right_knee, { x = right_knee.x, y = right_knee.y + 5.5, z = right_knee.z }, 1.8, points)

			--
			return {
				points = points, lines = (function()
					Polygons:Begin()

					shapes.Sphere(Polygons, "Torso")
					shapes.Sphere(Polygons, "Head")
					shapes.Cylinder(Polygons, "UpperLeftArm")
					shapes.Cylinder(Polygons, "LowerLeftArm")
					shapes.Cylinder(Polygons, "UpperRightArm")
					shapes.Cylinder(Polygons, "LowerRightArm")
					shapes.Cylinder(Polygons, "UpperLeftLeg")
					shapes.Cylinder(Polygons, "LowerLeftLeg")
					shapes.Cylinder(Polygons, "UpperRightLeg")
					shapes.Cylinder(Polygons, "LowerRightLeg")

					return Polygons:End()
				end)(),

				skeleton = {
					-- Torso --
					get_time = function(time)
						return .5 + sin(time / 750) * .5
					end,
					min = 10, max = 30,
					{
						-- Head --
						min = -60, max = 60,
						shapes.SphereNames("Head")
					},
					{
						-- Upper Left Arm --
						min = 20, max = 40,
						get_time = function(time)
							return .5 + sin(time / 150) * .5
						end,
						pos = left_shoulder,
						{
							-- Lower Left Arm --
							min = -30, max = 40, axis = "hinge",
							pos = left_elbow,
							shapes.CylinderNames("LowerLeftArm")
						},
						shapes.CylinderNames("UpperLeftArm")
					},
					{
						-- Upper Right Arm --
						pos = right_shoulder,
						{
							-- Lower Right Arm --
							pos = right_elbow, min = 10, max = 80, axis = "hinge",
							shapes.CylinderNames("LowerRightArm")
						},
						shapes.CylinderNames("UpperRightArm")
					},
					{
						-- Upper Left Leg --
						pos = left_hip, min = 20, max = 110,
						{
							-- Lower Left Leg --
							pos = left_knee, min = 20, max = 70, axis = "hinge",
							shapes.CylinderNames("LowerLeftLeg")
						},
						shapes.CylinderNames("UpperLeftLeg")
					},
					{
						-- Upper Right Leg --
						pos = right_hip, min = 30, max = 90,
						{
							-- Lower Right Leg --
							pos = right_knee, min = -10, max = 35,
							shapes.CylinderNames("LowerRightLeg")
						},
						shapes.CylinderNames("UpperRightLeg")
					},
					shapes.SphereNames("Torso") -- n.b. this must follow the sub-bones when declared in a table (in the rest above, too)
				}
			}
		end)()
	})

	-- Add a trackball to orient the camera.
	local camera = trackball.New(self.view, CX / 3, .25 * CY, 45)

	camera:addEventListener("trackball_rotated", function(event)
		self.m_world:RotateView(event.delta)
	end)

	display.newText(self.view, "Rotate Camera", camera.x, camera.y + 55, native.systemFont, 13)

	-- Add buttons to move the camera backward and forward.
	local forward = TouchButton(self.view, "Ahead", camera.y - 30)
	local backward = TouchButton(self.view, "Back", camera.y + 30)

	-- Update the camera when buttons are held.
	local move_speed = 25.75

	function self.m_enter_frame (event)
		local now = event.time

		-- Apply any movement.
		local bsince, fsince = backward.m_since, forward.m_since

		if bsince or fsince then
			local fx, fy, fz = self.m_world:GetVectorInView(0, 0, 1)
			local sum = (bsince or now) - (fsince or now) -- this is (bsince - now) + (now - fsince), accounting for absences
			local dt = sum * move_speed / 1000

			self.m_world:UpdateEye(fx * dt, fy * dt, fz * dt)

			backward.m_since, forward.m_since = bsince and now, fsince and now
		end
	end
end

Scene:addEventListener("create")

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		self.m_world:Activate()

		Runtime:addEventListener("enterFrame", self.m_enter_frame)
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		self.m_world:Deactivate()

		Runtime:removeEventListener("enterFrame", self.m_enter_frame)
	end
end

Scene:addEventListener("hide")

return Scene