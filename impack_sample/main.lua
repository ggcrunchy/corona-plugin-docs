--- Sample for impack plugin.

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

--[[
local impack = require("plugin.impack")
local bytemap = require("plugin.Bytemap")

local files = {
	"ScreenSelector.bmp",
	"FLAG.TGA",
	"MARBLES.TGA",
	"tumblr_inline_mjx5ioXh8l1qz4rgp.gif"
}

local data1, w1, h1 = impack.image.load(files[2]) -- n.b. assumes 4 channels!

local pdata, w, h, bpp = impack.image.load(files[3], { as_userdata = true })
local comp

if bpp == 1 then
	comp = "mask"
elseif bpp == 3 then
	comp = "rgb"
elseif bpp == 4 then
	comp = "rgba"
end

local bmap = bytemap.newTexture{ width = w, height = h, format = comp }
local image = display.newImage(bmap.filename, bmap.baseDir)

image.x, image.y = display.contentCenterX, display.contentCenterY - 250

impack.write.png("SS.png", w, h, bpp, pdata)

timer.performWithDelay(500, function()
local aa={}
	bmap:SetBytes(pdata,{get_info=aa})
	
	bmap:invalidate()
	local bb,ii=bmap:GetBytes()
	print("!!!",#pdata,#bb,pdata==bb) -- equality succeeds if 'as_userdata' not provided above
ii=aa
	if ii then
		for k, v in pairs(ii) do
			print("INFO", k, v)
		end
	end
end)

local ff, fw, fh = impack.image.xload("tumblr_inline_mjx5ioXh8l1qz4rgp.gif")
local fmap = bytemap.newTexture{ width = fw, height = fh, format = "rgba" }
local gif = display.newImage(fmap.filename, fmap.baseDir)

gif.x, gif.y = display.contentCenterX, display.contentCenterY

local pos, n, accum, t = 1, #ff, 0

timer.performWithDelay(20, function(event)
	local et, changed = event.time, not t

	t = t or et
	accum, t = accum + et - t, et

	while accum >= ff[pos].delay do
		accum, changed = accum - ff[pos].delay, true

		if pos == n then
			pos = 1
		else
			pos = pos + 1
		end
	end

	if changed then
		fmap:SetBytes(ff[pos].image)
		fmap:invalidate()
	end
end, 0)

local map1 = bytemap.newTexture{ width = w1, height = h1, format = "rgb" }
local image1 = display.newImage(map1.filename, map1.baseDir)

image1.x, image1.y = display.contentCenterX + 50, display.contentCenterY - 250

map1:SetBytes(data1, { format = "rgba" })

local bytes = map1:GetBytes{ format = "rgba" }

local data2, w2, h2 = impack.ops.rotate(bytes, w1, h1, math.pi / 3)
local data3, w3, h3 = impack.ops.rotate(bytes, w1, h1, math.pi * 1.1)
local data4 = impack.ops.box_filter(bytes, w1, h1, 9, 9)

local map2 = bytemap.newTexture{ width = w2, height = h2, format = "rgb" }
local image2 = display.newImage(map2.filename, map2.baseDir)

image2.x, image2.y = display.contentCenterX, display.contentCenterY - 250

local map3 = bytemap.newTexture{ width = w3, height = h3, format = "rgb" }
local image3 = display.newImage(map3.filename, map3.baseDir)

image3.x, image3.y = display.contentCenterX - 50, h3 / 2

local map4 = bytemap.newTexture{ width = w1, height = h1, format = "rgb" }
local image4 = display.newImage(map4.filename, map4.baseDir)

image4.x, image4.y = display.contentCenterX + 150, display.contentCenterY - h1 / 2

timer.performWithDelay(1000, function()
	image1:toFront()
	image2:toFront()
	image3:toFront()
	image4:toFront()
end)

map2:SetBytes(data2, { format = "rgba" })
map3:SetBytes(data3, { format = "rgba" })
map4:SetBytes(data4, { format = "rgba" })

--
local taken, frames = {}, {}

for i = 1, 5 do
	local index

	repeat
		index = math.random(#ff)
	until not taken[index]

	frames[#frames + 1] = { image = ff[index].image, delay = math.random(50, 200) }

	taken[index] = true
end

impack.write.gif("GG.gif", fw, fh, frames)
]]
