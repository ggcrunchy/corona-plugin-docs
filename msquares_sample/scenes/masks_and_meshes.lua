--- Scene that demonstrates the abs >= 2 winding rule.

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
local utils = require("utils")

-- Plugins --
local bytemap = require("plugin.Bytemap")
local msquares = require("plugin.msquares")

-- Corona globals --
local display = display
local graphics = graphics
local transition = transition

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local Stencil = {
	w = 7,

	0, 0, 1, 1, 1, 0, 0,
	0, 1, 1, 1, 1, 1, 0,
	1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1,
	0, 1, 1, 1, 1, 1, 0,
	0, 0, 1, 1, 1, 0, 0
}

assert(#Stencil % Stencil.w == 0, "Missing values")

local NRows = #Stencil / Stencil.w
local ColOffset = floor(Stencil.w / 2)
local RowOffset = floor(NRows / 2)

local Colors = {
	0x70, 0x70, 0x70,
	0xFF, 0x00, 0x00,
	0x00, 0xFF, 0x00,
	0x00, 0x00, 0xFF,
	0xFF, 0xFF, 0x00
}

local ColorValues = {}

for i = 1, #Colors, 3 do
	local r, g, b = Colors[i], Colors[i + 1], Colors[i + 2]

	ColorValues[#ColorValues + 1] = {
		bytes = char(r, g, b),
		uint = r * 2^16 + g * 2^8 + b,
		r = r / 0xFF,
		g = g / 0xFF,
		b = b / 0xFF
	}
end

local CellW, CellH = 100, 80
local CellSize = 2
local TexW, TexH = CellW * CellSize, CellH * CellSize

local function RoundToMultipleOf4 (x)
	x = x + 3

	return x - x % 4
end

local Opts = {}

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
		local color, mask_bytes = target.m_color, target.m_mask_bytes
		local texture, mask = target.m_texture, color == ColorValues[1].bytes and Opaque or Transparent
		local bounds, index = target.contentBounds, 1
		local c0 = floor(event.x - bounds.xMin) - ColOffset
		local r0 = floor(event.y - bounds.yMin) - RowOffset

		for roff = 1, NRows do
			local row = r0 + roff

			if row > TexH then
				break
			elseif row >= 1 then
				local rbase = (row - 1) * TexW

				Opts.y1, Opts.y2 = row, row

				for coff = 1, Stencil.w do
					local col = c0 + coff

					if col >= 1 and col <= TexW then
						if Stencil[index] == 1 then
							Opts.x1, Opts.x2 = col, col

							texture:SetBytes(color, Opts)

							mask_bytes[rbase + col] = mask
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

local BounceParams, RotateParams = { tag = "mesh" }, { tag = "mesh" }

local function DoBounce (object)
	BounceParams.x = .25 * CX + random(CX)
	BounceParams.y = .25 * CY + random(CY)
	BounceParams.time = random(1000, 3500)

	transition.to(object, BounceParams)
end

local function DoRotate (object)
	RotateParams.rotation = random(90, 540)
	RotateParams.time = random(1000, 3500)

	transition.to(object, RotateParams)
end

BounceParams.onComplete = DoBounce
RotateParams.onComplete = DoRotate

local function RandomScale ()
	return .725 + random() * .275
end

-- Create --
function Scene:create (event)
	local canvas = display.newRect(self.view, CX, CY, TexW, TexH)

	canvas:addEventListener("touch", CanvasTouch)

	self.m_canvas = canvas

	local frame = display.newRect(self.view, canvas.x, canvas.y, canvas.contentWidth, canvas.contentHeight)

	frame:setFillColor(0, 0)

	frame.alpha, frame.strokeWidth = .7, 6

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

	frame:toFront()

	local go = Button(self.view, "Go!", 410, 100, function()
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

					for k = 1, #points, color_mesh:GetDim() do
						uvs[#uvs + 1] = utils.EncodeTenBitsPair(RandomScale() * color.r, RandomScale() * color.g)
						uvs[#uvs + 1] = utils.EncodeTenBitsPair(RandomScale() * color.b, RandomScale())

						local x, y = points[k], points[k + 1]

						verts[#verts + 1] = size * (x - .5)
						verts[#verts + 1] = size * (.5 - y) + Y0 - 5 -- TODO: why 5???
					end

					local mesh = display.newMesh(CX, CY, {
						indices = color_mesh:GetTriangles(), uvs = uvs, vertices = verts, mode = "indexed", zeroBasedIndices = true
					})

					utils.SetVertexColorShader(mesh)

					mesh:translate(mesh.path:getVertexOffset())

					DoBounce(mesh)
					DoRotate(mesh)

					break
				end
			end
		end
	end, 0, 0, 1)
	local about = display.newText(self.view, "Drag inside the rect to paint using the frame color", CX, 65, native.systemFontBold, 15)

	-- Go! button / Reset (depending on what's going on)
end

Scene:addEventListener("create")

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		local mask_bytes, texture = {}, bytemap.newTexture{ width = TexW, height = TexH, format = "rgb" }

		for i = 1, TexW * TexH do
			mask_bytes[i] = Opaque
		end

		texture:SetBytes(ColorValues[1].bytes:rep(#mask_bytes))

		self.m_canvas.fill = { type = "image", filename = texture.filename, baseDir = texture.baseDir }

		self.m_canvas.m_mask_bytes, self.m_canvas.m_texture = mask_bytes, texture
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		self.m_canvas.m_texture:releaseSelf()

		if self.m_mask then
			self.m_mask:releaseSelf()
		end

		self.m_canvas.m_texture, self.m_mask = nil
	end
end

Scene:addEventListener("hide")

return Scene
