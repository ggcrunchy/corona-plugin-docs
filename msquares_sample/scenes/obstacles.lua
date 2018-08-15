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
local utils = require("utils")

-- Plugins --
local bytemap = require("plugin.Bytemap")
local msquares = require("plugin.msquares")

-- Corona globals --
local physics = physics

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local CullColor = utils.ColorValueFromOctets(0xFF, 0, 0xFF)

local CellW, CellH = 100, 80
local CellSize = 2
local TexW, TexH = CellW * CellSize, CellH * CellSize

local Opaque, Transparent = char(0xFF), char(0)

local CanvasTouch

do
	local Opts = {}

	local Color, Texture

	CanvasTouch = utils.CanvasTouchFunc(TexW, TexH,

    {
		w = 7,

		1, 1, 0, 0, 0, 1, 1,
		1, 1, 1, 0, 1, 1, 1,
		0, 1, 1, 1, 1, 1, 0,
		0, 0, 1, 1, 1, 0, 0,
		0, 1, 1, 1, 1, 1, 0,
		1, 1, 1, 0, 1, 1, 1,
		1, 1, 0, 0, 0, 1, 1
    },

    function(canvas)
        Color, Texture = canvas.m_color, canvas.m_texture
    end, function(_, col)
		Opts.x1, Opts.x2 = col, col

        Texture:SetBytes(CullColor.bytes, Opts)
    end, function()
        Texture:invalidate()

        Color, Texture = nil
    end, function(row)
        Opts.y1, Opts.y2 = row, row
    end)
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

	local cbounds = canvas.contentBounds
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

	self.m_go = utils.Button(self.view, "Go!", ButtonX, ButtonY, function()
		local mlist = msquares.color(canvas.m_texture:GetBytes(), TexW, TexH, CellSize, CullColor.uint, 3)
		local size = max(TexW, TexH) -- msquares normalizes against maximum
		local chain_params = { connectFirstAndLastChainVertex = true }

		for i = 1, #mlist do
			local mesh = mlist:GetMesh(i)
			local boundary = mesh:GetBoundary()

			for j = 1, #boundary do
				local body, points, verts = display.newCircle(0, 0, 5), boundary[j], {}

				body.alpha = .025

				for k = 1, #points, mesh:GetDim() do
					local x, y = points[k], points[k + 1]

					verts[#verts + 1] = size * x + cbounds.xMin
					verts[#verts + 1] = size * y + cbounds.yMin	
				end

				chain_params.chain = verts
				
				physics.addBody(body, "static", chain_params)
			end
		end

		self.m_ball_group = display.newGroup()

		self.view:insert(self.m_ball_group)

		for row = 1, 9 do
			for col = 1, 10 do
				local ball = display.newCircle(self.m_ball_group, cbounds.xMin + col * (cbounds.xMax - cbounds.xMin) / 11, cbounds.yMin - row * 7, 2)

				ball:setFillColor(random(), random(), random())

				physics.addBody(ball)
			end
		end
		
		utils.ShowButton(self.m_go, false)
		utils.ShowButton(self.m_reset, true)
	end, 0, 0, 1)

	self.m_reset = utils.Button(self.view, "Reset", ButtonX, ButtonY, function()
		utils.ShowButton(self.m_reset, false)
	end, 0, 0, 1)

	utils.ShowButton(self.m_reset, false)
	
	local about = display.newText(self.view, "Drag inside the rect to paint or clear obstacles", CX, 65, native.systemFontBold, 15)

	self.m_r1 = display.newRect(self.view, canvas.x, cbounds.yMax, canvas.contentWidth, 3)
	self.m_r2 = display.newRect(self.view, cbounds.xMin, canvas.y, 3, canvas.contentHeight)
	self.m_r3 = display.newRect(self.view, cbounds.xMax, canvas.y, 3, canvas.contentHeight)

	self.m_r1.alpha = .025
	self.m_r2.alpha = .025
	self.m_r3.alpha = .025
end

Scene:addEventListener("create")

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		physics.start()

		local texture = bytemap.newTexture{ width = TexW, height = TexH, format = "rgb" }

		self.m_canvas.fill = { type = "image", filename = texture.filename, baseDir = texture.baseDir }

		self.m_canvas.m_texture = texture

		physics.addBody(self.m_r1, "static")
		physics.addBody(self.m_r2, "static")
		physics.addBody(self.m_r3, "static")
	end
end

Scene:addEventListener("show")

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