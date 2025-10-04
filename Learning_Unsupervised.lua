-- Learning_Unsupervised.lua
-- Simple frequency/topic extractor (bag-of-words) from stored examples.
-- Listens to ai.Learning commands: "train_unsupervised", "get_topics"

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end
local folder = player:WaitForChild("ai_runtime", 5)

local EV_LEARN = folder:WaitForChild("ai.Learning")
local FN_DATA_GET = folder:WaitForChild("ai.DataStorage_Get")
local FN_TOPICS = folder:FindFirstChild("ai.Unsupervised_GetTopics") or Instance.new("BindableFunction")
FN_TOPICS.Name = "ai.Unsupervised_GetTopics"
FN_TOPICS.Parent = folder

local Topics = {}  -- word -> count
local totalWords = 0

local function tokenize(s)
    s = tostring(s or ""):lower()
    local tokens = {}
    for w in s:gmatch("%w+") do tokens[#tokens+1] = w end
    return tokens
end

local function train()
    local ok, res = pcall(function() return FN_DATA_GET:Invoke() end)
    if not ok then return false, res end
    local examples = res[1] or res
    Topics = {}; totalWords = 0
    for _, ex in ipairs(examples) do
        for _, w in ipairs(tokenize(ex.text)) do
            Topics[w] = (Topics[w] or 0) + 1
            totalWords = totalWords + 1
        end
    end
    return true, totalWords
end

local function getTopN(n)
    n = n or 10
    local arr = {}
    for w,c in pairs(Topics) do table.insert(arr, {w=w,c=c}) end
    table.sort(arr, function(a,b) return a.c > b.c end)
    local out = {}
    for i=1, math.min(n,#arr) do out[i] = arr[i] end
    return out
end

FN_TOPICS.OnInvoke = function(n)
    return getTopN(n)
end

EV_LEARN.Event:Connect(function(cmd)
    if tostring(cmd or "") == "train_unsupervised" then
        local ok,res = pcall(train)
        print("[ai.Unsupervised] train:", ok, res)
    end
end)

print("[ai.Unsupervised] Ready. Use ai.Learning:Fire('train_unsupervised') then call ai.Unsupervised_GetTopics:Invoke(n).")
