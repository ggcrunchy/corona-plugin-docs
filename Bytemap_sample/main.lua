--- Sample for Bytemap plugin.

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

--[[
local impack = require("plugin.impack")
local bytemap = require("plugin.Bytemap")

local bbytes, w, h = impack.image.load("FLAG.TGA")
local btex = bytemap.newTexture{ width = w, height = h, format = "rgba" }

btex:SetBytes(bbytes)

local brush = display.newImage(btex.filename, btex.baseDir)

brush.x, brush.y = display.contentCenterX, display.contentCenterY

local larger = bytemap.newTexture{
	width = math.floor(.75 * display.contentWidth),
	height = math.floor(.75 * display.contentHeight),
	format = "rgba"
}

local fill_me = display.newImage(larger.filename, larger.baseDir)

fill_me.x, fill_me.y = brush.x, brush.y

local fbounds = fill_me.contentBounds
local frect = display.newRect(fill_me.x, fill_me.y, fbounds.xMax - fbounds.xMin, fbounds.yMax - fbounds.yMin)

frect:setFillColor(0, 0)
frect:setStrokeColor(1, 0, 0)

frect.strokeWidth = 2

brush.alpha = .45

local fw, fh = fill_me.width, fill_me.height

local function GetBytes (info)
	local bytes = ""

	if info.x2 >= 1 and info.x1 <= fw and info.y2 >= 1 and info.y1 <= fh then
		local x1, y1, x2, y2 = info.x1, info.y1, info.x2, info.y2
		local xoff, yoff = 0, 0

		if x1 <= 0 then
			xoff = xoff - x1 + 1
		end

		if x2 > fw then
			x2 = fw
		end

		if y1 <= 0 then
			yoff = yoff - y1 + 1
		end

		if y2 > fh then
			y2 = fh
		end

		local stride = w * 4
		local offset = yoff * stride + xoff * 4
		local bw = (x2 - (x1 + xoff) + 1) * 4

		for y = y1 + yoff, y2 do
			bytes = bytes .. bbytes:sub(offset + 1, offset + bw)
			offset = offset + stride
		end
	end

	return bytes
end

brush:addEventListener("touch", function(event)
	local phase, target = event.phase, event.target

	if phase == "began" or phase == "moved" then
		if phase == "began" then
			display.getCurrentStage():setFocus(target)

			target.xwas, target.ywas = event.x, event.y
		else
			target.x, target.y = target.x + event.x - target.xwas, target.y + event.y - target.ywas
			target.xwas, target.ywas = event.x, event.y
		end

		local bounds = target.contentBounds
		local x1m1, y1m1 = bounds.xMin - fbounds.xMin, bounds.yMin - fbounds.yMin
		local info = {}
		local config = {
			x1 = x1m1 + 1, x2 = x1m1 + w,
			y1 = y1m1 + 1, y2 = y1m1 + h,
			get_info = info
		}

		larger:SetBytes(btex:GetBytes(), config)
		larger:invalidate()

		local bytes = GetBytes(config)
		local lbytes = larger:GetBytes(config)

		print("COMPARE!", bytes == lbytes)
	elseif phase == "ended" or phase == "cancelled" then
		display.getCurrentStage():setFocus(nil)
	end

	return true
end)
]]
