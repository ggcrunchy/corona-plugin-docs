--- Scene that demonstrates basic shape intersection.

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
local pi = math.pi
local sin = math.sin

-- Corona extensions --
local round = math.round

-- Plugins --
local clipper = require("plugin.clipper")

-- Modules --
local utils = require("utils")

-- Corona globals --
local display = display
local native = native
local timer = timer

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

local N = 50

local Delta = 2 * pi / N

local function GetEllipsePoints (x1, y1, x2, y2)
	local path = clipper.NewPath()
	local cx, cy = .5 * (x1 + x2), .5 * (y1 + y2)
	local ax, ay, px, py = x2 - cx, y2 - cy, cx, cy -- set previous to center, which should be "not the same"

	for i = 1, N do
		local angle = i * Delta
		local x, y = round(cx + ax * cos(angle)), round(cy + ay * sin(angle))

		if (x - px)^2 + (y - py)^2 > 5 then -- moved at least a few pixels?
			path:AddPoint(x, y)

			px, py = x, y
		end
	end

	return path
end

local YOffset = -35

-- Create --
function Scene:create ()
    -- set up the subject and clip polygons ...
    local subj = clipper.NewPathArray()

    subj:AddPath(GetEllipsePoints(100, 100, 300, 300))
    subj:AddPath(GetEllipsePoints(125, 130, 275, 180))
    subj:AddPath(GetEllipsePoints(125, 220, 275, 270))

    local clip = clipper.NewPathArray()

    clip:AddPath(GetEllipsePoints(140, 70, 220, 320))

    -- display the subject and clip polygons ...
    utils.DrawPolygons(self.view, subj, { r = 0x33 / 0xFF, a = .5, y = YOffset })
    utils.DrawPolygons(self.view, clip, { b = 0x33 / 0xFF, a = .5, y = YOffset })

    self.subject, self.clip = subj, clip
    self.clipper = clipper.NewClipper()

    self.pgroup = display.newGroup()

    self.view:insert(self.pgroup)

    local rtext = display.newText(self.view, "", 50, 50, native.systemFont, 12)

    self.rule_text, rtext.anchorX, rtext.x = rtext, 0, 0
end

Scene:addEventListener("create")

local Stroke = { 0, 0, 1 }

local SolutionOpts = { r = .5, g = .5, b = .5, a = .25, y = YOffset, stroke = Stroke }

local Rules = { "EvenOdd", "NonZero", "Positive", "Negative" }

local function AuxUpdate (scene, ri)
    utils.ClearGroup(scene.pgroup)

    -- get the intersection of the subject and clip polygons ...
    scene.clipper:AddPaths(scene.subject, "SubjectClosed")
    scene.clipper:AddPaths(scene.clip, "Clip") -- "ClipClosed")

    local rule = Rules[ri]
    local solution = scene.clipper:Execute("Intersection", rule, rule)

    scene.clipper:Clear()

    scene.rule_text.text = ("Subject rule: %s"):format(rule)

    -- finally draw the intersection polygons ...
    utils.DrawPolygons(scene.pgroup, solution, SolutionOpts)
end

-- Show --
function Scene:show (event)
	if event.phase == "did" then
        AuxUpdate(self, 1)

        local ri = 1

        self.update = timer.performWithDelay(2500, function()
            ri = ri + 1

            if ri > #Rules then
                ri = 1
            end

            AuxUpdate(self, ri)
        end, 0)
	end
end

Scene:addEventListener("show")

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		timer.cancel(self.update)
        utils.ClearGroup(self.pgroup)
	end
end

Scene:addEventListener("hide")

return Scene
