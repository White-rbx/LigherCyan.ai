-- Learning_Reinforcement.lua
-- Very simple RL-like updater: stores actions and rewards, updates action-values (Q-values) per state-key
-- Commands via ai.Learning: 'rl_record' (payload: {state=..., action=..., reward=...}), 'rl_policy' to get best action

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end
local folder = player:WaitForChild("ai_runtime", 5)
local EV_LEARN = folder:WaitForChild("ai.Learning")

-- simple Q-table: stateKey -> { action -> value }
local Q = {}
local alpha = 0.3  -- learning rate
local gamma = 0.9  -- discount (not used for single-step)
local function stateKey(s)
    return tostring(s or ""):sub(1,120)
end

-- record transition (single-step)
local function recordTransition(t)
    -- t = {state=..., action=..., reward=number}
    if not t or type(t) ~= "table" then return false, "bad payload" end
    local s = stateKey(t.state)
    local a = tostring(t.action or "act")
    local r = tonumber(t.reward) or 0
    Q[s] = Q[s] or {}
    Q[s][a] = (Q[s][a] or 0) + alpha * (r - (Q[s][a] or 0))
    return true
end

local function bestActionFor(state)
    local s = stateKey(state)
    local bucket = Q[s]
    if not bucket then return nil end
    local best, val = nil, -1e9
    for a,v in pairs(bucket) do
        if v > val then best, val = a, v end
    end
    return best, val
end

EV_LEARN.Event:Connect(function(cmd, payload)
    cmd = tostring(cmd or "")
    if cmd == "rl_record" then
        local ok, res = pcall(recordTransition, payload)
        if not ok then print("[ai.RL] record error:", res) end
    elseif cmd == "rl_policy" then
        local s = payload or ""
        local a, v = bestActionFor(s)
        print("[ai.RL] best action for", tostring(s), "=>", tostring(a), v)
    elseif cmd == "rl_dump" then
        print("[ai.RL] Q entries", (function() local c=0 for _ in pairs(Q) do c=c+1 end return c end)())
    end
end)

print("[ai.Reinforcement] Ready (alpha="..tostring(alpha).."). Use ai.Learning:Fire('rl_record', {state=...,action=...,reward=...}).")
