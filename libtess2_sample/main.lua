--- Sample for libtess2 plugin.

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
local sqrt = math.sqrt
local select = select
local unpack = unpack

-- Corona globals --
local timer = timer

--
--
--

local Ray = {}

local function DrawRay (group, sx, sy, ex, ey)
	local dx, dy = ex - sx, ey - sy
	local len = sqrt(dx^2 + dy^2)
	local head_len = min(3, .5 * len)
	local tail_len = len - head_len

	dx, dy = dx / len, dy / len

	local nx, ny = -dy, dx
	local tx, ty = sx + dx * tail_len, sy + dy * tail_len

	Ray[ 1], Ray[ 2] = sx, sy
	Ray[ 3], Ray[ 4] = tx, ty
	Ray[ 5], Ray[ 6] = tx + nx * head_len, ty + ny * head_len
	Ray[ 7], Ray[ 8] = ex, ey
	Ray[ 9], Ray[10] = tx - nx * head_len, ty - ny * head_len
	Ray[11], Ray[12] = tx, ty

	local ray = display.newLine(group, unpack(Ray))

	ray:setStrokeColor(1, 0, 0)
end

local NumberStillDrawing

local Timers = {}

local RayTime = 120

local function DrawShape (sgroup, n, shape, ...)
	if n > 0 then
		local group = display.newGroup()

		sgroup:insert(group)

		local pri, psx, psy, ptx, pty
		
		Timers[#Timers + 1] = timer.performWithDelay(35, function(event)
			local when, n = event.time, group.numChildren
			local timeouts = floor(when / RayTime)
			local last, t = timeouts + 1, when / RayTime - timeouts
			local ri, si, first, sx, sy, return_to = 1, 1
			local x, y = shape.x or 0, shape.y or 0

			repeat
				local entry = shape[si]

				if not entry then -- finished?
					timer.cancel(event.source)

					if pri then -- see notes below
						group:remove(pri)

						DrawRay(group, psx, psy, ptx, pty)
					end
					
					NumberStillDrawing = NumberStillDrawing - 1
				elseif entry == "sep" then -- switching contours?
					si, sx = si + 1
				elseif sx then -- have a previous point?
					local tx, ty = entry + x, shape[si + 1] + y

					if ri > n or ri == last then -- ray not yet drawn and / or in progress?
						local px, py = tx, ty

						if ri == last then -- interpolate if in progress
							px, py = sx + t * (tx - sx), sy + t * (ty - sy)
						end

						if ri == n then -- need to replace current entry?
							group:remove(n)
						else
							n = n + 1
						end

						if pri == ri - 1 then -- finish previous interpolation, if necessary...
							group:remove(pri)

							DrawRay(group, psx, psy, ptx, pty)
						end

						pri, psx, psy, ptx, pty = ri, sx, sy, tx, ty -- ...since it will probably miss the last stretch

						DrawRay(group, sx, sy, px, py)
					end

					ri = ri + 1

					if ri > last then -- past currently drawing ray?
						break
					else
						local next_entry = shape[si + 2]

						if return_to then -- just did a loop
							si, return_to = return_to
						elseif not next_entry or next_entry == "sep" then -- ending shape?
							si, return_to = first, si + 2
						else -- normal ray
							si = si + 2
						end

						sx, sy = tx, ty
					end
				else -- start of contour
					first, si, sx, sy = si, si + 2, entry + x, shape[si + 1] + y
				end
			until not entry -- cancel case, see above
		end, 0)

		DrawShape(sgroup, n - 1, ...)
	end
end

local function DrawAll (sgroup, ...)
	NumberStillDrawing = select("#", ...)

	for i = sgroup.numChildren, 1, -1 do
		sgroup:remove(i)
	end
	
	for i = 1, #Timers do
		timer.cancel(Timers[i])

		Timers[i] = nil
	end
	
	DrawShape(sgroup, NumberStillDrawing, ...)
end

local g = display.newGroup()

local W, H = display.contentWidth, display.contentHeight

local L1, L2, L3 = 8, 20, 30

local BoxCCW = {
	x = .25 * W, y = .3 * H,

	L1, -L1, -L1, -L1, -L1, L1, L1, L1, "sep", -- inner square
	L2, -L2, -L2, -L2, -L2, L2, L2, L2, "sep", -- middle square
	L3, -L3, -L3, -L3, -L3, L3, L3, L3 -- outer square
}

local BoxMixed = {
	x = .75 * W, y = .3 * H,

	-L1, -L1, L1, -L1, L1, L1, -L1, L1, "sep", -- inner square
	-L2, -L2, L2, -L2, L2, L2, -L2, L2, "sep", -- middle square
	L3, -L3, -L3, -L3, -L3, L3, L3, L3 -- outer square
}

local Overlap = {
	x = .25 * W, y = .6 * H,

	-L2, -L3, L2, -L3, L2, L3, -L2, L3, "sep", -- tall rect
	L3, -L1, -L3, -L1, -L3, L1, L3, L1, "sep", -- wide rect
	L1, -L2, -L1, -L2, 0, L3 + 15 -- triangle
}

local L4 = 40

local SelfIntersectingSpiral = {
	x = .75 * W, y = .6 * H,

	-L1, -L1, -L1, L1, L1, L1, -- first loop
	L1, -L2, -L2, -L2, -L2, L2, L2, L2, -- second loop
	L2, -L3, -L3, -L3, -L3, L3, L3, L3, -- third loop
	L3, -L4, -L4, -L4, -L4, L4, L4, L4, L4, -L1 -- final loop
}

DrawAll(g, BoxCCW, BoxMixed, Overlap, SelfIntersectingSpiral)

local function FourExamples ()
	--
end

local ButtonW, ButtonH = 100, 30
local prev = display.newRoundedRect(5 + ButtonW / 2, H - ButtonH / 2 - 25, ButtonW, ButtonH, 12)
local next = display.newRoundedRect(W - ButtonW / 2 - 5, prev.y, ButtonW, ButtonH, 12)

prev:setFillColor(0, 0, 1)
next:setFillColor(0, 0, 1)

display.newText("Previous", prev.x, prev.y, native.systemFontBold, 14)
display.newText("Next", next.x, next.y, native.systemFontBold, 14)

local Description = display.newText("", display.contentCenterX, prev.y, native.systemFontBold, 12)