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

-- Modules --
local winding_bc = require("winding_bc")

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		winding_bc.Show(self, "NEGATIVE")
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		winding_bc.Hide(self)
	end
end

--[[
int main()
{
Path subj;
Paths solution;
subj <<
IntPoint(348,257) << IntPoint(364,148) << IntPoint(362,148) <<
IntPoint(326,241) << IntPoint(295,219) << IntPoint(258,88) <<
IntPoint(440,129) << IntPoint(370,196) << IntPoint(372,275);
ClipperOffset co;
co.AddPath(subj, jtRound, etClosedPolygon);
co.Execute(solution, -7.0);

//draw solution ...
DrawPolygons(solution, 0x4000FF00, 0xFF009900);
}]]

Scene:addEventListener("hide")

return Scene
