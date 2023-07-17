--- Scene that demonstrates glyph meshes.

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
local huge = math.huge
local random = math.random
local unpack = unpack

-- Modules --
local utils = require("utils")

-- Plugins --
local libtess2 = require("plugin.libtess2")

-- Solar2D globals --
local display = display
local native = native
local timer = timer
local transition = transition

-- Solar2D modules --
local composer = require("composer")
local widget = require("widget")

--
--
--

local Scene = composer.newScene()

--
--
--

local Tess

--
--
--

local function RemoveText ()
  display.remove(Scene.m_text_group) -- n.b. timer will kill self

  Scene.m_text_group = nil
end

--
--
--

local AddText

function Scene:create ()
  self.m_selection = display.newGroup()

  self.view:insert(self.m_selection)

  local function OnPress (event)
    if event.target.id ~= self.m_mode then
      RemoveText()

      self.m_mode = event.target.id

      AddText(self.m_mode)
    end
  end

  for i, v in ipairs{
    { text = "Basic mesh (indexed)", id = "basic" },
    { text = "Basic mesh (flat triangle list)", id = "flat" },
    { text = "As lines", id = "lines" },
    { text = "Distorted (jittery)", id = "jittery" },
    { text = "Distorted (transitioned)", id = "trans" }
  } do
    local button = widget.newSwitch{
      left = 20, top = 40 + i * 15,
      width = 15, height = 10,
      style = "radio", id = v.id,
      initialSwitchState = i == 1,
      onPress = OnPress
    }

    local text = display.newText(self.m_selection, v.text, 0, button.y, native.systemFont, 9)

    text.anchorX, text.x = 0, button.contentBounds.xMax + 15

    self.m_selection:insert(button)
  end

  --
  --
  --

	Tess = libtess2.NewTess()

	Tess:SetOption("CONSTRAINED_DELAUNAY_TRIANGULATION", true)
end

Scene:addEventListener("create")

--
--
--

function Scene:destroy ()
	Tess = nil
end

Scene:addEventListener("destroy")

--
--
--

local FadeInParams = { alpha = 1 }
local FadeOutParams = { alpha = 0, onComplete = display.remove }

local function FadeObject (object, delay)
  object.alpha = 0

  FadeInParams.delay = delay
  FadeOutParams.delay = delay + 2350
  
  transition.to(object, FadeInParams)
  transition.to(object, FadeOutParams)
end

--
--
--

local function RandomComponent ()
  local t = random()

  return .0625 * (1 - t) + .9375 * t
end

local function Jitter (component)
  return component + (2 * random() - 1) * .125
end

--
--
--

local function MakeAddContour (body)
  return function(arg)
    local points = arg.points

    if points and #points > 0 then
      body(Tess, points, arg)

      arg.points = nil
    end
  end
end

local AddContour = MakeAddContour(function(tess, points, _)
  tess:AddContour(points)
end)

local AddContourAndGetMin = MakeAddContour(function(tess, points, arg)
  arg.minx, arg.miny = utils.AddContourAndGetMin(tess, points, arg.minx, arg.miny)
end)

--
--
--

local function JitteryPrep ()
  return .5
end

local function JitteryUpdate (path, j, _, _, x2, y2)
  path:setVertex(j, x2, y2)
end

--
--
--

local MoveParams = {}

function MoveParams:onComplete ()
  self.x = nil
end

--
--
--

local function TransitionedPrep (vertices)
  local positions = {}

  for i = 1, #vertices / 2 do
    positions[i] = {}
  end

  return 1.5, positions
end

local function TransitionedUpdate (path, j, x1, y1, x2, y2, positions)
  local pos = positions[j]
          
  if pos.x then
    path:setVertex(j, pos.x, pos.y)
  else
    pos.x, MoveParams.x = x1, x2
    pos.y, MoveParams.y = y1, y2
    MoveParams.time = random(300, 900)

    transition.to(pos, MoveParams)
  end
end

--
--
--

local function AddDistortion (mesh, vertices, prep, update)
  local scale, context = prep(vertices)

  timer.performWithDelay(100, function(event)
    local path = mesh.path

    if path then -- mesh not destroyed?
      local j = 1

      for i = 1, #vertices, 2 do
        local x1, y1 = vertices[i], vertices[i + 1]
        local x2, y2 = x1 + (2 * random() - 1) * scale, y1 + (2 * random() - 1) * scale

        update(path, j, x1, y1, x2, y2, context)

        j = j + 1
      end
    else
      timer.cancel(event.source)
    end
  end, 0)
