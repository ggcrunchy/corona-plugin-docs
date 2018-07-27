--- Scene that demonstrates path offsetting.

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

-- Modules --
local utils = require("utils")

-- Plugins --
local clipper = require("plugin.clipper")

-- Corona globals --
local timer = timer

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

-- Create --
function Scene:create ()
	local subj =	{ 348, 257 } .. { 364, 148 } .. { 362, 148 } ..
					{ 326, 241 } .. { 295, 219 } .. { 258,  88 } ..
					{ 440, 129 } .. { 370, 196 } .. { 372, 275 } .. clipper.ToPath
	local original = clipper.NewPathArray()

	original:AddPath(subj)

	self.subject = subj
	self.offset = clipper.NewOffset()

	self.ogroup = display.newGroup()

	self.view:insert(self.ogroup)

	utils.DrawPolygons(self.view, original, { a = .8, stroke = { .4 } })

	self.solution = clipper.NewPathArray()
end

Scene:addEventListener("create")

local SolutionOpts = { r = 0, b = 0, stroke = { 0, 0x99 / 0xFF, 0 } }

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		self.update = timer.performWithDelay(75, function(event)
			utils.ClearGroup(self.ogroup)

			self.offset:AddPath(self.subject, "Round", "ClosedPolygon")

			local pulse = event.count % 18

			self.offset:Execute(self.solution, -9 + pulse)
			self.offset:Clear()

			utils.DrawPolygons(self.ogroup, self.solution, SolutionOpts)
		end, 0)
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		timer.cancel(self.update)
		utils.ClearGroup(self.ogroup)
	end
end

Scene:addEventListener("hide")

return Scene
