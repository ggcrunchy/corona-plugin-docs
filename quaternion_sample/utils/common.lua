--- Some routines common to different parts of the quaternion sample.

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

-- Modules --
local constants = require("utils.constants")

-- Plugins --
local quaternion = require("plugin.quaternion")

-- Corona globals --
local display = display
local native = native

-- Cached module references --
local _Rotate_

-- Exports --
local M = {}

--- Vector cross product.
-- @number x1 Vector #1, x-component...
-- @number y1 ...y-component...
-- @number z1 ...and z-component.
-- @number x2 Vector #2, x-component...
-- @number y2 ...y-component...
-- @number z2 ...and z-component.
-- @treturn number Cross product x-component...
-- @treturn number ...y-component...
-- @treturn number ...and z-component.
function M.CrossProduct (x1, y1, z1, x2, y2, z2)
	local nx = y1 * z2 - z1 * y2
	local ny = z1 * x2 - x1 * z2
	local nz = x1 * y2 - y1 * x2

	return nx, ny, nz
end

--- Vector dot product.
-- @number x1 Vector #1, x-component...
-- @number y1 ...y-component...
-- @number z1 ...and z-component.
-- @number x2 Vector #2, x-component...
-- @number y2 ...y-component...
-- @number z2 ...and z-component.
-- @treturn number Dot product.
function M.DotProduct (x1, y1, z1, x2, y2, z2)
	return x1 * x2 + y1 * y2 + z1 * z2
end

--- Helper to create an identity quaternion.
-- @treturn Quaternion Identity quaternion.
function M.IdentityQuaternion ()
	return { x = 0, y = 0, z = 0, w = 1 }
end

--- Print-like use of display objects.
-- @pgroup into Group to receive text objects.
-- @uint size Font size.
function M.Print (into, size)
	local y = 0

	return function(str, other)
		local text = display.newText(str .. (other and "   " or "") .. (other or ""), 0, 0, native.systemFontBold, size)

		text.anchorX, text.x = 0, 5
		text.anchorY, text.y = 0, y

		text:setTextColor(1, 0, 0)

		into:insert(text)

		y = y + text.contentHeight + 5
	end
end

-- Conjugate quaternion --
local Conj = {}

--- Rotate a vector by a quaternion.
-- @tparam Vector3 v Vector to rotate.
-- @tparam Quaternion q Rotation to apply.
-- @bool reuse Put the result back in and return _v_?
-- @treturn Vector3 Rotated vector. (**N.B.** It will have a **w** component of 0.)
function M.Rotate (v, q, reuse)
	local out

	if reuse then
		out = v
	else
		out = { x = v.x, y = v.y, z = v.z, w = 0 }
	end

	-- q x v x q*
	return quaternion.Multiply(out, quaternion.Multiply(out, q, out), quaternion.Conjugate(Conj, q))
end

-- Intermediate vector used to retrieve frame vectors --
local Temp = {}

--- Maps a Euclidean basis vector into the view frame.
-- @tparam Quaternion frame View frame.
-- @number x Vector x-coordinate...
-- @number y ...y-coordinate...
-- @number z ...and z-coordinate.
-- @treturn number Rotated x-coordinate...
-- @treturn number ...y-coordinate...
-- @treturn number ...and z-coordinate.
function M.RotateFrameVector (frame, x, y, z)
	Temp.x, Temp.y, Temp.z, Temp.w = x, y, z, 0

	_Rotate_(Temp, frame, true)

	return Temp.x, Temp.y, Temp.z
end

-- Shorthand for half-dimensions of screen --
local DW, DH = display.contentCenterX, display.contentCenterY

-- Distances to the near and far planes --
local NearZ, FarZ = constants.NearDistance(), constants.FarDistance()

--- Screen-to-world transform, relative to screen center.
-- @number x Screen x...
-- @number y ...and y.
-- @number z Distance relative to eye.
-- @treturn Vector3 World point.
function M.Unproject (x, y, z)
	x = x * z / (DW * NearZ)
	y = y * z / (DH * NearZ)

	return { x = x, y = y, z = z }
end

-- Cache module members.
_Rotate_ = M.Rotate

-- Export the module.
return M