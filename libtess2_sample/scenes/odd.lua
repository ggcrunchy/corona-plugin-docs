--- Scene that demonstrates the odd winding rule.

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
local shapes = require("shapes")
local utils = require("utils")

-- Corona globals --
local transition = transition

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

-- Create --
function Scene:create ()
	
end

Scene:addEventListener("create")

local FadeInParams = { alpha = 1 }

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		local back = display.newGroup()
		local group = display.newGroup()

		self.view:insert(back)
		self.view:insert(group)

		self.m_back = back
		self.m_group = group

		back.alpha = 0

		function group.on_done (tess)
			--
		end

		function group.on_all_done ()
			transition.to(back, FadeInParams)
		end

		utils.DrawAll(group, shapes.BoxCCW, shapes.BoxMixed, shapes.Overlap, shapes.SelfIntersectingSpiral)
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		self.m_back:removeSelf()
		self.m_group:removeSelf()

		utils.CancelTimers()
	end
end

Scene:addEventListener("hide")

return Scene