--- Scene that demonstrates masking of glyphs.

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
local char = string.char
local concat = table.concat
local floor = math.floor

-- Modules --
local utils = require("utils")

-- Plugins --
local bytemap = require("plugin.Bytemap")

-- Corona globals --
local display = display
local easing = easing
local transition = transition

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local BackParams = { y = .65 * display.contentHeight, transition = easing.continuousLoop, time = 3500, iterations = 0 }

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		local font = utils.FontFromText("Mayan")
        local xpos = 2 -- leave a little padding in case the character extends left
        local text = "Heljo World!" -- intentionally misspelled to show 'lj' brokenness (TODO: revise to demonstrate)
        local mask = bytemap.newTexture{ width = 92, height = 24, format = "mask" } -- add mask padding and round

        local scale = font:ScaleForPixelHeight(15)
        local ascent = font:GetFontVMetrics()
        local baseline = math.ceil(ascent * scale)

		mask:SetBytes(char(0xFF):rep((mask.width - 6) * (mask.height - 6)), {
			x1 = 4, y1 = 4, x2 = mask.width - 3, y2 = mask.height - 3 -- offsets for mask
		})
		
        local i, n = 1, #text

        for i = 1, n do
            local ch = text:byte(i)
            local xshift = xpos % 1
            local advance, lsb = font:GetCodepointHMetrics(ch)
        --  local x0, y0, x1, y1 = font:GetCodepointBitmapBoxSubpixel(ch, scale, scale, xshift, 0)
		--	local w, h = x1 - x0, y1 - y0
		--	N.B. the following supplies the details from the above as conveniences
            local bitmap, w, h, x0, y0 = font:GetCodepointBitmapSubpixel(scale, scale, xshift, 0, ch)

			if bitmap then -- might be space, etc. (with box we would get w = h = 0)
				local inverted, xf, yf = {}, floor(xpos) + x0 + 3, baseline + y0 + 3 -- offset for mask

				for cbyte in bitmap:gmatch(".") do
					inverted[#inverted + 1] = char(0xFF - cbyte:byte())
				end

				bitmap = concat(inverted)

				mask:SetBytes(bitmap, {
					x1 = xf + 1, y1 = yf + 1, x2 = xf + w, y2 = yf + h
				})
			end

			-- TODO: this is not in the current sample but should return later using the Make APIs
            -- note that this stomps the old data, so where character boxes overlap (e.g. 'lj') it's wrong
            -- because this API is really for baking character bitmaps into textures. if you want to render
            -- a sequence of characters, you really need to render each bitmap to a temp buffer, then
            -- "alpha blend" that into the working buffer

            xpos = xpos + advance * scale

            if i < n then
                xpos = xpos + scale * font:GetCodepointKernAdvance(ch, text:byte(i + 1))

                i = i + 1
            end
        end

        local simage = display.newRect(display.contentCenterX, display.contentCenterY, 100, 100)

		simage:setFillColor(1, 0, 1)

		local smask = graphics.newMask(mask.filename, mask.baseDir)

		simage:setMask(smask)
		simage:scale(5, 5) -- zoom in on the word

		self.m_object, self.m_mask = simage, mask

		local behind = display.newRect(display.contentCenterX, .45 * display.contentCenterY, 90, 90)

		behind:toBack()

		transition.to(behind, BackParams)

		self.m_behind = behind
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		self.m_behind:removeSelf()
		self.m_object:removeSelf()
		self.m_mask:releaseSelf()

		self.m_behind, self.m_object, self.m_mask = nil
	end
end

Scene:addEventListener("hide")

return Scene