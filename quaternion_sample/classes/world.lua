--- A class encapsulating a world and the objects within it.

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
local ipairs = ipairs
local max = math.max
local min = math.min
local pairs = pairs
local rad = math.rad
local setmetatable = setmetatable
local type = type

-- Modules --
local common = require("utils.common")
local constants = require("utils.constants")

-- Plugins --
local quaternion = require("plugin.quaternion")

-- Corona globals --
local display = display
local Runtime = Runtime

-- Exports --
local M = {}

-- World metatable --
local World = {}

World.__index = World

-- Distances to the near and far planes --
local NearZ, FarZ = constants.NearDistance(), constants.FarDistance()

-- Clamp a z-coordinate against the near and far planes
local function ClampZ (z)
	return min(max(z, NearZ), FarZ)
end

-- Helper to get the eye-to-point displacement
local function EyeToPoint (ex, ey, ez, p)
	return p.x - ex, p.y - ey, p.z - ez
end

-- Shorthand for center coordinates --
local CX, CY = display.contentCenterX, display.contentCenterY

-- Get the projected x- and y-coordinates
local function GetXY (x, y, z)
	return CX * (1 + NearZ * x / z), CY * (1 + NearZ * y / z)
end

-- Draws the current batch of lines, relative to the view, with clipping
local function RenderObjects (W)
	-- Start with a fresh set of lines.
	display.remove(W.m_line_group)

	local line_group = display.newGroup()

	W.m_view:insert(line_group)
	line_group:toBack()

	W.m_line_group = line_group

	-- Cache the current eye position plus the right, up, and forward directions.
	local eye, frame = W.m_eye, W.m_frame
	local ex, ey, ez = eye.x, eye.y, eye.z
	local rx, ry, rz = common.RotateFrameVector(frame, 1, 0, 0)
	local ux, uy, uz = common.RotateFrameVector(frame, 0, 1, 0)
	local fx, fy, fz = common.RotateFrameVector(frame, 0, 0, 1)

	-- Walk through each set of lines.
	local world_points = W.m_points

	for i, names in ipairs(W.m_names) do
		local points = world_points[i]

		for j = 1, #names, 2 do
			-- Find the vectors from the eye to each endpoint.
			local pname1, pname2 = names[j], names[j + 1]
			local dx1, dy1, dz1 = EyeToPoint(ex, ey, ez, points[pname1])
			local dx2, dy2, dz2 = EyeToPoint(ex, ey, ez, points[pname2])

			-- Get the components of the eye-to-endpoint vectors in the forward direction,
			-- i.e. z in the view coordinate system.
			local z1, z2 = common.DotProduct(dx1, dy1, dz1, fx, fy, fz), common.DotProduct(dx2, dy2, dz2, fx, fy, fz)

			-- If both points are in front of the near plane or behind the far plane, skip
			-- the line. Otherwise, proceed.
			if (z1 >= NearZ or z2 >= NearZ) and (z1 <= FarZ or z2 <= FarZ) then
				-- Get the components of the eye-to-endpoint vectors in the right and up
				-- directions, i.e. x and y in the view coordinate system.
				local x1, y1 = common.DotProduct(dx1, dy1, dz1, rx, ry, rz), common.DotProduct(dx1, dy1, dz1, ux, uy, uz)
				local x2, y2 = common.DotProduct(dx2, dy2, dz2, rx, ry, rz), common.DotProduct(dx2, dy2, dz2, ux, uy, uz)

				-- Clip lines that spill outside the near and far planes. Lines aligned with
				-- the plane will not need this treatment. Thus, the clamped z-offsets can be
				-- used to interpolate the segments, clipping them against the planes.
				local dz = z2 - z1

				if dz^2 > 1e-3 then
					local dx, dy = x2 - x1, y2 - y1
					local s = (ClampZ(z1) - z1) / dz
					local t = (ClampZ(z2) - z1) / dz

					x2, y2, z2 = x1 + dx * t, y1 + dy * t, z1 + dz * t
					x1, y1, z1 = x1 + dx * s, y1 + dy * s, z1 + dz * s
				end

				-- Get the projected endpoints and plot the segment.
				x1, y1 = GetXY(x1, y1, z1)
				x2, y2 = GetXY(x2, y2, z2)

				local line = display.newLine(line_group, x1, y1, x2, y2)

				line:setStrokeColor(0, 0, 1)
			end
		end
	end
