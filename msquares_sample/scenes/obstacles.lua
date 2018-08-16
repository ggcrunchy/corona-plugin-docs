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
local floor = math.floor
local max = math.max
local random = math.random

-- Modules --
local utils = require("utils")

-- Plugins --
local bytemap = require("plugin.Bytemap")
local msquares = require("plugin.msquares")

-- Corona globals --
local physics = physics
local timer = timer

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

        Texture:SetBytes(Color, Opts)
    end, function()
        Texture:invalidate()

        Color, Texture = nil
    end, function(row)
        Opts.y1, Opts.y2 = row, row
    end)
end

local CX, CY = display.contentCenterX, display.contentCenterY

local ButtonX, ButtonY = 410, 100

local DefFrameGray, DefFrameWidth = .9, 2

local UnselectedScale = .8

local function Unselect (object)
    local color = object.m_color

    object:setStrokeColor(color.r * UnselectedScale, color.g * UnselectedScale, color.b * UnselectedScale)
end

local FadeParams = {}

local function Reset (canvas)
	canvas:addEventListener("touch", CanvasTouch)

    utils.ShowButton(Scene.m_go, true)
    utils.ShowButton(Scene.m_reset, false)

    if Scene.m_ball_group then
        timer.performWithDelay(1, function()
            Scene.m_ball_group:removeSelf()

            Scene.m_ball_group = nil

            physics.stop()
        end)
    end
end

local NBallCols, NBallRows = 10, 7

-- Create --
function Scene:create (event)
	local canvas = display.newRect(self.view, CX, CY, TexW, TexH)

	canvas:addEventListener("touch", CanvasTouch)

	self.m_canvas = canvas

	local cbounds = canvas.contentBounds
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

    for i = 1, 2 do
        local rect = display.newRect(self.m_color_group, 105, 95 + (i - 1) * 32, 50, 25)
        local color = i == 1 and { r = 1, g = 1, b = 1, bytes = char(0):rep(4) } or CullColor
        local text = display.newText(self.m_color_group, i == 1 and "Clear" or "Paint", 0, rect.y, native.systemFont, 15)

        text.anchorX, text.x = 1, rect.contentBounds.xMin - 5

        rect.m_index, rect.m_color = i, color

        rect:addEventListener("touch", RectTouch)

        rect.strokeWidth = 2

        if i == 1 then
            rect:dispatchEvent{ phase = "began", name = "touch", target = rect }
            rect:setFillColor(0)
        else
            rect:setFillColor(color.r, color.g, color.b)

            Unselect(rect)
        end
    end

	frame:toFront()

	self.m_go = utils.Button(self.view, "Go!", ButtonX, ButtonY, function()
		local mlist = msquares.color(canvas.m_texture:GetBytes(), TexW, TexH, CellSize, CullColor.uint, 3)
		local size = max(TexW, TexH) -- msquares normalizes against maximum

        physics.start()

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

        local dw = (cbounds.xMax - cbounds.xMin) / (NBallCols + 1)

        for row = 1, NBallRows do
			for col = 1, NBallCols do
				local ball = display.newCircle(self.m_ball_group, cbounds.xMin + col * dw, cbounds.yMin - row * 7, 2)

				ball:setFillColor(random(), random(), random())

				physics.addBody(ball)
			end
		end

		physics.addBody(self.m_r1, "static")
		physics.addBody(self.m_r2, "static")
		physics.addBody(self.m_r3, "static")

		canvas:removeEventListener("touch", CanvasTouch)

		utils.ShowButton(self.m_go, false)
		utils.ShowButton(self.m_reset, true)
	end, 0, 0, 1)

	self.m_reset = utils.Button(self.view, "Reset", ButtonX, ButtonY, function()
		Reset(canvas)

        canvas.m_texture:SetBytes(char(0):rep(TexW * TexH * 4))
        canvas.m_texture:invalidate()

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
		local texture = bytemap.newTexture{ width = TexW, height = TexH, format = "rgb" }

		self.m_canvas.fill = { type = "image", filename = texture.filename, baseDir = texture.baseDir }

		self.m_canvas.m_texture = texture

        timer.resume(self.m_update_current_color)

        self.m_color_group.alpha = 1
    end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		Reset(self.m_canvas)

		self.m_canvas.m_texture:releaseSelf()

		self.m_canvas.m_texture = nil

        timer.pause(self.m_update_current_color)
	end
end

Scene:addEventListener("hide")

return Scene
