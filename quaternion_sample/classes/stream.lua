--- A class used to build up models from a stream.

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
local setmetatable = setmetatable

-- Exports --
local M = {}

-- Stream metatable --
local Stream = {}

Stream.__index = Stream

-- Helper to add pairs to the stream without duplication
local function AddPair (stream, filter, a, b)
	if b < a then
		a, b = b, a
	end

	local key = ("%s:%s"):format(a, b)

	if not filter[key] then
		stream[#stream + 1] = a
		stream[#stream + 1] = b

		filter[key] = true
	end
end

--- Add a quad to the stream.-- @string a Name of first...
-- @string b ...second...
-- @string c ...third...
-- @string d ...and fourth point.
-- @treturn Stream Self, for chaining.
function Stream:AddQuad (a, b, c, d)
	local stream, filter = self.m_stream, self.m_filter

	AddPair(stream, filter, a, b)
	AddPair(stream, filter, b, c)
	AddPair(stream, filter, c, d)
	AddPair(stream, filter, d, a)

	return self -- for chaining
end

--- Add a triangle to the stream.
-- @string a Name of first...
-- @string b ...second...
-- @string c ...and third point.
-- @treturn Stream Self, for chaining.
function Stream:AddTri (a, b, c)
	local stream, filter = self.m_stream, self.m_filter

	AddPair(stream, filter, a, b)
	AddPair(stream, filter, b, c)
	AddPair(stream, filter, c, a)

	return self -- for chaining
end

--- Begins a stream.
-- @treturn Stream Self, for chaining.
function Stream:Begin ()
	self.m_filter, self.m_stream = {}, {}

	return self -- for chaining
end

-- Commit the polygon stream
function Stream:End ()
	local stream = self.m_stream

	self.m_stream = nil

	return stream
end

--- Constructs a new **Stream**.
-- @treturn Stream Polygon stream.
function M.New ()
	return setmetatable({}, Stream)
end

-- Export the module.
return M