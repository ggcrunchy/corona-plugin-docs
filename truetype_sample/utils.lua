--- Utilities for truetype sample.

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

-- Standard library imports --
local floor = math.floor
local min = math.min
local open = io.open
local sqrt = math.sqrt

-- Plugins --
local truetype = require("plugin.truetype")
local utf8 = require("plugin.utf8")

-- Solar2D globals --
local system = system

-- Exports --
local M = {}

--
--
--

function M.AddContourAndGetMin (tess, points, minx, miny)
  for i = 1, #points, 2 do
    minx, miny = min(minx, points[i]), min(miny, points[i + 1])
  end

  tess:AddContour(points)

  return minx, miny
end

--
--
--

-- Fonts should be renamed as .TXT files to accommodate Android
-- See: https://docs.coronalabs.com/guide/data/readWriteFiles/index.html#copying-files-to-subfolders
function M.FontFromText (name)
-- local file = open("c:/windows/fonts/arialbd.ttf", "rb") -- original test in stb_truetype.h
	local file = open(system.pathForFile("fonts/text/" .. name .. "-FONT.TXT"), "rb")

	if file then
		local contents = file:read("*a")

		file:close()

		return truetype.InitFont(contents, truetype.GetFontOffsetForIndex(contents)), contents
	end
end

--
--
--

local Samples, Length = {}

local function AddSample (j, x, y)
  if j > 1 then
    Length = Length + sqrt((x - Samples[j - 3])^2 + (y - Samples[j - 2])^2)
  else
    Length = 0
  end
  
  Samples[j], Samples[j + 1], Samples[j + 2] = x, y, Length

  return j + 3
end

local function Fit (s)
  local j = 4

  while true do -- s is fraction of full length, so will terminate
    local len2 = Samples[j + 2]

    if s < len2 then
      local x2, y2 = Samples[j], Samples[j + 1]
      local x1, y1, len1 = Samples[j - 3], Samples[j - 2], Samples[j - 1]
      local t = (s - len1) / (len2 - len1)

      return x1 + t * (x2 - x1), y1 + t * (y2 - y1)
    end

    j = j + 3
  end
end

local function GetLength (j)
  return Samples[j - 1]
end

--
--
--

local function AuxCubic ()
  -- TODO!
end

--
--
--

local SampleCount = 30

local function AuxQuadratic (add_point, spacing, xpos, ypos, prevx, prevy, scale, x, y, cx, cy, arg)
  local j = AddSample(1, prevx, prevy)

  for i = 1, SampleCount do
    local t = i / SampleCount
    local s = 1 - t
    local a, b, c = s^2, 2 * s * t, t^2

    j = AddSample(j, a * prevx + b * cx + c * x, a * prevy + b * cy + c * y)
  end

  local s, len = 0, GetLength(j)

  while s < len do
    local qx, qy = Fit(s)

    add_point(xpos + qx * scale, ypos - qy * scale, arg)

    s = s + spacing
  end
end

--
--
--

local function AuxSegmentedLine (arg, add_point, spacing, xpos, ypos, prevx, prevy, scale, x, y)
  local dx, dy = x - prevx, y - prevy
  local len = sqrt(dx^2 + dy^2) / spacing

  x, y, dx, dy = xpos + prevx * scale, ypos - prevy * scale, dx / len, dy / len

  for _ = 1, len do
    add_point(x, y, arg)

    x, y = x + dx * scale, y - dy * scale
  end
end

--
--
--

local function AuxLine (arg, add_point, _, xpos, ypos, prevx, prevy, scale)
  add_point(xpos + prevx * scale, ypos - prevy * scale, arg)
end

--
--
--

function M.MakeContourListener (params)
  local add_point, finish, move, start = params.add_point, params.finish, params.move, params.start
  local spacing = params.spacing or 30

  return function(shape, xpos, ypos, scale, arg)
    local prevx, prevy
local xx,yy=xpos,ypos
    if start then
      start(arg)
    end
xpos,ypos=0,0
    local do_line = arg.segment_lines and AuxSegmentedLine or AuxLine

    for i = 1, #(shape or "") do -- ignore non-shapes such as spaces
      local what, x, y, cx, cy, cx1, cy1 = shape:GetVertex(i)

      if what == "line_to" then
        do_line(arg, add_point, spacing, xpos, ypos, prevx, prevy, scale, x, y)
      elseif what == "curve_to" then
        AuxQuadratic(add_point, spacing, xpos, ypos, prevx, prevy, scale, x, y, cx, cy, arg)
      elseif what == "cubic_to" then
        AuxCubic(add_point, spacing, xpos, ypos, prevx, prevy, scale, x, y, cx, cy, cx1, cy1, arg)
      else
        move(xpos + x * scale, ypos - y * scale, arg)
      end

      prevx, prevy = x, y
    end

    if finish then
      finish(arg,xx,yy)
    end
  end
end

--
--
--

local LineState = {}

local function BuildLineState (text, font, scale, current)
  local count, cp_prev = 0

  for _, cp_cur in utf8.codes(text) do
	if cp_prev then
      current = current + scale * font:GetCodepointKernAdvance(cp_prev, cp_cur)
	end
  
    LineState[count + 1] = cp_cur
    LineState[count + 2] = current
    count = count + 2

    --
    --
    --

    local advance, _ = font:GetCodepointHMetrics(cp_cur)

    current, cp_prev = current + advance * scale, cp_cur
  end

  return count
end

--
--
--

local function MakeLineStateFunc (func)
  return function(params)
    local font, ypos, listener = params.font, params.baseline, params.listener
    local scale, arg = params.scale or 1, params.arg

    for i = 1, BuildLineState(params.text, font, scale, params.current), 2 do
      func(font, scale, LineState[i], LineState[i + 1], ypos, listener, arg)
    end
  end
end

--
--
--

M.ShapesLine = MakeLineStateFunc(function(font, scale, cp_cur, xpos, ypos, listener, arg)
  local ok, x0, y0, _ = font:GetCodepointBox(cp_cur)

  if ok then
    listener(font:GetCodepointShape(cp_cur), xpos + scale * x0, ypos + scale * y0, scale, arg)
  end
end)

--
--
--

M.SubpixelLine = MakeLineStateFunc(function(font, scale, cp_cur, xpos, ypos, listener, arg)
  local bitmap, w, h, x0, y0 = font:GetCodepointBitmapSubpixel(scale, scale, xpos % 1, 0, cp_cur)

  if bitmap then
    listener(bitmap, floor(xpos) + x0, ypos + y0, w, h, arg)
  end
end)

--
--
--

return M