end

--
--
--

local function AddTriangle (out, elems, verts, base, offset)
  for _ = 1, 3 do
    local index = elems[base]

    out[offset + 1] = verts[index * 2 + 1]
    out[offset + 2] = verts[index * 2 + 2]
    base, offset = base + 1, offset + 2
  end

  return base, offset
end

--
--
--

local function FlatMesh (vertices)
  local flattened, base, offset = {}, 1, 0
  local elems, verts = Tess:GetElements(), Tess:GetVertices()

  for i = 1, Tess:GetElementCount() do
    base, offset = AddTriangle(flattened, elems, verts, base, offset)
  end

  return display.newMesh{
    parent = Scene.m_text_group,
    vertices = flattened
  }, flattened
end

--
--
--

local function IndexedMesh (vertices)
  return display.newMesh{
    parent = Scene.m_text_group,
    indices = Tess:GetElements(), mode = "indexed", zeroBasedIndices = true,
    vertices = vertices
  }, vertices
end

--
--
--

local function DrawMesh (arg)
  local mesh, vertices = (arg.flat and FlatMesh or IndexedMesh)(Tess:GetVertices())

  mesh.anchorX, mesh.x = 0, arg.minx
  mesh.anchorY, mesh.y = 0, arg.miny

  --
  --
  --

  local r, g, b = RandomComponent(), RandomComponent(), RandomComponent()

  for i = 1, #vertices / 2 do
    mesh:setFillVertexColor(i, Jitter(r), Jitter(g), Jitter(b))
  end

  --
  --
  --

  if arg.prep then
    AddDistortion(mesh, vertices, arg.prep, arg.update)
  end

  --
  --
  --

  return mesh
end

--
--
--

local function DrawLines ()
  local polys = display.newGroup()

  Scene.m_text_group:insert(polys)

  --
  --
  --

  local base, elems, verts = 1, Tess:GetElements(), Tess:GetVertices()

  for i = 1, Tess:GetElementCount() do
    local coords = {}

    base = AddTriangle(coords, elems, verts, base, 0)
    coords[7], coords[8] = coords[1], coords[2]

    local line = display.newLine(polys, unpack(coords))

    line:setStrokeColor(random(), random(), random())
  end

  --
  --
  --

  return polys
end

--
--
--

local DoContours = utils.MakeContourListener{
  add_point = function(x, y, arg)
    local points = arg.points

    points[#points + 1] = x
    points[#points + 1] = y
  end,

  finish = function(arg,xx,yy)
    arg:try_to_add_contour()

    if Tess:Tesselate("POSITIVE", "POLYGONS", 3) then
	local m=arg:draw()
	m:translate(xx, yy)
      FadeObject(--[[arg:draw()]]m, (arg.index - 1) * 300)

      arg.index = arg.index + 1
    end
  end,

  move = function(_, _, arg)
    arg:try_to_add_contour()

    arg.points = arg.points or {}
  end,

  start = function(arg)
    arg.minx, arg.miny = huge, huge
  end
}

--
--
--

function AddText (mode) -- n.b. was forward ref'd
  Scene.m_text_group = display.newGroup()

  Scene.view:insert(Scene.m_text_group)
  
  --
  --
  --

  local arg = { index = 1 }

  if mode ~= "lines" then
    arg.draw = DrawMesh
    arg.try_to_add_contour = AddContourAndGetMin

    if mode == "flat" then
      arg.flat = true
    elseif mode ~= "basic" then
      arg.segment_lines = true

      if mode == "jittery" then
        arg.prep, arg.update = JitteryPrep, JitteryUpdate
      else
        arg.prep, arg.update = TransitionedPrep, TransitionedUpdate
      end
    end
  else
    arg.draw = DrawLines
    arg.try_to_add_contour = AddContour
  end

  --
  --
  --

  local font = Scene.m_font

  utils.ShapesLine{
    text = "Mil7kst 88 or 3?!", font = font,
    scale = font:ScaleForPixelHeight(15) * 4,
    current = 25, baseline = 200,
    listener = DoContours, arg = arg
  }
end

--
--
--

function Scene:show (event)
	if event.phase == "did" then
		self.m_font = utils.FontFromText("Mayan")

    AddText(self.m_mode or "basic")
	end
end

Scene:addEventListener("show")

--
--
--

function Scene:hide (event)
	if event.phase == "did" then
		RemoveText()

    self.m_font = nil
	end
end

Scene:addEventListener("hide")

--
--
--

return Scene