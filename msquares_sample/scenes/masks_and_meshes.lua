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
local timer = timer
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

local function ShowButton (button, show)
	button.parent.isVisible = not not show
end

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
						if Stencil[index] == 1 and mask ~= mask_bytes[rbase + col] then
							Opts.x1, Opts.x2 = col, col

							texture:SetBytes(color, Opts)

							mask_bytes[rbase + col] = mask

							Scene.nmasked = Scene.nmasked + (mask == Transparent and 1 or -1)

							if mask == Transparent and Scene.nmasked == 1 then
								ShowButton(Scene.go, true)
							elseif mask == Opaque and Scene.nmasked == 0 then
								ShowButton(Scene.go, false)
							end
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
	local bgroup = display.newGroup()
	local button = display.newRoundedRect(bgroup, x, y, 100, 25, 12)
	local fr, fg, fb = r / 0xFF, g / 0xFF, b / 0xFF

	button:addEventListener("touch", function(event)
		if event.phase == "began" then
			action()
		end

		return true
	end)
	button:setFillColor(r, g, b)

	local str = display.newText(bgroup, text, 0, button.y, native.systemFontBold, 15)

	str.anchorX, str.x = 0, x - 35

	view:insert(bgroup)

	return button
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

local ButtonX, ButtonY = 410, 100

local DefFrameGray, DefFrameWidth = .9, 2

local UnselectedScale = .8
	
local function Unselect (object)
	local color = object.m_color

	object:setStrokeColor(color.r * UnselectedScale, color.g * UnselectedScale, color.b * UnselectedScale)
end

local FadeParams = {}

local function Reset (mask_bytes, texture)
	for i = 1, TexW * TexH do
		mask_bytes[i] = Opaque
	end

	ShowButton(Scene.go, true)
	ShowButton(Scene.reset, false)

	Scene.nmasked = 0

	texture:SetBytes(ColorValues[1].bytes:rep(#mask_bytes))

	if Scene.m_mesh_group then
		for i = 1, Scene.m_mesh_group.numChildren do
			transition.cancel(Scene.m_mesh_group[i])
		end

		Scene.m_mesh_group:removeSelf()
		
		Scene.m_mesh_group = nil
	end
end

-- Create --
function Scene:create (event)
	local canvas = display.newRect(self.view, CX, CY, TexW, TexH)

	canvas:addEventListener("touch", CanvasTouch)

	self.m_canvas = canvas

	local frame = display.newRect(self.view, canvas.x, canvas.y, canvas.contentWidth, canvas.contentHeight)

	frame:setFillColor(0, 0)

	frame.alpha = .7

	local what, y = "Empty", 95

	local current

	self.update_current_color = timer.performWithDelay(150, function()
		if current then
			current:setStrokeColor(random(), random(), random())
		end
	end, 0)

	timer.pause(self.update_current_color)
	
	local function RectTouch (event)
		local phase, rect = event.phase, event.target
		local color, index = rect.m_color, rect.m_index

		if phase == "began" then
			canvas.m_color = color.bytes

			if index > 1 then
				frame:setStrokeColor(color.r, color.g, color.b)

				frame.strokeWidth = 6
			else
				frame:setStrokeColor(DefFrameGray)

				frame.strokeWidth = DefFrameWidth
			end

			if current and current ~= rect then
				Unselect(current)
			end

			current = rect
		end

		return true
	end

	self.color_group = display.newGroup()
	
	self.view:insert(self.color_group)
	
	for i, color in ipairs(ColorValues) do		
		local rect = display.newRect(self.color_group, 65, y, 50, 25)

		rect.m_index, rect.m_color = i, color

		rect:addEventListener("touch", RectTouch)
		rect:setFillColor(color.r, color.g, color.b)

		rect.strokeWidth = 2

		if i == 1 then
			rect:dispatchEvent{ phase = "began", name = "touch", target = rect }
		else
			Unselect(rect)
		end

		what, y = ("Object #%i"):format(i), y + 32
	end

	frame:toFront()

	self.go = Button(self.view, "Go!", ButtonX, ButtonY, function()
		FadeParams.alpha = 0

		transition.to(self.color_group, FadeParams)

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

		self.m_mesh_group = display.newGroup()

		self.view:insert(self.m_mesh_group)

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

					local mesh = display.newMesh(self.m_mesh_group, CX, CY, {
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

		ShowButton(self.go, false)
		ShowButton(self.reset, true)
	end, 0, 0, 1)

	self.reset = Button(self.view, "Reset", ButtonX, ButtonY, function()
		local canvas = self.m_canvas

		Reset(canvas.m_mask_bytes, canvas.m_texture)

		canvas.m_texture:invalidate()
		canvas:setMask(nil)

		FadeParams.alpha = 1

		transition.to(self.color_group, FadeParams)
	end, 0, 0, 1)
	
	local about = display.newText(self.view, "Drag inside the rect to paint using the frame color", CX, 65, native.systemFontBold, 15)

	-- Go! button / Reset (depending on what's going on)
end

Scene:addEventListener("create")

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		local mask_bytes, texture = {}, bytemap.newTexture{ width = TexW, height = TexH, format = "rgb" }

		Reset(mask_bytes, texture)

		self.m_canvas.fill = { type = "image", filename = texture.filename, baseDir = texture.baseDir }

		self.m_canvas.m_mask_bytes, self.m_canvas.m_texture = mask_bytes, texture

		timer.resume(self.update_current_color)

		self.color_group.alpha = 1
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

		-- go / reset

		self.m_canvas.m_texture, self.m_mask = nil

		timer.pause(self.update_current_color)
	end
end

Scene:addEventListener("hide")

return Scene
