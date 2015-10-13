--- Scene that demonstrates several quaternion function calls.

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
local deg = math.deg
local rad = math.rad

-- Modules --
local common = require("utils.common")

-- Plugins --
local quaternion = require("plugin.quaternion")

-- Corona modules --
local composer = require("composer")
local widget = require("widget")

-- Function calls scene.
local Scene = composer.newScene()

-- Show --
function Scene:create ()
	self.m_page = widget.newScrollView{ backgroundColor = { .075 }, height = display.contentHeight - 40 }

	self.view:insert(self.m_page)

	-- Use display objects for prints
	local Print = common.Print(self.m_page, 8)

	-- Print helper
	local function Q (what, q)
		Print(("%s: x = %.2f, y = %.2f, z = %.2f, w = %.2f"):format(what, q.x, q.y, q.z, q.w))
	end

	-- Quaternions are just tables with x, y, z, and w
	local q1 = { x = 1, y = 2, z = 3, w = 4 }
	local q2 = { x = 4, y = 3, z = 2, w = 1 }

	Q("q1", q1)
	Q("q2", q2)

	-- Provide some instructions.
	Print("")
	Print("Scroll down to see various results.")

	-- Add, subtract, negate, scale, add scaled, multiply
	Print("")
	Q("q1 + q2", quaternion.Add({}, q1, q2))
	Q("q1 - q2", quaternion.Sub({}, q1, q2))
	Q("-q1", quaternion.Negate({}, q1))
	Q("q2 * 3.1", quaternion.Scale({}, q1, 3.1))
	Q("q1 + q2 * 5.2", quaternion.Add_Scaled({}, q1, q2, 5.2))
	Q("q1 x q2", quaternion.Multiply({}, q1, q2))

	-- Angle between
	Print("")
	Print("Angle between q1, q2 (degrees):", deg(quaternion.AngleBetween(q1, q2)))

	-- Dot product
	Print("")
	Print("q1 . q2:", quaternion.Dot(q1, q2))

	-- Length
	Print("")
	Print("Length of q2:", quaternion.Length(q2))

	-- Conjugate
	local conj = quaternion.Conjugate({}, q1)

	Print("")
	Q("q1*", conj)
	Q("q1* x q1", quaternion.Multiply({}, conj, q1))

	-- Log, exp
	local log = quaternion.Log({}, q1)

	Print("")
	Q("log(q1)", log)
	Q("exp(q1)", quaternion.Exp({}, q1))
	Q("exp(log(q1))", quaternion.Exp({}, log))

	-- Inverse
	local qi = quaternion.Inverse({}, q1)

	Print("")
	Q("q1^-1", qi)
	Q("q1^-1 x q1", quaternion.Multiply({}, qi, q1))
	Q("q1 x q1^-1", quaternion.Multiply({}, q1, qi))

	-- Difference
	local diff = quaternion.Difference({}, q1, q2)

	Print("")
	Q("Difference of q1, q2", diff)
	Q("q1 x diff", quaternion.Multiply({}, q1, diff))

	-- Normalization (using self as out)
	quaternion.Normalize(q1, q1)
	quaternion.Normalize(q2, q2)

	Print("")
	Q("q1, normalized", q1)
	Q("q2, normalized", q2)
	Print("q1, length (normalized):", quaternion.Length(q1))

	-- Axis-angle rotation
	local V = { x = 2, y = 1, z = 2 }

	Print("")
	Print(("Rotating (%.2f, %.2f, %.2f) around axis (0, 0, 1)"):format(V.x, V.y, V.z))

	for i = 1, 10 do
		local angle = 360 * (i - 1) / 9

		Q(("%.2f degrees"):format(angle), common.Rotate(V, quaternion.FromAxisAngle({}, rad(angle), 0, 0, 1)))
	end

	-- Euler angle rotation
	Print("")
	Print("Euler angle rotations")

	Q("xyz order, 20, 55, 30 degrees", common.Rotate(V, quaternion.FromEulerAngles({}, rad(20), rad(55), rad(30))))
	Q("zxy order, 40, 35, 80 degrees", common.Rotate(V, quaternion.FromEulerAngles({}, rad(40), rad(35), rad(80), "zxy")))

	-- Slerp
	Print("")
	Print("Slerp from q1 to q2:")

	for i = 1, 10 do
		local t = (i - 1) / 9

		Q(("t = %.2f"):format(t), quaternion.Slerp({}, q1, q2, t))
	end

	-- Some new vectors
	local q0 = quaternion.Normalize({}, { x = 3, y = 0, z = -2, w = 1.7 })
	local q3 = quaternion.Normalize({}, { x = 7, y = 32, z = 3, w = 2 })

	Print("")
	Q("q0", q0)
	Q("q3", q3)

	-- Squad
	Print("")
	Print("Squad using (q0, q1, q2, q3):")

	for i = 1, 10 do
		local t = (i - 1) / 9

		Q(("t = %.2f"):format(t), quaternion.Squad({}, q0, q1, q2, q3, t))
	end
end

Scene:addEventListener("create")

return Scene