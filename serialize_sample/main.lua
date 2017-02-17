--- Sample for serialize plugin.

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
if system.getInfo("platform") ~= "tvos" then
	widget.setTheme("widget_theme_android_holo_dark")
else
	widget.setTheme("widget_theme_ios7")
end

-- Switch to a given scene
local function ChooseScene (name)
	return function()
		composer.gotoScene(name)
	end
end

-- Add tabs to switch among views
local tab_bar = widget.newTabBar{
	buttons = {
		{ label = "Quirky", onPress = ChooseScene("scenes.quirky"), selected = true },
		{ label = "CBOR", onPress = ChooseScene("scenes.cbor") },
		{ label = "Functions", onPress = ChooseScene("scenes.funcs") }
	},
	width = display.viewableContentWidth
}

tab_bar.x = display.contentCenterX
tab_bar.y = (display.contentHeight + display.viewableContentHeight) / 2 - 20

composer.gotoScene("scenes.quirky")
