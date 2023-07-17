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
local ceil = math.ceil

-- Modules --
local utils = require("utils")

-- Plugins --
local bytemap = require("plugin.Bytemap")

-- Solar2D globals --
local display = display
local easing = easing
local graphics = graphics
local transition = transition

-- Solar2D modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

--
--
--

function Scene:show (event)
	if event.phase == "did" then
    self.m_mask_group = display.newGroup()
  
    self.view:insert(self.m_mask_group)
  
    --
    --
    --
  
    local mtex = bytemap.newTexture{ width = 92, height = 24, format = "mask" } -- add mask padding and round

		mtex:SetBytes(char(0xFF):rep((mtex.width - 6) * (mtex.height - 6)), {
			x1 = 4, y1 = 4, x2 = mtex.width - 3, y2 = mtex.height - 3 -- offsets for mask
		})

    --
    --
    --
  
		local font = utils.FontFromText("Mayan")
    local ascent, scale = font:GetFontVMetrics(), font:ScaleForPixelHeight(15)

    utils.SubpixelLine{
      text = "Heljo World!", font = font,
      scale = scale,
      current = 2, baseline = ceil(ascent * scale),

      listener = function(bitmap, x, y, w, h)
        x, y = x + 3, y + 3 -- offset for mask
  
        mtex:SetBytes(bitmap, {
					x1 = x + 1, y1 = y + 1, x2 = x + w, y2 = y + h,
					format = "inverse"
				})
      end
    }

    --
    --
    --

    local behind = display.newCircle(self.m_mask_group, display.contentCenterX, .45 * display.contentCenterY, 40)
    
    transition.to(behind, { y = .65 * display.contentHeight, transition = easing.continuousLoop, time = 3500, iterations = 0 })

    local masked_rect = display.newRect(self.m_mask_group, display.contentCenterX, display.contentCenterY, 100, 100)

		masked_rect:setFillColor(1, 0, 1)
		masked_rect:setMask(graphics.newMask(mtex.filename, mtex.baseDir))
    mtex:releaseSelf()
	end
end

Scene:addEventListener("show")

--
--
--

function Scene:hide (event)
	if event.phase == "did" then
		self.m_mask_group:removeSelf()

		self.m_mask_group = nil
	end
end

Scene:addEventListener("hide")

return Scene