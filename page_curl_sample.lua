--- Curl effect demo.
--
-- This uses the build settings and config files also found in the directory.

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
local cos = math.cos
local floor = math.floor
local ipairs = ipairs
local random = math.random
local pairs = pairs
local pi = math.pi
local sin = math.sin

-- Modules --
local page_curl = require("plugin.page_curl")

-- Corona globals --
local display = display
local easing = easing
local native = native
local Runtime = Runtime
local transition = transition

-- Corona modules --
local widget = require("widget")

-- Give our widgets some theming.
widget.setTheme("widget_theme_android_holo_dark")

-- Shorthand for display dimensions --
local W, H = display.contentWidth, display.contentHeight

-- Set a background for some contrast
local Background = display.newRect(display.contentCenterX, display.contentCenterY, W, H)

Background:setFillColor(.2)

-- Views state --
local Groups, Current, EnterFrame = display.newGroup(), 1, {}

-- Group showing help text --
local TextGroup = display.newGroup()

-- Helper to set up and switch view groups
local function ChooseGroup (index)
	local choice = display.newGroup()

	choice.isVisible = index == 1

	Groups:insert(choice)

	return function()
		local old_update = EnterFrame[Current]

		if old_update then
			Runtime:removeEventListener("enterFrame", old_update)
		end

		Groups[Current].isVisible = false
		Groups[index].isVisible, Current = true, index

		TextGroup.isVisible = Groups[index].m_has_touch

		local new_update = EnterFrame[index]

		if new_update then
			Runtime:addEventListener("enterFrame", new_update)
		end
	end
end

-- Add tabs to switch among views
local tab_bar = widget.newTabBar{
	buttons = {
		{ label = "Options", onPress = ChooseGroup(1), selected = true },
		{ label = "Page flip", onPress = ChooseGroup(2) },
		{ label = "Capture", onPress = ChooseGroup(3) },
		{ label = "Snapshot", onPress = ChooseGroup(4) },
		{ label = "In-motion", onPress = ChooseGroup(5) },
		{ label = "Random", onPress = ChooseGroup(6) }
	}, width = display.contentWidth
}

tab_bar.x = display.contentCenterX
tab_bar.y = display.contentHeight - tab_bar.height / 2

-- Helper to display a view's grabbable regions
local function DisplayRegions (curl)
	local regions = curl:GetGrabRegions()

	for _, region in pairs(regions) do
		local rect = display.newRoundedRect(curl.parent, region.x, region.y, region.width, region.height, 12)

		rect:setFillColor(.3, .3)
		rect:setStrokeColor(.4, random(), .2)

		rect.strokeWidth = 3
	end

	curl.parent.m_has_touch = true
end

-- Widget factory
local function NewWidget (index, w, h)
	w, h = w or floor(.7 * W), h or floor(.7 * H)

	local curl = page_curl.NewPageCurlWidget{ left = 20, top = 25, width = w, height = h }

	Groups[index]:insert(curl)

	return curl, w, h
end

-- Helper to add left-aligned text
local function Text (group, x, y, str)
	local text = display.newText(group, str, 0, 0, native.systemFont, 17)

	text.anchorX, text.x = 0, x
	text.anchorY, text.y = 0, y

	return text
end

-- Helper to add tab bars with text
local function TabsAndText (group, x, y, str, buttons)
	local text = Text(group, x, y, str)
	local bounds = text.contentBounds
	local tabs = widget.newTabBar{ buttons = buttons, left = bounds.xMin, top = bounds.yMax + 5, width = W - (bounds.xMin + 10), height = 27 }

	group:insert(tabs)

	buttons[1].onPress()

	return tabs.contentBounds.yMax + 5
end

-- Current color --
local R, G, B = 1, 1, 1

-- Helper to add sliders with text
local function TextAndSlider (curl, x, y, str, func)
	local text = Text(curl.parent, x, y, str)
	local slider = widget.newSlider{
		left = x + text.contentWidth + 5, top = y, width = 120, height = 20, value = 100,

		listener = function(event)
			func(event.value / 100)

			curl:SetColor(R, G, B)
		end
	}

	curl.parent:insert(slider)

	return slider.contentBounds.xMax + 5, slider
