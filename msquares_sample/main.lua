--- Sample for msquares plugin.

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
	{ scene = "masks_and_meshes", text = "Paint, Then Convert To Masks + Meshes" },
	-- { scene = "color_key", text = "Color Key From Image" } (nanosvg)
	-- { scene = "static_objects", text = "Paint, Then Convert To Obstacles" }
	-- { scene = "gospers_glider_gun", text = "Gosper's Glider Gun" } (metal?)
	-- { scene = "plotting", text = "Plotting a function" }
--[[
- SVG stuff from tests
- 3D examples when "object3d" is ready
- Mask, also passed via bytes -> floats
- Color-keyed paint example
- Something with float array
- Use serialize to send actual floats?
- Physics obstacles
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