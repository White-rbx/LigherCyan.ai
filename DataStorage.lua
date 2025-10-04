-- DataStorage.lua
-- In-memory session-only storage for text examples.
-- Expose API via BindableFunction: ai.DataStorage_Add (text) -> true/err, ai.DataStorage_Get() -> table copy
-- Also listens to ai.DataStorage event (BindableEvent) to append.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end
local folder = player:WaitForChild("ai_runtime", 5)
if not folder then error("[ai.DataStorage] ai_runtime folder missing. Run bootstrap first.") end

local EVENT = folder:WaitForChild("ai.DataStorage")           -- BindableEvent
local FN_ADD = folder:WaitForChild("ai.DataStorage_Add")      -- BindableFunction
local FN_GET = folder:WaitForChild("ai.DataStorage_Get")      -- BindableFunction

-- internal storage table
local Storage = {
    examples = {},   -- each item: {text=..., meta={time=..., source=...}}
    stats = {count = 0}
}

-- Utility: shallow copy of storage.examples
local function getAll()
    local out = {}
    for i,v in ipairs(Storage.examples) do out[i] = {text = v.text, meta = v.meta} end
    return out
end

-- Add function (exposed)
FN_ADD.OnInvoke = function(text, meta)
    if not text or tostring(text):match("^%s*$") then return false, "empty" end
    local entry = { text = tostring(text), meta = meta or {time = os.time()} }
    table.insert(Storage.examples, entry)
    Storage.stats.count = #Storage.examples
    -- optional: immediate local publish for other listeners
    pcall(function() EVENT:Fire(entry) end)
    return true, entry
end

-- Get function
FN_GET.OnInvoke = function()
    return getAll(), Storage.stats
end

-- Also listen to Event fire directly (convenience)
EVENT.Event:Connect(function(payload)
    -- If payload is string, treat as text
    if type(payload) == "string" then
        FN_ADD:Invoke(payload)
    elseif type(payload) == "table" and payload.text then
        FN_ADD:Invoke(payload.text, payload.meta)
    end
end)

print("[ai.DataStorage] Ready. Use ai.DataStorage_Add / ai.DataStorage_Get via BindableFunction.")
