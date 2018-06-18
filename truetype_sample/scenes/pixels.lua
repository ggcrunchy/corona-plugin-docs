--- Scene that demonstrates glyph pixels.

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
local floor = math.floor

-- Modules --
local utils = require("utils")

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local function Print (bitmap, w, h)
    local index, text = 1, " .:ioVM@"

    for _ = 1, h do
        local line = ""

        for _ = 1, w do
            local pos = floor(bitmap:sub(index, index):byte() / 32) + 1

            line, index = line .. text:sub(pos, pos), index + 1
        end

        print(line)
    end
end

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		local font = utils.FontFromText("8-BIT WONDER")
		local bitmap, w, h = font:GetCodepointBitmap(0, font:ScaleForPixelHeight(20), ("a"):byte())

        Print(bitmap, w, h)
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then

	end
end

Scene:addEventListener("hide")

return Scene