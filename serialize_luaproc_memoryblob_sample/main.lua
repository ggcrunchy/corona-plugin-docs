--- Sample for serialize and luaproc plugins: sends complex data to and from a Lua process.

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
local luaproc = require("plugin.luaproc")
local memory_blob = require("plugin.MemoryBlob")
local serialize = require "plugin.serialize"

-- Modules --
local marshal = serialize.marshal

-- Prepare a message to tell us what's going on.
local cx, cy = display.contentCenterX, display.contentCenterY
local message = display.newText("Capturing serialized table", cx, cy, native.systemFont, 19)

-- Register serialize's entry point with luaproc.
luaproc.preload("serialize", serialize.Reloader)
luaproc.preload("MemoryBlob", memory_blob.Reloader)

memory_blob.GetBlobDispatcher():addEventListener("stale_entry", function(event)
	print("BYE", event.id)
end)

-- Respond to alerts from another process.
local has_doubled = false

luaproc.get_alert_dispatcher():addEventListener("alerts", function(event)
	if event.payload == true then
		message.text = "Doubling all values"
		has_doubled = true
	else
		local content = event.payload

		-- On the second string-type alert, the payload will be an encoded table.
		if has_doubled then
			local decoded = marshal.decode(content)

			content = decoded.get_contents(decoded.t)
		end

		message.text = "Contents of table: " .. content
	end
end)

local S1 = "DKDKDJKE(DFASDFKASDFJSDKFSDFASFDSFASDFDF"
local S3 = "KDFJDFJDKFJDKFJDFKDJFKDFJDKFJDKFDKFDFK"
print("SSS",#S1,#S3)
local b1 = memory_blob.New{ resizable = true }
local b2 = memory_blob.New{ resizable = true }
local b3 = memory_blob.New{ size = #S3 }

b1:Write(1, S1)
b2:Write(3, S3)

luaproc.get_alert_dispatcher():addEventListener("blobs", function(event)
	local what, blob = event.payload
	local index, id = what:sub(1, 1), what:sub(3)

	if index == "1" then
		blob = b1
	elseif index == "2" then
		blob = b2
	else
		blob = b3
	end

	local result = blob:Sync(id)
	local aa, bb, cc = "BLOB " .. index, blob:GetBytes(), #blob

	print(result, aa, cc, bb)
end)
--[[
timer.performWithDelay(100, function(e)
	if e.count % 15 == 0 then
		memory_blob.StepStorageFrame()
	end
	memory_blob.PurgeStaleStorage(5)
end, 0)
]]
-- Encode a table as a string so that it can be captured. Launch a process to
-- decode and operate on it asynchronously.
local bytes = marshal.encode{ t = 37, a = 16, d = 4 }

luaproc.newproc(function()
	local marshal = require("serialize").marshal
	local memory_blob = require("MemoryBlob")
	local string = require("string")

	luaproc.sleep(2500)

	local Str1 = "ERFEIJKL:ASDFIOJADF:LOKJ"
	local Str2 = "#5()PDFJKDJFLASDFOWKDFJS"
	local Str3 = "DFKDFKUUJKDKKDAFJKALSLSD"

	local blob1 = memory_blob.New{ resizable = true }
	local blob2 = memory_blob.New{ resizable = true, size = #Str2 / 2 }
	local blob3 = memory_blob.New{ size = #Str3 - 4 }

	print("SIZES", #blob1, #blob2, #blob3, #Str1)

	blob1:Write(1, Str1)
	blob2:Write(1, Str2)
	blob3:Write(1, Str3)

	print("BLOB1", blob1:GetBytes(), #blob1)
	print("BLOB2", blob2:GetBytes(), #blob2)
	print("BLOB3", blob3:GetBytes(), #blob3)

	local id1 = blob1:Submit()
	local id2 = blob2:Submit()
	local id3 = blob3:Submit()

	print("ID1", id1)
	print("ID2", id2)
	print("ID3", id3)
	
	luaproc.alert("blobs", "1:" .. id1)
	luaproc.alert("blobs", "2:" .. id2)
	luaproc.alert("blobs", "3:" .. id3)

	print("BLOB1 now", blob1:GetBytes(), #blob1)
	print("BLOB2 now", blob2:GetBytes(), #blob2)
	print("BLOB3 now", blob3:GetBytes(), #blob3)
--[[
alignment: If specified, the memory alignment, which must be a multiple of 2, ≥ 4. The blob's memory will start at an address that is a multiple of this value, which is useful and / or needed e.g. for SIMD operations. By default, blobs use the Lua allocator's alignment. 

Currently, the upper limit is 1024, one level beyond AVX2 support.
resizable: If true, the blob can be resized. Off by default.
size: Blob size in bytes, ≥ 0. For resizable blobs, this is the blob's initial size; otherwise, it specifies the fixed size. If absent, 0.
]]
	-- Get the table back.
	local original = marshal.decode(bytes)

	-- Returns table contents as a string
	local function GetContents (t)
		local contents, prev = ""

		for k, v in pairs(t) do
			contents = contents .. (prev and ", " or "") .. k .. " = " .. tostring(v)
			prev = true
		end

		return contents
	end

	-- Report back to the main state, then wait a bit.
	luaproc.alert("alerts", GetContents(original))
	luaproc.sleep(2500)
	luaproc.alert("alerts", true)
	luaproc.sleep(2500)

	-- Double the original values and send them back to the main state.
	for k, v in pairs(original) do
		original[k] = v * 2
	end

	luaproc.alert("alerts", marshal.encode{
		get_contents = GetContents, t = original
	})
end)