end

-- Helper to find a vector sum
local function Add (a, b)
	return a.x + b.x, a.y + b.y, a.z + b.z
end

-- Helper to find a vector difference
local function Sub (a, b)
	return a.x - b.x, a.y - b.y, a.z - b.z
end

-- Update the animated objects
local function UpdateObjects (W, time)
	local bone_positions, flat_skeletons, quaternions = W.m_bone_positions, W.m_flat_skeletons, W.m_quaternions
	local from, to

	for i, entry in ipairs(flat_skeletons) do
		local parent = entry.parent

		-- Get the entry's interpolation time. If unavailable, use the parent's. Failing
		-- that, forgo interpolation.
		local tfunc = entry.get_time
		local t = tfunc and tfunc(time)

		if not t then
			t = parent and flat_skeletons[parent].m_time or 0
		end

		entry.m_time = t

		-- Find the local rotation and position of the bone. At the root, this is enough.
		-- Otherwise, apply the current transformation to it, and incorporate its own
		-- rotation and position into the steps that follow.
		local pos, bone_pos = entry.pos, entry.bone_pos
		local qcur = quaternion.Slerp(entry.bone_quat, entry.quat1, entry.quat2, t)

		if parent then
			bone_pos.w, bone_pos.x, bone_pos.y, bone_pos.z = 0, Sub(pos, flat_skeletons[parent].pos)

			local pb_quat = flat_skeletons[parent].bone_quat

			common.Rotate(bone_pos, pb_quat, true)

			bone_pos.x, bone_pos.y, bone_pos.z = Add(bone_pos, flat_skeletons[parent].bone_pos)

			quaternion.Multiply(qcur, pb_quat, qcur)
		else
			from, to = entry.from, entry.to
			bone_pos.x, bone_pos.y, bone_pos.z = pos.x, pos.y, pos.z
		end

		-- Find the positions of the batch of points relative to the untransformed bone,
		-- rotate these, and move the results back relative to the transformed bone.
		for _, name in ipairs(entry) do
			local into = to[name]

			into.w, into.x, into.y, into.z = 0, Sub(from[name], pos)

			common.Rotate(into, qcur, true)

			into.x, into.y, into.z = Add(into, bone_pos)
		end
	end
end

-- Currently active world --
local Current

-- Update the active world, if there is one
local function EnterFrame (event)
	if Current then
		UpdateObjects(Current, event.time)
		RenderObjects(Current)
	end
end

--- Make this the currently active world. If another is active, it is deactivated.
function World:Activate ()
	if not Current then
		Runtime:addEventListener("enterFrame", EnterFrame)
	end

	Current = self
end

--- If this is the currently active world, deactivate it. This is a no-op otherwise.
function World:Deactivate ()
	if self == Current then
		Runtime:removeEventListener("enterFrame", EnterFrame)

		Current = nil
	end
end

--- Given a vector in view-local coordinates, finds its world position.
-- @number x Local x-coordinate...
-- @number y ...y-coordinate...
-- @number z ...and z-coordinate.
-- @treturn number World x-coordinate...
-- @treturn number ...y-coordinate...
-- @treturn number ...and z-coordinate.
function World:GetVectorInView (x, y, z)
	return common.RotateFrameVector(self.m_frame, x, y, z)
end

-- Helper to rotate a quaternion in place
local function RotateBy (quat, delta)
	quaternion.Multiply(quat, quat, delta)
end

--- Updates the quaternion of any bone with a given key.
-- @string key Key used to identify bones to rotate.
-- @tparam Quaternion delta Change of bone orienation.
function World:RotateBone (key, delta)
	for _, entry in ipairs(self.m_flat_skeletons) do
		if entry.key == key then
			RotateBy(entry.quat1, delta)
			RotateBy(entry.quat2, delta)
		end
	end
end

--- Updates the world view quaternion.
-- @tparam Quaternion delta Change of view orientation.
function World:RotateView (delta)
	RotateBy(self.m_frame, delta)
end

--- Updates the view position.
-- @number dx Change in x-coordinate...
-- @number dy ...y-coordinate...
-- @number dz ...and z-coordinate.
function World:UpdateEye (dx, dy, dz)
	local eye = self.m_eye

	eye.x, eye.y, eye.z = eye.x + dx, eye.y + dy, eye.z + dz
end

