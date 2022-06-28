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
local b1 = memory_blob.New{ resizable = true }
local b2 = memory_blob.New{ resizable = true }
local qid = memory_blob.NewQueue()
local q = memory_blob.GetQueueReference(qid)
math.randomseed(os.time())
local function RandomString ()
    local n = 0
    for i = 1, 6 do
        n = n * 10 + math.random(10) - 1
    end
    return tostring(n)
end
local dopts = { out = b2 }
timer.performWithDelay(300, function(event)
    local result

    if event.count % 2 == 0 then
        result = q:TryDequeue(dopts)
    else
        result = q:TryDequeue()
    end

    if not result then
        print("Dequeued nothing (main thread)")
        return
    end

    if event.count % 2 == 0 then
        print("Dequeued to blob (main thread)", b2:GetBytes(), #b2)
    else
        print("Dequeued string (main thread)", result)
    end
end, 20)
timer.performWithDelay(600, function(event)
    local s = RandomString()
    if event.count % 2 == 0 then
        b1:Write(1, s)
        print("Going to enqueue blob (main thread)", b1:GetBytes(), #b1)
        q:Enqueue(b1)
        print("Blob now (main thread)", b1:GetBytes(), #b1)
    else
        print("Queueing string (main thread)", s, #s)
        q:Enqueue(s)
    end
end, 15)
-- Encode a table as a string so that it can be captured. Launch a process to
-- decode and operate on it asynchronously.
local bytes = marshal.encode{ t = 37, a = 16, d = 4 }
luaproc.newproc(function()
    local math = require("math")
    local marshal = require("serialize").marshal
    local memory_blob = require("MemoryBlob")
    local string = require("string")
    local function RandomString ()
        local n = 0
        for i = 1, 8 do
            n = n * 10 + math.random(10) - 1
        end
        return tostring(n)
    end
    local p1_b1 = memory_blob.New{ resizable = true }
    local p1_b2 = memory_blob.New{ resizable = true }
    local p1_q = memory_blob.GetQueueReference(qid)
    local p1_dopts = { out = p1_b2 }
    for ii = 1, 40 do
        repeat
            luaproc.sleep(200)

            local jj = ii % 4
            if jj < 2 then
                local result
                if jj % 2 == 0 then
                    result = p1_q:TryDequeue(p1_dopts)
                else
                    result = p1_q:TryDequeue()
                end
                if not result then
                    print("Dequeued nothing (process 1)")
                    break -- out of repeat-until false
                end
                if jj % 2 == 0 then
                    print("Dequeued to blob (process 1)", p1_b2:GetBytes(), #p1_b2)
                else
                    print("Dequeued string (process 1)", result)
                end         
            else
                local s = RandomString()
                if jj % 2 == 0 then
                    p1_b1:Write(1, s)
                    print("Going to enqueue blob (process 1)", p1_b1:GetBytes(), #p1_b1)
                    p1_q:Enqueue(p1_b1)
                    print("Blob now (process 1)", p1_b1:GetBytes(), #p1_b1)
                else
                    print("Queueing string (process 1)", s, #s)
                    p1_q:Enqueue(s)
                end
            end
        until true
    end
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
luaproc.newproc(function()
    local math = require("math")
    local marshal = require("serialize").marshal
    local memory_blob = require("MemoryBlob")
    local string = require("string")
    local function RandomString ()
        local n = 0
        for i = 1, 9 do
            n = n * 10 + math.random(10) - 1
        end
        return tostring(n)
    end
    local p2_b1 = memory_blob.New{ resizable = true }
    local p2_b2 = memory_blob.New{ resizable = true }
    local p2_q = memory_blob.GetQueueReference(qid)
    local p2_dopts = { out = p2_b2 }
    for ii = 1, 40 do
        repeat
            luaproc.sleep(200)

            local jj = ii % 4
            if jj < 2 then
                local result
                if jj % 2 == 0 then
                    result = p2_q:TryDequeue(p2_dopts)
                else
                    result = p2_q:TryDequeue()
                end
                if not result then
                    print("Dequeued nothing (process 2)")
                    break -- out of repeat-until false
                end
                if jj % 2 == 0 then
                    print("Dequeued to blob (process 2)", p2_b2:GetBytes(), #p2_b2)
                else
                    print("Dequeued string (process 2)", result)
                end         
            else
                local s = RandomString()
                if jj % 2 == 0 then
                    p2_b1:Write(1, s)
                    print("Going to enqueue blob (process 1)", p2_b1:GetBytes(), #p2_b1)
                    p2_q:Enqueue(p2_b1)
                    print("Blob now (process 1)", p2_b1:GetBytes(), #p2_b1)
                else
                    print("Queueing string (process 1)", s, #s)
                    p2_q:Enqueue(s)
                end
            end
        until true
    end
end)