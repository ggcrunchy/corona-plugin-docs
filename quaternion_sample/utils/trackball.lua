--- A trackball widget.

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
local asin = math.asin
local max = math.max
local sqrt = math.sqrt

-- Modules --
local common = require("utils.common")

-- Kernels --
require("kernels.sphere_colors")

-- Plugins --
local quaternion = require("plugin.quaternion")

-- Corona globals --
local display = display

-- Exports --
local M = {}

-- Rotated event --
local RotatedEvent = { name = "trackball_rotated" }

-- Intermediate delta quaternion --
local Delta = {}

-- Trackball touch listener
local function TrackballTouch (event)
	local phase, target = event.phase, event.target

	-- Began --
	if phase == "began" then
		display.getCurrentStage():setFocus(target, event.id)

		target.m_x, target.m_y = event.x, event.y

	-- Moved --
	elseif phase == "moved" then
		local xwas, xnow = target.m_x, event.x
		local ywas, ynow = target.m_y, event.y

		if xwas and (abs(xnow - xwas) >= 2 or abs(ynow - ywas) >= 2) then
			-- Assuming orthographic projection, find the old and new points on the sphere.
			local cx, cy, radius = target.x, target.y, target.path.radius
			local x1, y1 = (xwas - cx) / radius, (ywas - cy) / radius
			local x2, y2 = (xnow - cx) / radius, (ynow - cy) / radius
			local z1 = sqrt(max(1 - x1^2 - y1^2), 0)
			local z2 = sqrt(max(1 - x2^2 - y2^2), 0)

			-- Get the angle and axis of rotation through these points. Update the frame.
			local dist = sqrt((x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2)
			local angle = 2 * asin(dist / 2)

			if angle == angle then -- an off-sphere point results in a NaN
				quaternion.FromAxisAngle(Delta, angle, common.CrossProduct(x1, y1, z1, x2, y2, z2))
				quaternion.Multiply(target.m_frame, Delta, target.m_frame)

				-- Alert listeners.
				RotatedEvent.target, RotatedEvent.delta = target, Delta

				target:dispatchEvent(RotatedEvent)

				RotatedEvent.target, RotatedEvent.delta = nil

				-- Update some trackball graphics state.
				local tfe = target.fill.effect

				tfe.nx, tfe.ny, tfe.nz = common.RotateFrameVector(target.m_frame, 0, 0, 1)

				-- Update the previous point.
				target.m_x, target.m_y = xnow, ynow
			end
		end

	-- Ended / Cancelled --
	elseif phase == "ended" or phase == "cancelled" then
		if target.m_x then
			display.getCurrentStage():setFocus(target, nil)

			target.m_x, target.m_y = nil
		end
	end

	return true
end

--- Creates a trackball widget.
--
-- The trackball dispatches a **"trackball\_rotated"** event, with the delta available via
-- **event.delta** as a **Quaternion** and the trackball under **event.target**.
-- @pgroup Group to which trackball is added.
-- @number x Position x-coordinate...
-- @number y ...and y-coordinate.
-- @number radius Trackball radius.
function M.New (group, x, y, radius)
	local trackball = display.newCircle(group, x, y, radius)

	trackball:addEventListener("touch", TrackballTouch)
	trackball:setStrokeColor(.45, .3)

	trackball.fill.effect = "filter.sphere.colors"
	trackball.strokeWidth = 1

	trackball.m_frame = common.IdentityQuaternion()

	return trackball
end

-- Export the module.
return M