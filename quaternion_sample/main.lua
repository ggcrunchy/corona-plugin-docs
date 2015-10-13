--- Sample code for quaternion plugin.

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

-- Corona globals --
local display = display

-- Corona modules --
local composer = require("composer")
local widget = require("widget")

-- Give our widgets some theming.
widget.setTheme("widget_theme_android_holo_dark")

-- Switch to a given scene
local function ChooseScene (name)
	return function()
		composer.gotoScene(name)
	end
end

-- Add tabs to switch among views
local tab_bar = widget.newTabBar{
	buttons = {
		{ label = "Map", onPress = ChooseScene("scenes.map"), selected = true },
		{ label = "Spheres", onPress = ChooseScene("scenes.spheres") },
		{ label = "Objects", onPress = ChooseScene("scenes.objects") },
		{ label = "Functions", onPress = ChooseScene("scenes.funcs") }
	}, width = display.contentWidth
}

tab_bar.x = display.contentCenterX
tab_bar.y = display.contentHeight - tab_bar.height / 2

composer.gotoScene("scenes.map")