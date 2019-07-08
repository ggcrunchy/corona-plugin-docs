--- Scene that demonstrates additional information gleaned via polytree solutions.

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
local unpack = unpack

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

local CX, CY = display.contentCenterX, display.contentCenterY

local CW, CH = display.contentWidth, display.contentHeight

local function Line (group, arr, points)
    local path = clipper.NewPath()

    for i = 1, #points, 2 do
        path:AddPoint(points[i], points[i + 1])
    end

    arr:AddPath(path)

    local line = display.newLine(group, unpack(points))

    line.strokeWidth = 3

    return line
end

local function Loop (group, arr, points)
	local line = Line(group, arr, points)

	line:append(points[1], points[2])
end

-- Create --
function Scene:create ()
	local lgroup = display.newGroup()

	self.view:insert(lgroup)

	lgroup.alpha = .35

    -- set up the subject and clip polygons ...
    local subj = clipper.NewPathArray()

    -- "arrowhead"
    Line(lgroup, subj, { CW - 84, CY, 89, CY, CW - 156, CH - 83 })

    -- "curve"
    Line(lgroup, subj, {
        44, CH - 105, 
        76, 213, 107, 207, 133, 197,
        155, 192, 171, 187,
        201, 167, 206, 159,
        213, 147, 224, 135, 234, 128, 242, 123,
        253, 117, 261, 115,
        283, 110, 313, 106, 341, 105
    })

    -- "box"
	local subj_closed = clipper.NewPathArray()

    Loop(lgroup, subj_closed, { 129, CY - 33, CW - 156, CY - 37, CW - 156, CH - 100, 133, CH - 105 })

    -- "poly"
    local clip_closed = clipper.NewPathArray()

    Loop(lgroup, clip_closed, { 49, CY - 40, CX - 9, CY - 67, CW - 107, CY + 33, 160, CH - 78, CX, CY + 40 })

    self.subject, self.clip_closed, self.subject_closed = subj, clip_closed, subj_closed
    self.clipper = clipper.NewClipper()

    self.pgroup = display.newGroup()

    self.view:insert(self.pgroup)

    local ctext = display.newText(self.view, "", 50, 50, native.systemFont, 12)

    self.clip_text, ctext.anchorX, ctext.x = ctext, 0, 0
end

Scene:addEventListener("create")

local Clip = { "Union", "Intersection", "Difference", "Xor" }

local Tree = { out = clipper.NewPolyTree() }

local Closed = { out = clipper.NewPathArray() }
local Open = { out = clipper.NewPathArray() }

local Path = { out = clipper.NewPath() }

local Contour = {}

local function AuxUpdate (scene, ci)
    utils.ClearGroup(scene.pgroup)

    -- get the results of clipping subject and clip polygons ...
    scene.clipper:AddPaths(scene.subject, "Subject")
	scene.clipper:AddPaths(scene.subject_closed, "SubjectClosed")

    local clip = Clip[ci]

    scene.clipper:AddPaths(scene.clip_closed, "ClipClosed")

    local solution = scene.clipper:Execute(clip, Tree)
    local open = clipper.OpenPathsFromPolyTree(solution, Open)
    local closed = clipper.ClosedPathsFromPolyTree(solution, Closed)

    scene.clipper:Clear()

    scene.clip_text.text = ("Clip type: %s"):format(clip)

    -- finally draw the clipped results ...
	for i = 1, #open do
		local path = open:GetPath(i, Path)
		local x1, y1 = path:GetPoint(1)
		local x2, y2 = path:GetPoint(2)

		local line = display.newLine(scene.pgroup, x1, y1, x2, y2)

		for j = 3, #path do
			line:append(path:GetPoint(j))
		end

		line:setStrokeColor(0, .8, 0)

		line.strokeWidth = 4
	end

	local tess = utils.GetTess()

	for i = 1, #closed do
		local path, index = closed:GetPath(i, Path), 1

		for j = 1, #path do
			index, Contour[index], Contour[index + 1] = index + 2, path:GetPoint(j)
		end

		for j = #Contour, index, -1 do
			Contour[j] = nil
		end

		tess:AddContour(Contour)

		utils.Mesh(scene.pgroup, tess, "POSITIVE")

		local mesh = scene.pgroup[scene.pgroup.numChildren]

		mesh:setFillColor(0, 1, 0, .45)
		mesh:setStrokeColor(0, 1, 0)

		mesh.strokeWidth = 4
	end
end

-- Show --
function Scene:show (event)
	if event.phase == "did" then
        AuxUpdate(self, 1)

        local ci = 1

        self.update = timer.performWithDelay(2500, function()
            ci = ci + 1

            if ci > #Clip then
                ci = 1
            end

            AuxUpdate(self, ci)
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



--[=[

Example from http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Classes/PolyTree/_Body.htm

--[[
 polytree: 
    Contour = ()
    ChildCount = 1
    Childs[0]: 
        Contour = ((10,10),(100,10),(100,100),(10,100))
        IsHole = False
        ChildCount = 1
        Childs[0]: 
            Contour = ((20,20),(20,90),(90,90),(90,20))
            IsHole = True
            ChildCount = 2
            Childs[0]: 
                Contour = ((30,30),(50,30),(50,50),(30,50))
                IsHole = False
                ChildCount = 0
            Childs[1]: 
                Contour = ((60,60),(80,60),(80,80),(60,80))
                IsHole = False
                ChildCount = 0
]]

local outer = display.newLine(10, 10, 100, 10, 100, 100, 10, 100 --[[ ]], 10, 10)
local inner = display.newLine(20, 20, 20, 90, 90, 90, 90, 20 --[[ ]], 20, 20)

local box1 = display.newLine(30, 30, 50, 30, 50, 50, 30, 50 --[[ ]], 30, 30)
local box2 = display.newLine(60, 60, 80, 60, 80, 80, 60, 80 --[[ ]], 60, 60)

outer.strokeWidth = 4
inner.strokeWidth = 4
box1.strokeWidth = 4
box2.strokeWidth = 4

--]=]

return Scene