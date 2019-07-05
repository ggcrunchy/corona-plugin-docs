--- Sample for Clipper plugin.

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
local utils = require("utils")

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
	{ scene = "csg", text = "Constructive solid geometry" },
	{ scene = "intersection", text = "Intersecting shapes" },
	{ scene = "minkowski_sum", text = "Minkowski sum"},
	{ scene = "offset", text = "Polygon offset" }
--[[
- Luapower example, more or less
- Make SVGs?
- "Art" program
- Build on libtess2, serialize?
]]
}

--[=[

Example from http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Classes/PolyTree/_Body.htm

--[[
 polytree: 
    Contour = ()
    ChildCount = 1
    Childs[0]: 
        Contour = ((10,10),(100,10),(100,100),(10,100))
        IsHole = False
        ChildCount = 1
        Childs[0]: 
            Contour = ((20,20),(20,90),(90,90),(90,20))
            IsHole = True
            ChildCount = 2
            Childs[0]: 
                Contour = ((30,30),(50,30),(50,50),(30,50))
                IsHole = False
                ChildCount = 0
            Childs[1]: 
                Contour = ((60,60),(80,60),(80,80),(60,80))
                IsHole = False
                ChildCount = 0
]]

local outer = display.newLine(10, 10, 100, 10, 100, 100, 10, 100 --[[ ]], 10, 10)
local inner = display.newLine(20, 20, 20, 90, 90, 90, 90, 20 --[[ ]], 20, 20)

local box1 = display.newLine(30, 30, 50, 30, 50, 50, 30, 50 --[[ ]], 30, 30)
local box2 = display.newLine(60, 60, 80, 60, 80, 80, 60, 80 --[[ ]], 60, 60)

outer.strokeWidth = 4
inner.strokeWidth = 4
box1.strokeWidth = 4
box2.strokeWidth = 4

]=]

--[=[
local CX, CY = display.contentCenterX, display.contentCenterY

local CW, CH = display.contentWidth, display.contentHeight

local arrowhead = display.newLine(CW - 95, CY, 100, CY, CW - 175, CH - 250)

arrowhead.strokeWidth = 3

local function Loop (x, y, ...)
	local line = display.newLine(x, y, ...)

	line:append(x, y)

	return line
end

local box = Loop(145, CY - 100, CW - 175, CY - 110, CW - 175, CH - 300, 150, CH - 315)

box.strokeWidth = 3

local poly = Loop(55, CY - 120, CX - 10, CY - 200, CW - 120, CY + 100, 180, CH - 235, CX, CY + 120)

poly.strokeWidth = 3

local curve = display.newLine(50, CH - 315, 
	86, 638, 120, 620, 150, 592,
	174, 576, 192, 562,
	226, 500, 232, 478,
	240, 442, 252, 404, 263, 384, 272, 370,
	285, 352, 294, 344,
	318, 330, 352, 318, 384, 314)

curve.strokeWidth = 3

--[[
local r = display.newRect(CX, CY, CW, CH)

r:toBack()
r:setFillColor(1,0,0)
r:addEventListener("touch", function(event)
	if event.phase == "ended" then
		print("!!", event.x, event.y)
	end

	return true
end)]]
]=]

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