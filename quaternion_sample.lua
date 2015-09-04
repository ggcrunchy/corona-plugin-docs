--- Sample code for quaternion plugin.

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

local quaternion = require("plugin.quaternion")

local function Q (what, q)
	print(("%s: x = %.2f, y = %.2f, z = %.2f, w = %.2f"):format(what, q.x, q.y, q.z, q.w))
end

-- Quaternions are just tables with x, y, z, and w
local q1 = { x = 1, y = 2, z = 3, w = 4 }
local q2 = { x = 4, y = 3, z = 2, w = 1 }

Q("q1", q1)
Q("q2", q2)

-- Add, subtract, negate, scale, add scaled, multiply
print("")
Q("q1 + q2", quaternion.Add({}, q1, q2))
Q("q1 - q2", quaternion.Sub({}, q1, q2))
Q("-q1", quaternion.Negate({}, q1))
Q("q2 * 3.1", quaternion.Scale({}, q1, 3.1))
Q("q1 + q2 * 5.2", quaternion.Add_Scaled({}, q1, q2, 5.2))
Q("q1 x q2", quaternion.Multiply({}, q1, q2))

-- Angle between
print("")
print("Angle between q1, q2 (degrees)", math.deg(quaternion.AngleBetween(q1, q2)))

-- Dot product
print("")
print("q1 . q2:", quaternion.Dot(q1, q2))

-- Length
print("")
print("Length of q2:", quaternion.Length(q2))

-- Conjugate
local conj = quaternion.Conjugate({}, q1)

print("")
Q("q1*", conj)
Q("q1* x q1", quaternion.Multiply({}, conj, q1))

-- Log, exp
local log = quaternion.Log({}, q1)

print("")
Q("log(q1)", log)
Q("exp(q1)", quaternion.Exp({}, q1))
Q("exp(log(q1))", quaternion.Exp({}, log))

-- Inverse
local qi = quaternion.Inverse({}, q1)

print("")
Q("q1^-1", qi)
Q("q1^-1 x q1", quaternion.Multiply({}, qi, q1))
Q("q1 x q1^-1", quaternion.Multiply({}, q1, qi))

-- Difference
local diff = quaternion.Difference({}, q1, q2)

print("")
Q("difference of q1, q2", diff)
Q("q1 x diff", quaternion.Multiply({}, q1, diff))

-- Normalization (using self as out)
quaternion.Normalize(q1, q1)
quaternion.Normalize(q2, q2)

print("")
Q("q1, normalized", q1)
Q("q2, normalized", q2)
print("q1, length (normalized):", quaternion.Length(q1))
print("")

-- Helper to rotate vector by quaternion
local Conj = {}

local function Rotate (v, q)
	local out = { x = v.x, y = v.y, z = v.z, w = 0 }

	-- q x v x q*
	return quaternion.Multiply(out, quaternion.Multiply(out, q, out), quaternion.Conjugate(Conj, q))
end

-- Axis-angle rotation
local V = { x = 2, y = 1, z = 2 }

print("")
print(("Rotating (%.2f, %.2f, %.2f) around axis (0, 0, 1)"):format(V.x, V.y, V.z))

for i = 1, 10 do
	local angle = 360 * (i - 1) / 9

	Q(("%.2f degrees"):format(angle), Rotate(V, quaternion.FromAxisAngle({}, math.rad(angle), 0, 0, 1)))
end

-- Euler angle rotation
print("")
print("Euler angle rotations")

Q("xyz order, 20, 55, 30 degrees", Rotate(V, quaternion.FromEulerAngles({}, math.rad(20), math.rad(55), math.rad(30))))
Q("zxy order, 40, 35, 80 degrees", Rotate(V, quaternion.FromEulerAngles({}, math.rad(40), math.rad(35), math.rad(80), "zxy")))

-- Slerp
print("")
print("Slerp from q1 to q2")

for i = 1, 10 do
	local t = (i - 1) / 9

	Q(("t = %.2f"):format(t), quaternion.Slerp({}, q1, q2, t))
end

-- Some new vectors
local q0 = quaternion.Normalize({}, { x = 3, y = 0, z = -2, w = 1.7 })
local q3 = quaternion.Normalize({}, { x = 7, y = 32, z = 3, w = 2 })

print("")
Q("q0", q0)
Q("q3", q3)

-- Squad
print("")
print("Squad using (q0, q1, q2, q3)")

for i = 1, 10 do
	local t = (i - 1) / 9

	Q(("t = %.2f"):format(t), quaternion.Squad({}, q0, q1, q2, q3, t))
end