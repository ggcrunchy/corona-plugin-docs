--- Sample for tinyfiledialogs plugin.

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

-- Plugins --
local tfd = require("plugin.tinyfiledialogs")

-- Corona modules --
local widget = require( "widget" )

widget.setTheme("widget_theme_android_holo_dark")

local left, top = 50, 50
local str = display.newText("Choose an option", display.contentCenterX, display.contentHeight - 150, native.systemFont, 20)

for _, button in ipairs{
	{
		label = "Open Single File",
		action = function()
			local file = tfd.openFileDialog{
				title = "Open single file", default_path_and_file = system.pathForFile("Text/"),
				filter_patterns = "*.txt", -- may also be an array, cf. next button
				filter_description = "Text" -- name that can substitute for patterns
			}

			str.text = file and ('"Opened" file: ' .. file) or "Cancelled"
		end
	}, {
		label = "Open Multiple Files",
		action = function()
			local files = tfd.openFileDialog{
				title = "Open many files", default_path_and_file = system.pathForFile("Images/"),
				filter_patterns = { "*.png", "*.jpg" }, -- may also be a single string, cf. previous button
				filter_description = "Images", -- name that can substitute for patterns
				allow_multiple_selects = true
			}

			if files then
				str.text = '"Opened" file(s): ' .. table.concat(files, "\n")
			else
				str.text = "Cancelled"
			end
		end
	}, {
		label = "Save File",
		action = function()
			local file = tfd.saveFileDialog{
				title = "Save file", default_path_and_file = system.pathForFile("Images/"),
				filter_patterns = { "*.png", "*.jpg" }, -- may also be a single string
				filter_description = "Images" -- name that can substitute for patterns
			}

			str.text = file and ('"Saved" file: ' .. file) or "Cancelled"
		end
	}, {
		label = "Select Folder",
		action = function()
			local folder = tfd.selectFolderDialog{
				title = "Select folder", default_path = system.pathForFile("Images/") -- n.b. path seems to not work yet on Windows?
			}

			str.text = folder and ("Folder: " .. folder) or "Cancelled"
		end
	}, {
		label = "Choose Color",
		action = function()
			local rgb = { r = .3, g = .7, b = 0 } -- use to set default values on input, reuse as output
			local color = tfd.colorChooser{
				title = "Choose color", out_rgb = rgb, rgb = rgb
			}

			if color then
				str.text = "Color: " .. color

				str:setFillColor(rgb.r, rgb.g, rgb.b)
			else
				str.text = "Cancelled"
			end
		end
	}, {
		label = "Input box",
		action = function()
			local input = tfd.inputBox{
				title = "Enter some text", message = "Huzzah", default_input = "TEXT"
			}

			str.text = input and ("Got input: " .. input) or "Cancelled"
		end
	}, {
		label = "Password box",
		action = function()
			local input = tfd.inputBox{
				title = "Enter some text", message = "Huzzah", default_input = false
			}

			str.text = input and ('"Password" revealed: ' .. input) or "Cancelled"
		end
	}, {
		label = "OK message",
		action = function()
			local ok = tfd.messageBox{
				title = "All good", message = "Hmm!", dialog_type = "ok"
			}

			str.text = "AOK"
		end
	}, {
		label = "OK / Cancel",
		action = function()
			local ok = tfd.messageBox{
				title = "How are things?", message = "Hmm?", dialog_type = "okcancel", icon_type = "question"
			}

			str.text = ok and "All's well" or "Woe betide me!"
		end
	}, {
		label = "Yes / No",
		action = function()
			local yes = tfd.messageBox{
				title = "Very important question", message = "Yes or no", dialog_type = "yesno", icon_type = "question",
				default_okyes = true
			}

			str.text = "The answer is: " .. (yes and "Yes" or "No")
		end
	}
} do
	local action = button.action

	widget.newButton{
		left = left, top = top,
		label = button.label,
		onEvent = function(event)
			if event.phase == "ended" then
				action()
			end
		end
	}

	top = top + 70

	if str.y - top < 100 then
		left, top = left + 200, 50
	end
end
