--- Utilities used to build and stream shapes.

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
local pi = math.pi
local random = math.random
local sin = math.sin
local sqrt = math.sqrt
local unpack = unpack

-- Modules --
local common = require("utils.common")

-- Exports --
local M = {}

-- Helper to construct a new point
local function AddPoint (x, y, z)
	return { x = x, y = y, z = z }
end

-- Formats a prefixed name
local function Name (prefix, index)
	return ("%s:%i"):format(prefix, index)
end

-- Formats a prefix
local function Prefix (set, what, index)
	local code = index and "%s_%s%i" or "%s_%s"

	return code:format(set, what, index)
end

-- Makes some functions common to objects with spherical topologies
local function MakeFuncs (meridians, parallels)
	-- Get Names --
	return function(set)
		local names, cap_prefix = {}, Prefix(set, "cap")

		names[#names + 1] = Name(cap_prefix, 1)

		for i = 1, parallels do
			local prefix = Prefix(set, "par", i)

			for j = 1, meridians do
				names[#names + 1] = Name(prefix, j)
			end
		end

		names[#names + 1] = Name(cap_prefix, 2)

		return names
	end,

	-- Geometry --
	function(stream, names)
		-- Upper cap.
		for i = 1, meridians - 1 do
			stream:AddTri(names[i + 1], names[1], names[i + 2])
		end

		stream:AddTri(names[meridians], names[1], names[2]) -- wrap around

		-- Parallels.
		local first = 1

		for _ = 1, parallels - 1 do
			local next = first + meridians

			for j = 1, meridians - 1 do
				stream:AddQuad(names[first + j], names[first + j + 1], names[next + j + 1], names[next + j])
			end

			stream:AddQuad(names[first + meridians], names[first + 1], names[next + 1], names[next + meridians]) -- wrap around

			first = next
		end

		-- Lower cap.
		local n = #names

		for i = 1, meridians - 1 do
			stream:AddTri(names[first + i], names[first + i + 1], names[n])
		end

		stream:AddTri(names[n - 1], names[first + 1], names[n]) -- wrap around
	end
end

do
	local Meridians, Parallels = 7, 10 
	local GetNames, Cylinder = MakeFuncs(Meridians, Parallels)

	--- Add cylinder geometry to a stream.
	-- @tparam Stream stream
	-- @string set Name of point set used to build this instance.
	-- @treturn Stream stream.
	function M.Cylinder (stream, set)
		Cylinder(stream, GetNames(set))

		return stream -- for chaining
	end

	--- Gets the names belonging to a point set, which need not be populated yet.
	-- @string set Name of point set.
	-- @return ... Names in set.
	function M.CylinderNames (set)
		return unpack(GetNames(set))
	end

	-- Normalize a vector
	local function Normalize (dx, dy, dz)
		local len = sqrt(dx^2 + dy^2 + dz^2)

		return dx / len, dy / len, dz / len, len
	end

	-- Given a vector, find another (non-parallel) one
	local function OtherVector (dx, dy, dz)
		local vx, vy, vz, dot

		repeat
			vx, vy, vz = Normalize(2 * random() - 1, 2 * random() - 1, 2 * random() - 1)
			dot = common.DotProduct(dx, dy, dz, vx, vy, vz)
		until abs(dot) < .85

		return vx, vy, vz, dot
	end

	--- Populates a cylinder point set.
	-- @string set Name of point set.
	-- @tparam Vector3 p1 Center of one cap...
	-- @tparam Vector3 p2 ...and of the opposite cap.
	-- @number radius Cylinder radius.
	-- @ptable[opt] into Table to receive points. If absent, one is provided.
	-- @treturn table Name -> **Vector3** list of points.
	function M.CylinderPoints (set, p1, p2, radius, into)
		local x1, y1, z1 = p1.x, p1.y, p1.z
		local x2, y2, z2 = p2.x, p2.y, p2.z
		local dx, dy, dz, h = Normalize(x2 - x1, y2 - y1, z2 - z1)

		-- Find an arbitrary vector and its projection on the axis.
		local vx, vy, vz, k = OtherVector(dx, dy, dz)
		local px, py, pz = dx * k, dy * k, dz * k

		-- The rejection from the axis provides a direction perpendicular to the axis. From
		-- this, the cross product of it with the axis itself will yield one more. Together
		-- these two vectors describe a plane, sans position.
		local rx, ry, rz = Normalize(vx - px, vy - py, vz - pz)
		local nx, ny, nz = common.CrossProduct(dx, dy, dz, rx, ry, rz)

		-- The cylinder can be approximated by sampling points around the caps and at several
		-- parallels in between. These levels will all be parallel circles; it makes sense to
		-- reuse angular information for each, so this is computed once up front.
		local cs, names, points = { radius, 0 }, GetNames(set), into or {}

		for i = 2, Meridians do
			local angle = (i - 1) * 2 * pi / Meridians

			cs[#cs + 1] = radius * cos(angle)
			cs[#cs + 1] = radius * sin(angle)
		end

		-- Upper point.
		points[names[1]] = AddPoint(x2, y2, z2)

		-- Interior.
		local base, dh = 1, h / (Parallels - 1)

		for i = 1, Parallels do
			local dist = (i - 1) * dh
			local cx, cy, cz = x2 - dist * dx, y2 - dist * dy, z2 - dist * dz

			for j = 1, Meridians do
				local k = j * 2 - 1
				local ca, sa = cs[k], cs[k + 1]
				local x = cx + ca * nx + sa * rx
				local y = cy + ca * ny + sa * ry
				local z = cz + ca * nz + sa * rz

				points[names[base + j]] = AddPoint(x, y, z)
			end

			base = base + Meridians
		end

		-- Lower point.
		points[names[#names]] = AddPoint(x1, y1, z1)

		return points
	end
end

do
	local Meridians, Parallels = 9, 8
	local GetNames, Sphere = MakeFuncs(Meridians, Parallels)

	--- Add sphere geometry to a stream.
	-- @tparam Stream stream.
	-- @string set Name of point set used to build this instance.
	-- @treturn Stream stream.
	function M.Sphere (stream, set)
		Sphere(stream, GetNames(set))

		return stream -- for chaining
	end

	--- Gets the names belonging to a point set, which need not be populated yet.
	-- @string set Name of point set.
	-- @return ... Names in set.
	function M.SphereNames (set)
		return unpack(GetNames(set))
	end

	--- Populate a sphere point set.
	-- @string set Name of point set.
	-- @tparam Vector3 center Center of sphere.
	-- @number radius Sphere radius.
	-- @ptable[opt] into Table to receive points. If absent, one is provided.
	-- @treturn table Name -> **Vector3** list of points.
	function M.SpherePoints (set, center, radius, into)
		local names, points, x, y, z = GetNames(set), into or {}, center.x, center.y, center.z

		-- Upper point.
		points[names[1]] = AddPoint(x, y + radius, z)

		-- Interior.
		local base, dtheta, dphi = 1, 2 * pi / (Meridians + 1), pi / (Parallels + 1)

		for i = 1, Parallels do
			local phi = i * dphi
			local cphi, sphi = radius * cos(phi), radius * sin(phi)

			for j = 1, Meridians do
				local theta = (j - 1) * dtheta

				points[names[base + j]] = AddPoint(x + sphi * cos(theta), y + cphi, z + sphi * sin(theta))
			end

			base = base + Meridians
		end

		-- Lower point.
		points[names[#names]] = AddPoint(x, y - radius, z)

		return points
	end
end

-- Export the module.
return M