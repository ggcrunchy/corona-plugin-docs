--- Scene that concentrates on a few objects, with some quaternion-based controls.

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
local sin = math.sin

-- Modules --
local common = require("utils.common")
local shapes = require("utils.shapes")
local stream = require("classes.stream")
local trackball = require("utils.trackball")
local world = require("classes.world")

-- Corona globals --
local display = display
local native = native

-- Corona modules --
local composer = require("composer")

-- Objects scene.
local Scene = composer.newScene()

-- Polygon stream singleton --
local Polygons = stream.New()

-- Shorthand for center coordinates --
local CX, CY = display.contentCenterX, display.contentCenterY

-- Create --
function Scene:create ()
	-- Models to update and draw in scene --
	self.m_world = world.New(self.view, 0, 0, 0, {
		-- Object with a dummy bone, to be rotated --
		{
			points = {
				a = common.Unproject(20, 150, 120),
				b = common.Unproject(-20, 110, 120),
				c = common.Unproject(0, 90, 120),
				d = common.Unproject(40, 130, 120),
				e = common.Unproject(70, 120, 250)
			}, lines = Polygons:Begin()
				:AddTri("a", "b", "c")
				:AddTri("a", "d", "c")
				:AddTri("e", "d", "a")
				:AddTri("c", "d", "e")
			:End(),

			skeleton = {
				key = "RotateMe",
				"a", "b", "c", "d", "e"
			}
		},

		-- Simple animated object --
		{
			points = {
				a = common.Unproject(20, 40, 40),
				b = common.Unproject(0, 60, 40),
				c = common.Unproject(-20, 20, 40),
				d = common.Unproject(30, 50, 45),
				e = common.Unproject(40, 50, 45),
				f = common.Unproject(35, 30, 45),
				g = common.Unproject(-30, 40, 35),
				h = common.Unproject(-50, 36, 35),
				i = common.Unproject(-38, 20, 35),
				j = common.Unproject(-20, 30, 35) 
			}, lines = Polygons:Begin()
				:AddTri("a", "b", "c")
				:AddTri("d", "e", "f")
				:AddQuad("g", "h", "i", "j")
			:End(),

			skeleton = {
				get_time = function(time)
					return .5 + sin(time / 500) * .5
				end,
				min = 10, max = 30,
				"a", "b", "c",
				{
					"d", "e", "f",
					min = 70, max = 141
				},
				{
					"g", "h", "i", "j",
					min = -34, max = 11
				}
			}
		},

		-- A sphere... --
		{
			points = shapes.SpherePoints("Sphere", common.Unproject(120, 20, 40), 8),
			lines = shapes.Sphere(Polygons:Begin(), "Sphere"):End()
		},

		-- ...and a cylinder --
		{
			points = shapes.CylinderPoints("Cylinder", common.Unproject(-50, -120, 40), common.Unproject(90, -30, 70), 8),
			lines = shapes.Cylinder(Polygons:Begin(), "Cylinder"):End()
		}
	})

	-- Add a trackball to orient the object.
	local trackball = trackball.New(self.view, CX / 3, .25 * CY, 45)

	trackball:addEventListener("trackball_rotated", function(event)
		self.m_world:RotateBone("RotateMe", event.delta)
	end)

	display.newText(self.view, "Rotate Object", trackball.x, trackball.y + 55, native.systemFont, 13)
end

Scene:addEventListener("create")

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		self.m_world:Activate()
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		self.m_world:Deactivate()
	end
end

Scene:addEventListener("hide")

return Scene