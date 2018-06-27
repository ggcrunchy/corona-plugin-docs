--- Test for truetype plugin.

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

-- Corona modules --
local composer = require("composer")

--
--
--

local W, H = display.contentWidth, display.contentHeight
local ButtonW, ButtonH = 100, 30
local prev = display.newRoundedRect(5 + ButtonW / 2, H - ButtonH / 2 - 25, ButtonW, ButtonH, 12)
local next = display.newRoundedRect(W - ButtonW / 2 - 5, prev.y, ButtonW, ButtonH, 12)

prev:setFillColor(0, 0, 1)
next:setFillColor(0, 0, 1)

display.newText("Previous", prev.x, prev.y, native.systemFontBold, 14)
display.newText("Next", next.x, next.y, native.systemFontBold, 14)

local Description = display.newText("", display.contentCenterX, prev.y, native.systemFontBold, 12)

local Examples = {
	{ scene = "basic", text = "Basic string (stretched)" },
	{ scene = "pixels", text = "Glyph pixels (see console)" },
	{ scene = "mesh", text = "Glyph meshes" },
	{ scene = "contour", text = "Glyph contours" },
	{ scene = "masked", text = "Glyphs to mask" }
--[[
NOTES for future ideas:

- UTF-8
- Right-to-left
- Animated patterns, etc.
- Following a curve
- Packing a bitmap
- Using a blob
- Outlining
- Squishy physics
- Build on above libs, maybe "object3d"...
]]
}

local Index = 1

local function GoToExample ()
	Description.text = Examples[Index].text

	composer.gotoScene("scenes." .. Examples[Index].scene)
end

local function Touch (update_index)
	return function(event)
		if event.phase == "began" then
			update_index()
			GoToExample()
		end
	end
end

prev:addEventListener("touch", Touch(function()
	Index = Index - 1

	if Index == 0 then
		Index = #Examples
	end
end))

next:addEventListener("touch", Touch(function()
	Index = Index + 1

	if Index > #Examples then
		Index = 1
	end
end))

GoToExample()