-- Adds a joint to the flattened skeletons list
local function AddJoint (flat_skeletons, t, parent, from, to)
	-- Install a new entry. Whenever such an entry is the root, include some lookup tables.
	local entry, index = { parent = parent, get_time = t.get_time, key = t.key }, #flat_skeletons + 1

	if not parent then
		entry.from, entry.to = from, to
	end

	flat_skeletons[index] = entry

	-- Copy names of points from the joint's array into the new entry. Add the bone position
	-- as well; if one was not given, use the average of the points.
	local pos, x, y, z, n = t.pos or {}, 0, 0, 0, 0

	for _, v in ipairs(t) do
		if type(v) ~= "table" then
			entry[#entry + 1] = v

			if not t.pos then
				local point = from[v]

				x, y, z, n = x + point.x, y + point.y, z + point.z, n + 1
			end
		end
	end

	if n > 0 then
		pos.x, pos.y, pos.z = x / n, y / n, z / n
	end

	entry.pos = pos

	-- With the points now in place, revisit the array and add any child joints.
	for _, v in ipairs(t) do
		if type(v) == "table" then
			AddJoint(flat_skeletons, v, index, from)
		end
	end

	-- Find the two quaternions between which the bone will be oriented. These may be given
	-- directly; if not, a rotation around some axis is found. If the axis is a table, its
	-- components are used. Otherwise (except at the root, where the y-axis is chosen), the
	-- axis is either the displacement from the last bone, or (and this requires being at
	-- least two layers down) the "hinge" between the last two displacements.
	local amin, amax, quat1, quat2 = t.min or 0, t.max or 0, t.quat1, t.quat2

	if not (quat1 and quat2) then
		local axis, ax, ay, az = t.axis, 0, 1, 0

		if type(axis) == "table" then
			ax, ay, az = axis.x, axis.y, axis.z
		elseif parent then
			parent = flat_skeletons[parent]

			local dx, dy, dz = Sub(pos, parent.pos)

			if axis == "hinge" then
				ax, ay, az = common.CrossProduct(dx, dy, dz, Sub(flat_skeletons[parent.parent].pos, parent.pos))
			else
				ax, ay, az = dx, dy, dz
			end
		end

		quat1 = quat1 or quaternion.FromAxisAngle({}, rad(amin), ax, ay, az)
		quat2 = quat2 or quaternion.FromAxisAngle({}, rad(amax), ax, ay, az)
	end

	entry.quat1, entry.quat2 = quat1, quat2

	-- Add a position and quaternion for this bone, to act as working state during updates.
	-- TODO: While easy to implement, the problem should only requires a shallow stack.
	entry.bone_pos, entry.bone_quat = {}, {}
end

--- Constructs a new **World**.
-- @pgroup view Group to which world lines are added.
-- @number x Eye position, x-coordinate...
-- @number y ...y-coordinate...
-- @number z ...and z-coordinate.
-- @array models Models to add to world. (Sort of documented in AddJoint(), _inter alia_.)
-- @treturn World World, comprising objects (animated or not) and camera.
function M.New (view, x, y, z, models)
	-- Prepare the objects that will use the models.
	local points, lines, names = {}, {}, {}

	for _, model in ipairs(models) do
		-- The points begin untransformed, i.e. just as in the model.
		local model_points = {}

		for k, v in pairs(model.points) do
			model_points[k] = { x = v.x, y = v.y, z = v.z }
		end

		-- Hook the line segments up to their points and copy the endpoint names.
		local from, model_names = model.lines, {}

		for i = 1, #from, 2 do
			local name1, name2 = from[i], from[i + 1]

			lines[#lines + 1] = { p1 = model_points[name1], p2 = model_points[name2] }
			model_names[#model_names + 1] = name1
			model_names[#model_names + 1] = name2
		end

		points[#points + 1] = model_points
		names[#names + 1] = model_names
	end

	-- Flatten the skeletons.
	local flat_skeletons = {}

	for i, model in ipairs(models) do
		if model.skeleton then
			AddJoint(flat_skeletons, model.skeleton, false, model.points, points[i])
		end
	end

	-- Put them all together and bind the methods.
	return setmetatable({
		m_eye = { x = x, y = y, z = z },
		m_flat_skeletons = flat_skeletons,
		m_frame = common.IdentityQuaternion(),
		m_lines = lines,
		m_names = names,
		m_points = points,
		m_view = view
	}, World)
end

-- Export the module.
return M