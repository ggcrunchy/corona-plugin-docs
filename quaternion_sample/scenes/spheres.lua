--- Scene that uses quaternions to traverse spheres.

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
local ipairs = ipairs
local max = math.max
local pi = math.pi
local random = math.random
local sqrt = math.sqrt

-- Modules --
local common = require("utils.common")

-- Kernels --
require("kernels.sphere_bumped")

-- Plugins --
local quaternion = require("plugin.quaternion")

-- Corona globals --
local display = display
local native = native
local Runtime = Runtime
local transition = transition

-- Corona modules --
local composer = require("composer")
local widget = require("widget")

-- Circle scene.
local Scene = composer.newScene()

-- Transitioning quaternion time parameter --
local QuatTrans = {}

-- Forward declare this, since it gets reset each time the scene is entered
local Print

-- Compare slerp and squad...
local DoneOne, NumFrames, Diff, FirstX, FirstY, FirstZ = false, 0, 0

local function CompareInterpolations (V, what)
	if NumFrames < 20 then
		if DoneOne then
			Print("")
			Print(("%s, %.5f, %.5f, %.5f"):format(what, V.x, V.y, V.z))
			Print(("%s, %.5f, %.5f, %.5f"):format(what == "Slerp:" and "Squad:" or "Slerp:", FirstX, FirstY, FirstZ))
			Print(("Difference: %.5f, %.5f, %.5f"):format(V.x - FirstX, V.y - FirstY, V.z - FirstZ))

			Diff = max(Diff, abs(V.x - FirstX), abs(V.y - FirstY), abs(V.z - FirstZ))

			NumFrames, DoneOne = NumFrames + 1, false
		else
			FirstX, FirstY, FirstZ, DoneOne = V.x, V.y, V.z, true
		end
	elseif NumFrames == 20 then
		Print("")
		Print("Maximum component difference", Diff)

		NumFrames = NumFrames + 1 -- stop the test
	end
end

-- Enter frame body
local function EnterFrame (how, func)
	local V, Q = {}, {}

	return function(self)
		V.x, V.y, V.z, V.w = 0, 0, 1, 0

		func(Q, Scene.m_quats, QuatTrans.t)

		common.Rotate(V, Q, true)
		CompareInterpolations(V, how)

		self.fill.effect.light_x = V.x
		self.fill.effect.light_y = V.y
		self.fill.effect.light_z = V.z
	end
end

-- Calculates a new random quaternion
local function NewQuat (quats, index)
	local quat = quats[index]
	local x = 2 * (random() - .5)
	local y = 2 * (random() - .5) * sqrt(max(0, 1 - x^2))
	local z = (random() < .5 and -1 or 1) * sqrt(max(0, 1 - x^2 - y^2))
	local theta = (pi / 6 + random() * pi / 6) * (random() < .5 and -1 or 1)

	quaternion.FromAxisAngle(quat, theta, x, y, z)

	if index > 1 then
		quaternion.Multiply(quat, quat, quats[index - 1])
	end
end

-- Interpolation time transition --
local Params = { t = 1, iterations = -1, time = 750 }

function Params.onRepeat (qt)
	local quats = Scene.m_quats

	-- Evict the first quaternion. Move the remaining elements down.
	local q1 = quats[1]

	for i = 2, 4 do
		quats[i - 1] = quats[i]
	end

	-- Select a new quaternion to replace the vacated final position.
	quats[4] = q1

	NewQuat(quats, 4)

	-- Do this early, so the enterFrame handlers respect the new quaternions.
	qt.t = 0
end

function Params.onStart (qt)
	qt.t = 0
end

-- Create --
function Scene:create ()
	local background = display.newRect(self.view, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)

	background:setFillColor(.05, 0, .1)

	for _, v in ipairs{
		{
			x = .5, prefix = "Slerp:", text = "Slerp()'d light", key = "m_slerp_sphere",

			func = function(q, quats, t)
				quaternion.Slerp(q, quats[2], quats[3], t)
			end
		},
		{
			x = 1.5, prefix = "Squad:", text = "Squad()'d light", key = "m_squad_sphere",

			func = function(q, quats, t)
				quaternion.Squad(q, quats[1], quats[2], quats[3], quats[4], t)
			end
		}
	} do
		local sphere = display.newCircle(self.view, display.contentCenterX * v.x, 90, 50)

		sphere.fill = { type = "image", filename = "Image1.jpg" }

		sphere.fill.effect = "filter.sphere.bumped"

		-- Update the light according to the current interpolation time.
		sphere.enterFrame = EnterFrame(v.prefix, v.func)

		self[v.key] = sphere

		display.newText(self.view, v.text, sphere.x, sphere.y - 65, native.systemFont, 20)
	end
end

Scene:addEventListener("create")

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		-- Start with a fresh batch of in-use quaternions.
		self.m_quats = { {}, {}, {}, {} }

		for i = 1, #self.m_quats do
			NewQuat(self.m_quats, i)
		end

		-- Update spheres.
		Runtime:addEventListener("enterFrame", self.m_slerp_sphere)
		Runtime:addEventListener("enterFrame", self.m_squad_sphere)

		-- Update the interpolation time.
		self.m_timer = transition.to(QuatTrans, Params)

		-- Reset some comparison state.
		DoneOne, NumFrames, Diff = false, 0, 0

		-- Prepare a new text console.
		local y = .35 * display.contentHeight

		self.m_text_view = widget.newScrollView{ top = y, height = display.contentHeight - y - 40, hideBackground = true }

		self.view:insert(self.m_text_view)

		Print = common.Print(self.m_text_view, 8)

		Print("")
		Print("Comparing slerp'd and squad'd light direction, over a few frames.")
		Print("(Scroll down to see more.)")
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		transition.cancel(self.m_timer)

		Runtime:removeEventListener("enterFrame", self.m_slerp_sphere)
		Runtime:removeEventListener("enterFrame", self.m_squad_sphere)

		self.m_text_view:removeSelf()
	end
end

Scene:addEventListener("hide")

return Scene