end

-- Options view --
do
	local curl, w, h = NewWidget(1)

	-- Color sliders --
	do
		local x, y = curl.x, curl.y + h + 10

		x = TextAndSlider(curl, x, y, "R:", function(r)
			R = r
		end)
		x = TextAndSlider(curl, x, y, "G:", function(g)
			G = g
		end)
		local _, slider = TextAndSlider(curl, x, y, "B:", function(b)
			B = b
		end)

		-- Add some instructions below the sliders, in all views.
		Text(TextGroup, curl.x, slider.contentBounds.yMax + 5, "Grab the rounded rect(s) to drag the page around.")
	end

	-- Sidebar --
	do
		local x, y = curl.x + w + 35, curl.y

		y = TabsAndText(curl.parent, x, y, "Number of images?", {
			{
				label = "One", onPress = function()
					curl:SetImage("Image1.jpg")
				end, selected = true
			}, {
				label = "Two", onPress = function()
					curl:SetFrontAndBackImages("Image1.jpg", "monalisa.jpg")
				end
			}, {
				label = "None", onPress = function()
					curl:SetBlankRect()
				end
			}
		})
		y = TabsAndText(curl.parent, x, y, "Back texture method?", {
			{
				label = "Same", onPress = function()
					curl:SetBackTextureMethod("same")
				end, selected = true
			}, {
				label = "None", onPress = function()
					curl:SetBackTextureMethod("none")
				end
			}
		})
		y = TabsAndText(curl.parent, x, y, "Which color method?", {
			{
				label = "Both", onPress = function()
					curl:SetColorMethod("both")
				end, selected = true
			}, {
				label = "Front Only", onPress = function()
					curl:SetColorMethod("front_only")
				end
			}, {
				label = "Back Only", onPress = function()
					curl:SetColorMethod("back_only")
				end
			}
		})
		y = TabsAndText(curl.parent, x, y, "Which edge effect?", {
			{
				label = "Edge", onPress = function()
					curl:SetEdgeEffect("edge")
				end, selected = true
			}, {
				label = "None", onPress = function()
					curl:SetEdgeEffect("none")
				end
			}, {
				label = "Shadow", onPress = function()
					curl:SetEdgeEffect("shadow")
				end
			}
		})
		y = TabsAndText(curl.parent, x, y, "Enable expansion?", {
			{
				label = "Yes", onPress = function()
					curl:EnableExpansion(true)
				end, selected = true
			}, {
				label = "No", onPress = function()
					curl:EnableExpansion(false)
				end
			}
		})
		TabsAndText(curl.parent, x, y, "Enable inner shadows?", {
			{
				label = "Yes", onPress = function()
					curl:EnableInnerShadows(true)
				end, selected = true
			}, {
				label = "No", onPress = function()
					curl:EnableInnerShadows(false)
				end
			}
		})
	end

	DisplayRegions(curl)
end

-- Page flip view --
do
	local other, w = NewWidget(2)
	local front = NewWidget(2)

	local function Moved (event)
		local curl, passed_threshold = event.target

		if event.dir == "right" then
			passed_threshold = curl.edge_x < .4
		else
			passed_threshold = curl.edge_x > .6
		end

		if passed_threshold then
			front:DisableTouch(true)

			transition.to(front, {
				alpha = .75, edge_x = event.dir == "right" and 0 or 1, transition = easing.outQuad,

				onComplete = function()
					front:toBack()

					front.alpha = 1

					front.angle, front.edge_x, front.edge_y = 0, 1, 1

					front, other = other, front

					front:SetTouchSides("left_and_right")
				end
			})
		end
	end

	other:addEventListener("page_dragged", Moved)
	front:addEventListener("page_dragged", Moved)

	other:SetImage("monalisa.jpg")
	front:SetImage("Image1.jpg")
	front:SetTouchSides("left_and_right")

	DisplayRegions(front)

	Text(Groups[2], other.x + w + 30, other.y, [[
		Once it has been
		dragged far enough,
		the page will flip.

		To effect this, touch
		is temporarily disabled,
		without resetting the
		page. A transition then
		curls the page the rest
		of the way.

		Two widgets work
		together: one acts as
		the current page while
		another shows what's
		coming up. After a
		flip, they swap roles.
	]])
