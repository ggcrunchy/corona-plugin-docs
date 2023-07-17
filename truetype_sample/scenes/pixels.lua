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
local min = math.min

-- Modules --
local utils = require("utils")

-- Plugins --
local memoryBitmap = require("plugin.memoryBitmap")

-- Solar2D modules --
local composer = require("composer")

-- Solar2D globals --
local display = display
local graphics = graphics
local timer = timer

--
--
--

local Scene = composer.newScene()

--
--
--

graphics.defineEffect{
  category = "filter", name = "outline",

  fragment = [[
    P_COLOR vec4 FragmentKernel (P_UV vec2 uv)
    {
      P_COLOR vec4 color = texture2D(CoronaSampler0, uv);

      return mix(vec4(1., 0., 0., 1.), color, smoothstep(0., .1775, abs(color.r - .1775)));
    }
  ]]
}

--
--
--

local function Print (dx, n, extra, bitmap, w, h, xoff, yoff)
  local tex = memoryBitmap.newTexture{ width = w + 2 * extra, height = h + 2 * extra }
  local rect, x, y = display.newImageRect(Scene.view, tex.filename, tex.baseDir, w * n, h * n), 1, 1

  rect.x, rect.y = display.contentCenterX + dx, display.contentCenterY

  for grayscale in bitmap:gmatch(".") do
    local intensity = grayscale:byte()

    if intensity > 0 then
      local gray = intensity / 255

      tex:setPixel(x + extra, y + extra, gray, gray, gray)
    end

    x = x + 1

    if x > w then
      x, y = 1, y + 1
    end
  end

  tex:invalidate()
  tex:releaseSelf()
  
  return rect
end

--
--
--

local CodeList = "abcdefghijklmnopqrstuvwxyz0123456789"

local function GetCodepoint (index)
  index = (index - 1) % #CodeList + 1

  return CodeList:sub(index, index):byte()
end

--
--
--

function Scene:show (event)
	if event.phase == "did" then
		local font = utils.FontFromText("Mayan")--"8-BIT WONDER")

    local function ShowGlyphs (event)
      display.remove(self.m_bitmap)
      display.remove(self.m_subpixel)
      display.remove(self.m_sdf)

      --
      --
      --

      local value = GetCodepoint(event.count + 1) -- offset to accommodate `count = 0` call

      self.m_bitmap = Print(-100, 3, 1, font:GetCodepointBitmap(0, font:ScaleForPixelHeight(20), value))
      self.m_subpixel = Print(0, 1, 0, font:GetCodepointBitmapSubpixel(
        0.4972374737262726, 0.4986416995525360,
        0.2391788959503174, 0.1752119064331055,
        value))

      self.m_sdf = Print(100, 3, 1, font:GetCodepointSDF(font:ScaleForPixelHeight(32), value, 4, 128, 128 / 4))
 
      --
      --
      --
 
      self.m_sdf.fill.effect = "filter.custom.outline"

      --
      --
      --

      self.m_subpixel:scale(.2, .2)
      self.m_sdf:scale(.25, .25)
    end

    ShowGlyphs{ count = 0 } -- long-ish delay, so show the first set separately

    self.m_timer = timer.performWithDelay(750, ShowGlyphs, 0)
	end
end

Scene:addEventListener("show")

--
--
--

function Scene:hide (event)
	if event.phase == "did" then
    timer.cancel(self.m_timer)
    display.remove(self.m_bitmap)
    display.remove(self.m_subpixel)
    display.remove(self.m_sdf)

    self.m_timer, self.m_bitmap, self.m_subpixel, self.m_sdf = nil
	end
end

Scene:addEventListener("hide")

--
--
--

return Scene