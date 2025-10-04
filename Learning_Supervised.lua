-- Learning_Supervised.lua
-- A simple supervised learner: stores mapping of input tokens -> responses and frequency
-- Listens to ai.Learning BindableEvent commands
-- Commands accepted: "train_map" (no payload -> uses DataStorage), "predict" with arg text -> returns best response
-- Exposes a BindableFunction ai.Learning_Supervised_Predict for on-demand prediction.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end
local folder = player:WaitForChild("ai_runtime", 5)

local EV_LEARN = folder:WaitForChild("ai.Learning")
local FN_DATA_GET = folder:WaitForChild("ai.DataStorage_Get")
-- expose predict function
local FN_PRED = folder:FindFirstChild("ai.Learning_Supervised_Predict") or Instance.new("BindableFunction")
FN_PRED.Name = "ai.Learning_Supervised_Predict"
FN_PRED.Parent = folder

-- Internal model: mapping input-key -> table of responses with counts
local Model = {
    mapping = {},   -- key -> { resp = count, ... }
    total_examples = 0
}

local function tokenize(s)
    s = tostring(s or ""):lower()
    local tokens = {}
    for w in s:gmatch("%w+") do tokens[#tokens+1] = w end
    return tokens
end

local function keyFromText(s)
    -- simple: first 3 tokens joined
    local t = tokenize(s)
    if #t == 0 then return nil end
    local n = math.min(3, #t)
    local key = table.concat({ t[1], (t[2] or ""), (t[3] or "") }, " ")
    return key
end

local function trainFromStorage()
    local ok, dataOrStats = pcall(function() return FN_DATA_GET:Invoke() end)
    if not ok then return false, dataOrStats end
    local examples = dataOrStats[1] or dataOrStats -- compatibility
    local added = 0
    for _, ex in ipairs(examples) do
        local txt = ex.text or ""
        local key = keyFromText(txt)
        if key then
            Model.mapping[key] = Model.mapping[key] or {}
            local resp = ex.meta and ex.meta.response or "unknown"
            Model.mapping[key][resp] = (Model.mapping[key][resp] or 0) + 1
            added = added + 1
        end
    end
    Model.total_examples = Model.total_examples + added
    return true, added
end

local function predict(text)
    local key = keyFromText(text)
    if not key then return nil end
    local bucket = Model.mapping[key]
    if not bucket then return nil end
    -- choose max-count response
    local best, bestc = nil, 0
    for r,c in pairs(bucket) do
        if c > bestc then bestc = c; best = r end
    end
    return best, bestc
end

-- Bindable predict
FN_PRED.OnInvoke = function(text)
    return predict(text)
end

-- Listen to learning event commands
EV_LEARN.Event:Connect(function(cmd, payload)
    cmd = tostring(cmd or "")
    if cmd == "train_supervised" then
        local ok, res = pcall(trainFromStorage)
        print("[ai.Learning.Supervised] train result:", ok, res)
    elseif cmd == "clear_model" then
        Model.mapping = {}; Model.total_examples = 0
        print("[ai.Learning.Supervised] model cleared")
    elseif cmd == "inspect" then
        print("[ai.Learning.Supervised] model size:", Model.total_examples)
    end
end)

print("[ai.Learning.Supervised] Ready. Use ai.Learning:Fire('train_supervised') to train.")