end

-- Capture view --
do
	local curl, temp_group = NewWidget(3), display.newGroup()

	for _ = 1, 1000 do
		local x, y = (.2 + .6 * random()) * W, (.2 + .6 * random()) * H
		local c = display.newCircle(temp_group, x, y, random(4, 17))

		c:setFillColor(.1 + random() * .8, .1 + random() * .8, .1 + random() * .8)
	end

	local gbounds = temp_group.contentBounds
	local gw, gh = temp_group.width, temp_group.height
	local rect = display.newRect(temp_group, (gbounds.xMin + gbounds.xMax) / 2, (gbounds.yMin + gbounds.yMax) / 2, gw, gh)

	rect:toBack()
	rect:setFillColor(0, .2, .7)

	curl:Capture(temp_group.contentBounds)

	temp_group:removeSelf()

	DisplayRegions(curl)

	local w = curl:GetSize()

	Text(Groups[3], curl.x + w + 30, curl.y, [[
		A background and several
		circles are loaded into a
		(temporary) group and
		captured.

		The capture now behaves
		like any other page.
	]])
end

-- Position generally below some curl widgets --
local X, Y

-- Snapshot view --
do
	local curl, w, h = NewWidget(4)
	local snapshot = curl:PrepareSnapshot()
	local group, cw, ch = snapshot.group, curl.width, curl.height
	local rect = display.newRect(group, 0, 0, cw, ch)

	rect:setFillColor(0, 0, 1)

	X, Y = curl.x, curl.y + h

	display.newImage(group, "monalisa.jpg")

	for _ = 1, 1000 do
		local x, y = (2 * random() - 1) * cw, (2 * random() - 1) * ch
		local c = display.newCircle(group, x, y, random(4, 17))

		c.x0, c.y0, c.dx, c.dy = x, y, random(-500, 500), random(-500, 500)

		c:setFillColor(.1 + random() * .8, .1 + random() * .8, .1 + random() * .8)
	end

	EnterFrame[4] = function(event)
		local a1, a2, a3 = .5 + sin(event.time / 800) * .3, .5 + sin(event.time / 1200) * .4, .5 + sin(event.time / 600) * .7

		for i = 3, group.numChildren do
			local child = group[i]

			child.alpha = a1
			child.x = child.x0 + a2 * child.dx
			child.y = child.y0 + a3 * child.dy
		end

		snapshot:invalidate()
	end

	DisplayRegions(curl)

	Text(Groups[4], curl.x + w + 30, curl.y, [[
		With snapshots, the
		page can depict a
		dynamic scene.
	]])
end

