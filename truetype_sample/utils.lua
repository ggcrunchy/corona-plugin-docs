--- Utilities for truetype sample.

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

-- Standard library imports --
local open = io.open

-- Plugins --
local truetype = require("plugin.truetype")

-- Corona globals --
local system = system

-- Exports --
local M = {}

--
--
--

-- Fonts should be renamed as .TXT files to accommodate Android
-- See: https://docs.coronalabs.com/guide/data/readWriteFiles/index.html#copying-files-to-subfolders
function M.FontFromText (name, index)
	local file = open(system.pathForFile("fonts/text/" .. name .. "-FONT.TXT"), "rb")

	if file then
		local contents = file:read("*a")

		file:close()

		return truetype.InitFont(contents, truetype.GetFontOffsetForIndex(contents, index or 0)), contents
	end
end

return M