--- Scene that demonstrates basic glyph rendering.

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

-- Plugins --
local bytemap = require("plugin.Bytemap")

-- Solar2D globals --
local display = display

-- Solar2D modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

-- Show --
function Scene:show (event)
	if event.phase == "did" then
    local screen = bytemap.newTexture{ width = 85, height = 18, format = "rgb" } -- n.b. try smaller values to see clip / wrap artifacts

    --
    --
    --

    -- comments from the example:
      -- note that this stomps the old data, so where character boxes overlap (e.g. 'lj') it's wrong
      -- because this API is really for baking character bitmaps into textures. if you want to render
      -- a sequence of characters, you really need to render each bitmap to a temp buffer, then
      -- "alpha blend" that into the working buffer
    -- when packing, glyphs are separated into distinct quads, and thus overlap isn't an issue

		local font = utils.FontFromText("Mayan")
    local ascent, scale = font:GetFontVMetrics(), font:ScaleForPixelHeight(15)

    utils.SubpixelLine{
      text = "Heljo World!", -- in Arial, 'lj' was broken; Mayan has the issue with 'rl' instead ('l' stomps the right side)
      font = font, scale = scale,
      current = 2, baseline = floor(ascent * scale) + 2,

      listener = function(bitmap, x, y, w, h)
        screen:SetBytes(bitmap, {
					x1 = x + 1, y1 = y + 1, x2 = x + w, y2 = y + h,
					format = "grayscale"
				})
      end
    }

    --
    --
    --

    local object = display.newImage(screen.filename, screen.baseDir)

		object:scale(5, 5) -- zoom in

    object.x, object.y = display.contentCenterX, display.contentCenterY

    --
    --
    --

		self.m_object, self.m_screen = object, screen
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		self.m_object:removeSelf()
		self.m_screen:releaseSelf()

		self.m_object, self.m_screen = nil
	end
end

Scene:addEventListener("hide")

return Scene