-- In-motion view --
do
	for i, params in ipairs{
		{ x = 50, y = 100, width = 170, height = 120, dx = 200, dy = 50, edge_x2 = .2 },
		{ x = W - 200, y = H - 300, width = 170, height = 120, dx = 90, angle = pi / 2, edge_x1 = .5, edge_y2 = .3 },
		{ x = W / 2, y = 2 * H / 3, width = 90, height = 70, dx = 200, dy = 350, angle = pi, edge_x1 = 0, edge_x2 = .9 },
		{ x = W - 20, y = H / 2, width = 270, height = 120, dx = 400, angle = pi * .31, edge_x1 = .6, edge_x2 = .1, edge_y1 = .7, edge_y2 = .5 }
	} do
		local curl = NewWidget(5, params.width, params.height)

		curl.x, curl.y = params.x, params.y

		curl.m_x, curl.m_y = curl.x, curl.y
		curl.m_dx, curl.m_dy = params.dx or 0, params.dy or 0
		curl.m_edge_x1, curl.m_edge_y1 = params.edge_x1 or 1, params.edge_y1 or 1
		curl.m_edge_x2 = params.edge_x2 or curl.m_edge_x1
		curl.m_edge_y2 = params.edge_y2 or curl.m_edge_y1

		curl.angle_radians, curl.edge_x, curl.edge_y = params.angle or 0, params.edge_x1 or 1, params.edge_y1 or 0

		if i == 1 or i == 3 then
			curl:SetImage("Image1.jpg")
		elseif i == 2 then
			curl:SetImage("monalisa.jpg")
		else
			curl:SetEdgeEffect("shadow")
			curl:SetFrontAndBackImages("Image1.jpg", "monalisa.jpg")
		end
	end

	EnterFrame[5] = function(event)
		local group, dx, dy, u, v = Groups[5], sin(event.time / 1400), sin(event.time / 1700), 1 - sin(event.time / 1100)^2, 1 - sin(event.time / 800)^2

		for i = 1, group.numChildren do
			local curl = group[i]

			if not curl.text then -- text description, not a curl widget
				curl.x, curl.y = curl.m_x + curl.m_dx * dx, curl.m_y + curl.m_dy * dy
				curl.edge_x = (1 - u) * curl.m_edge_x1 + u * curl.m_edge_x2
				curl.edge_y = (1 - v) * curl.m_edge_y1 + v * curl.m_edge_y2
			end
		end
	end

	Text(Groups[5], X, Y + 30, [[
		Page curl widgets are display objects (and can be moved around), with
		properties that can be updated dynamically.
	]])
end

-- Random view --
do
	local curl, w, h = NewWidget(6)

	curl:SetImage("monalisa.jpg")

	local temp, count, x1, y1 = NewWidget(6, 70, 70), 0, curl.x + w + 25, curl.y
	local temp_group = display.newGroup()

	Groups[6]:insert(temp_group)

	temp:SetImage("Image1.jpg")

	temp.x, temp.y = x1, y1

	EnterFrame[6] = function(event)
		curl.edge_x = .875 + sin(event.time / 600) * .1
		curl.edge_y = sin(event.time / 400) * .1
		curl.angle = event.time / 480

		-- Detach some small curled images every few frames.
		if temp then
			local rest = count % 30
			local time = (count - rest) / 30
			local dc = time % 2
			local dr = (time - dc) / 2

			-- Every 30 frames, prepare some new interpolation values. 
			if rest == 0 then
				temp.m_x1, temp.m_y1 = temp.x, temp.y
				temp.m_x2 = x1 + dc * 80
				temp.m_y2 = y1 + dr * 80

				local angle = random() * (2 * pi)
				local ca, sa = cos(angle), sin(angle)

				temp.m_angle1, temp.m_angle2 = temp.angle_radians, angle
				temp.m_edge_x1, temp.m_edge_x2 = ca * .5 + .5, .5 - ca * (random() + 1) * .2
				temp.m_edge_y1, temp.m_edge_y2 = sa * .5 + .5, .5 - sa * (random() + 1) * .2
			end

			-- Interpolate the small widget across frames.
			local t = rest / 29
			local s = 1 - t

			temp.x = s * temp.m_x1 + t * temp.m_x2
			temp.y = s * temp.m_y1 + t * temp.m_y2

			temp.angle_radians = s * temp.m_angle1 + t * temp.m_angle2
			temp.edge_x = s * temp.m_edge_x1 + t * temp.m_edge_x2
			temp.edge_y = s * temp.m_edge_y1 + t * temp.m_edge_y2

			-- On the last frame, detach the current image and switch to a new one. Quit
			-- after five rows.
			if rest == 29 then
				temp:Detach(temp_group)
				temp:SetImage(dc == 0 and "monalisa.jpg" or "Image1.jpg")

				if dc == 1 and dr == 4 then
					temp:removeSelf()

					temp = nil
				end
			end
		end

		-- Switch the color every few frames.
		count = count + 1

		if count % 10 == 0 then
			curl:SetColor(.8 + random() * .2, .2 + random() * .8, 1)
		end
	end

	Text(Groups[6], curl.x, curl.y + h + 30, [[
		Another show of regularly updating a widget's properties, including its color.
		On the side, several "freeze frame"s of a smaller page are left along a path.
	]])
end