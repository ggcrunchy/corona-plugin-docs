--- Scene that demonstrates glyph contours.

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
local ceil = math.ceil
local floor = math.floor
local random = math.random

-- Modules --
local utils = require("utils")

-- Solar2D globals --
local display = display
local timer = timer
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

local function NewPoint (x, y, positions)
  positions[#positions + 1] = x
  positions[#positions + 1] = y
end

--
--
--

local DoContours = utils.MakeContourListener{ add_point = NewPoint, move = NewPoint }

--
--
--

local PixelTime = 15

--
--
--

local FadeInParams, FadeOutParams, SpinParams = { alpha = .625 }, { alpha = 0 }, {}

local function SpawnObject (active, stash, x, y)
  local n, object = stash.numChildren

  if n > 0 then
    object = stash[n]
  else
    object = display.newRect(0, 0, .45, .45)

    object:setFillColor(0, 0)
    
    object.alpha, object.strokeWidth = 0, 1
  end

  object.x, object.y = random(x - 2, x + 2), random(y - 2, y + 2)

  object:setStrokeColor(random(), random(), random())
  active:insert(object)

  SpinParams.rotation = random(-235, 235)
  SpinParams.time = random(300, 700)

  transition.to(object, FadeInParams)
  transition.to(object, SpinParams)
end

--
--
--

function Scene:show (event)
	if event.phase == "did" then
    local active, stash = display.newGroup(), display.newGroup()

    stash.isVisible = false

    self.m_active = active
    self.m_stash = stash

    self.view:insert(active)
    self.view:insert(stash)

    --
    --
    --
    
    function FadeInParams:onComplete ()
      if self.removeSelf then
        FadeOutParams.time = random(3600, 5800)

        transition.to(self, FadeOutParams)
      end
    end
    
    function FadeOutParams:onComplete ()
      if self.removeSelf then
        stash:insert(self)
      end
    end

    --
    --
    --

		local font, positions = utils.FontFromText("Mayan"), { segment_lines = true }

    utils.ShapesLine{
      text = "3d!7g8mMn", font = font,
      scale = font:ScaleForPixelHeight(15) * 5.5,
      current = 25, baseline = 200,
      listener = DoContours, arg = positions
    }

    --
    --
    --

    local index, was, start = 1, 0

    self.m_timer = timer.performWithDelay(25, function(event)
      start = start or event.time

      local now = (event.time - start) / PixelTime
      local pos = floor(now)

      for _ = ceil(was), pos do
        local x, y = positions[index], positions[index + 1]

        if x then
          for _ = 1, 3 do
            SpawnObject(active, stash, x, y)
          end
        else
          timer.cancel(event.source) -- TODO: or reset
        end

        index = index + 2
      end

      was = now
    end, 0)
	end
end

Scene:addEventListener("show")

--
--
--

function Scene:hide (event)
	if event.phase == "did" then
		self.m_active:removeSelf()
		self.m_stash:removeSelf()

    timer.cancel(self.m_timer)

    self.m_active, self.m_stash, self.m_timer = nil
	end
end

Scene:addEventListener("hide")

--
--
--

return Scene