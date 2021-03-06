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

local Colors = {
	0x70, 0x70, 0x70,
	0xFF, 0x00, 0x00,
	0x00, 0xFF, 0x00,
	0x00, 0x00, 0xFF,
	0xFF, 0xFF, 0x00
}

local ColorValues = {}

for i = 1, #Colors, 3 do
	ColorValues[#ColorValues + 1] = utils.ColorValueFromOctets(Colors[i], Colors[i + 1], Colors[i + 2])
end

local UnmaskedColor = ColorValues[1].bytes

local Unmask, Mask = char(0xFF), char(0)

local CellW, CellH = 100, 80
local CellSize = 2
local TexW, TexH = CellW * CellSize, CellH * CellSize

local CanvasTouch

do
    local Opts = {}

    local Color, MaskOp, MaskBytes, Texture

    CanvasTouch = utils.CanvasTouchFunc(TexW, TexH,

    {
        w = 7,

        0, 0, 1, 1, 1, 0, 0,
        0, 1, 1, 1, 1, 1, 0,
        1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1,
        0, 1, 1, 1, 1, 1, 0,
        0, 0, 1, 1, 1, 0, 0
    },

    function(canvas)
        Color, Texture = canvas.m_color, canvas.m_texture
        MaskOp, MaskBytes = Color == UnmaskedColor and Unmask or Mask, canvas.m_mask_bytes
    end, function(index, col)
        if MaskOp ~= MaskBytes[index] then
            Opts.x1, Opts.x2 = col, col

            Texture:SetBytes(Color, Opts)

            MaskBytes[index] = MaskOp

            Scene.m_nmasked = Scene.m_nmasked + (MaskOp == Mask and 1 or -1)

            if MaskOp == Mask and Scene.m_nmasked == 1 then
                utils.ShowButton(Scene.m_go, true)
            elseif MaskOp == Unmask and Scene.m_nmasked == 0 then
                utils.ShowButton(Scene.m_go, false)
            end
        end
    end, function()
        Texture:invalidate()

        Color, MaskBytes, Texture = nil
    end, function(row)
        Opts.y1, Opts.y2 = row, row
    end)
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

local function Reset (canvas, mask_bytes, texture)
	canvas:addEventListener("touch", CanvasTouch)
    canvas:setMask(nil)

	for i = 1, TexW * TexH do
		mask_bytes[i] = Unmask
	end

	utils.ShowButton(Scene.m_go, false)
	utils.ShowButton(Scene.m_reset, false)

	Scene.m_nmasked = 0

	texture:SetBytes(UnmaskedColor:rep(#mask_bytes))

    transition.cancel("mesh")

	display.remove(Scene.m_mesh_group)
		
	Scene.m_mesh_group = nil
end

local function RoundToMultipleOf4 (x)
    x = x + 3

    return x - x % 4
end

-- Create --
function Scene:create (event)
	local canvas = display.newRect(self.view, CX, CY, TexW, TexH)

	self.m_canvas = canvas

	local frame = display.newRect(self.view, canvas.x, canvas.y, canvas.contentWidth, canvas.contentHeight)

	frame:setFillColor(0, 0)

	frame.alpha = .7

    local update_timer, update_selection = utils.SelectionStrokeHighlighter()

    timer.pause(update_timer)

    self.m_update_current_color = update_timer
	
	local function RectTouch (event)
		local phase, rect = event.phase, event.target

		if phase == "began" then
            local color = rect.m_color

            canvas.m_color = color.bytes

			if rect.m_index > 1 then
				frame:setStrokeColor(color.r, color.g, color.b)

				frame.strokeWidth = 6
			else
				frame:setStrokeColor(DefFrameGray)

				frame.strokeWidth = DefFrameWidth
			end

			update_selection(rect, Unselect)
		end

		return true
	end

	self.m_color_group = display.newGroup()
	
	self.view:insert(self.m_color_group)

	for i, color in ipairs(ColorValues) do
		local rect = display.newRect(self.m_color_group, 65, 95 + (i - 1) * 32, 50, 25)

		rect.m_index, rect.m_color = i, color

		rect:addEventListener("touch", RectTouch)
		rect:setFillColor(color.r, color.g, color.b)

		rect.strokeWidth = 2

		if i == 1 then
			rect:dispatchEvent{ phase = "began", name = "touch", target = rect }
		else
			Unselect(rect)
		end
	end

	frame:toFront()

	self.m_go = utils.Button(self.view, "Go!", ButtonX, ButtonY, function()
		FadeParams.alpha = 0

		transition.to(self.m_color_group, FadeParams)

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

		canvas:removeEventListener("touch", CanvasTouch)
		
		utils.ShowButton(self.m_go, false)
		utils.ShowButton(self.m_reset, true)
	end, 0, 0, 1)

	self.m_reset = utils.Button(self.view, "Reset", ButtonX, ButtonY, function()
		local canvas = self.m_canvas

		Reset(canvas, canvas.m_mask_bytes, canvas.m_texture)

		canvas.m_texture:invalidate()

		FadeParams.alpha = 1

		transition.to(self.m_color_group, FadeParams)
	end, 0, 0, 1)
	
	local about = display.newText(self.view, "Drag inside the rect to paint using the frame color", CX, 65, native.systemFontBold, 15)
end

Scene:addEventListener("create")

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		local mask_bytes, texture = {}, bytemap.newTexture{ width = TexW, height = TexH, format = "rgb" }

		Reset(self.m_canvas, mask_bytes, texture)

		self.m_canvas.fill = { type = "image", filename = texture.filename, baseDir = texture.baseDir }

		self.m_canvas.m_mask_bytes, self.m_canvas.m_texture = mask_bytes, texture

		timer.resume(self.m_update_current_color)

		self.m_color_group.alpha = 1
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

		timer.pause(self.m_update_current_color)
	end
end

Scene:addEventListener("hide")

return Scene
