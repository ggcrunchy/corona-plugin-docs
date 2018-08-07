--- Scene that demonstrates boundary contours tessellation with the negative winding rule.

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
local ipairs = ipairs
local max = math.max
local random = math.random

-- Modules --

-- Plugins --
local memoryBitmap = require("plugin.memoryBitmap")
local msquares = require("plugin.msquares")

-- Corona globals --
local physics = physics

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local Stencil = {
	w = 7,

	1, 1, 0, 0, 0, 1, 1,
	1, 1, 1, 0, 1, 1, 1,
	0, 1, 1, 1, 1, 1, 0,
	0, 0, 1, 1, 1, 0, 0,
	0, 1, 1, 1, 1, 1, 0,
	1, 1, 1, 0, 1, 1, 1,
	1, 1, 0, 0, 0, 1, 1
}

assert(#Stencil % Stencil.w == 0, "Missing values")

local NRows = #Stencil / Stencil.w
local ColOffset = floor(Stencil.w / 2)
local RowOffset = floor(NRows / 2)

local CellW, CellH = 100, 80
local CellSize = 2
local TexW, TexH = CellW * CellSize, CellH * CellSize

local function RoundToMultipleOf4 (x)
	x = x + 3

	return x - x % 4
end

local Opaque, Transparent = char(0xFF), char(0)

local function CanvasTouch (event)
	local phase, target = event.phase, event.target

	if phase == "began" or phase == "moved" then
		if phase == "began" then
			display.getCurrentStage():setFocus(target)

			target.touched = true
		elseif not target.touched then
			return false
		end

		-- Render any visible part of the brush and update the texture and mask.
		local color = target.m_color
		local texture = target.m_texture
		local bounds, index = target.contentBounds, 1
		local c0 = floor(event.x - bounds.xMin) - ColOffset
		local r0 = floor(event.y - bounds.yMin) - RowOffset

		for roff = 1, NRows do
			local row = r0 + roff

			if row > TexH then
				break
			elseif row >= 1 then
				local rbase = (row - 1) * TexW

				for coff = 1, Stencil.w do
					local col = c0 + coff

					if col >= 1 and col <= TexW then
						if Stencil[index] == 1 then
							texture:setPixel(col, row, .3, .3, .3)
						end
					end

					index = index + 1
				end
			else
				index = index + Stencil.w
			end
		end

		texture:invalidate()
	elseif phase == "ended" or phase == "cancelled" then
		display.getCurrentStage():setFocus(nil)

		target.touched = false
	end

	return true
end

local function Button (view, text, x, y, action, r, g, b)
	local button = display.newRoundedRect(view, x, y, 100, 25, 12)
	local fr, fg, fb = r / 0xFF, g / 0xFF, b / 0xFF

	button:addEventListener("touch", function(event)
		if event.phase == "began" then
			action()
		end

		return true
	end)
	button:setFillColor(r, g, b)

	local str = display.newText(view, text, 0, button.y, native.systemFontBold, 15)

	str:setFillColor(.2)

	str.anchorX, str.x = 0, x - 35
end

local CX, CY = display.contentCenterX, display.contentCenterY
local Y0 = display.screenOriginY

local function RandomScale ()
	return .725 + random() * .275
end

local ButtonX, ButtonY = 410, 100

-- Create --
function Scene:create (event)
	local canvas = display.newRect(self.view, CX, CY, TexW, TexH)

	canvas:addEventListener("touch", CanvasTouch)

	self.m_canvas = canvas

	local frame = display.newRect(self.view, canvas.x, canvas.y, canvas.contentWidth, canvas.contentHeight)

	frame:setFillColor(0, 0)

	frame.alpha, frame.strokeWidth = .7, 6
--[[
	local what, y = "Empty", 95

	for i, color in ipairs(ColorValues) do
		local function Body ()
			canvas.m_color = color.bytes

			frame:setStrokeColor(color.r, color.g, color.b)
		end

		local button = Button(self.view, what, 65, y, Body, color.r, color.g, color.b)

		if i == 1 then
			Body()
		end

		what, y = ("Object #%i"):format(i), y + 32
	end
]]
	frame:toFront()

	local reset

	local go = Button(self.view, "Go!", ButtonX, ButtonY, function()
		local mask = bytemap.newTexture{
			width = RoundToMultipleOf4(TexW + 6), height = RoundToMultipleOf4(TexH + 6), format = "mask"
		}

		local ex, ey = floor((mask.width - TexW) / 2), floor((mask.height - TexH) / 2)
		local mbytes = concat(canvas.m_mask_bytes)
		
		mask:SetBytes(mbytes, { x1 = ex + 1, x2 = ex + TexW, y1 = ey + 1, y2 = ey + TexH })

		canvas:setMask(graphics.newMask(mask.filename, mask.baseDir))

		self.m_mask = mask

		local mlist = msquares.color_multi(canvas.m_texture:GetBytes(), TexW, TexH, CellSize, 3)
		local size = max(TexW, TexH) -- msquares normalizes against maximum

		for i = 1, #mlist do
			local color_mesh = mlist:GetMesh(i)
			local mc = color_mesh:GetColor()

			for j = 2, #ColorValues do -- 1 = background
				local color = ColorValues[j]

				if mc == color.uint then
					local points, uvs, verts = color_mesh:GetPoints(), {}, {}

					break
				end
			end
		end
	end, 0, 0, 1)

	-- reset button

	local about = display.newText(self.view, "Drag inside the rect to paint using the frame color", CX, 65, native.systemFontBold, 15)

	-- Go! button / Reset (depending on what's going on)
end

Scene:addEventListener("create")

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		physics.start()

		local texture = memoryBitmap.newTexture{ width = TexW, height = TexH, format = "rgb" }

		self.m_canvas.fill = { type = "image", filename = texture.filename, baseDir = texture.baseDir }

		self.m_canvas.m_texture = texture
	end
end

Scene:addEventListener("show")

--[[
	P_COLOR vec4 FragmentKernel (P_UV vec2 uv)
	{
		P_COLOR vec4 data = texture2D(CoronaSampler0, uv);
		P_UV vec3 n = vec3(2. * data.yz - 1., 0.);
		
		n.z = sqrt(max(1. - dot(n, n), 0.));

		P_UV vec3 ldir = vec3(ldir_xy * data.x, 3.75 * CoronaVertexUserData.w);

		ldir = normalize(ldir);

		P_UV float sim = max(dot(n, ldir), 0.);
		P_UV vec3 r = reflect(ldir, n);
		P_COLOR vec3 m = .35 * (vec3(.1 * IQ(r.xy), .3 * IQ(r.yz), .1 * IQ(r.xz) * data.x) + .5);
		P_COLOR vec4 color = vec4(mix(m, vec3(pow(1. - r.x, data.x)), .15) + vec3(pow(sim, 60.)), 1.);
//if (true) return vec4(data.yz,0.,1.);
		return clamp(color, 0., 1.) * smoothstep(.75, 1., data.a);
	}
]]

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		physics.stop()

		self.m_canvas.m_texture:releaseSelf()

		self.m_canvas.m_texture = nil
	end
end

Scene:addEventListener("hide")

return Scene