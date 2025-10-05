-- LighterCyan GitHub Module Loader
-- ใช้กับ executor (KRNL) หรือ LocalScript (ถ้า HttpGet ถูกอนุญาต)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then error("No LocalPlayer") end

local files = {
    {"bootstrap", "https://raw.githubusercontent.com/White-rbx/LigherCyan.ai/refs/heads/main/bootstrap.lua"},
    {"DataStorage", "https://raw.githubusercontent.com/White-rbx/LigherCyan.ai/refs/heads/main/DataStorage.lua"},
    {"Learning_Supervised", "https://raw.githubusercontent.com/White-rbx/LigherCyan.ai/refs/heads/main/Learning_Supervised.lua"},
    {"Learning_Unsupervised", "https://raw.githubusercontent.com/White-rbx/LigherCyan.ai/refs/heads/main/Learning_Unsupervised.lua"},
    {"Learning_Reinforcement", "https://raw.githubusercontent.com/White-rbx/LigherCyan.ai/refs/heads/main/Learning_Reinforcement.lua"},
    {"Training_BatchEpoch", "https://raw.githubusercontent.com/White-rbx/LigherCyan.ai/refs/heads/main/Training_BatchEpoch.lua"},
    {"Training_AvoidOverfit", "https://raw.githubusercontent.com/White-rbx/LigherCyan.ai/refs/heads/main/Training_AvoidOverfit.lua"},
}

local function ensure_ai_runtime_polyfill()
    local folder = player:FindFirstChild("ai_runtime")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ai_runtime"
        folder.Parent = player
    end
    -- create essential bindables if missing
    local function ensureBindableFunction(name)
        if not folder:FindFirstChild(name) then
            local bf = Instance.new("BindableFunction")
            bf.Name = name
            bf.Parent = folder
            bf.OnInvoke = function(...) return nil end
        end
    end
    local function ensureBindableEvent(name)
        if not folder:FindFirstChild(name) then
            local be = Instance.new("BindableEvent")
            be.Name = name
            be.Parent = folder
        end
    end
    ensureBindableEvent("ai.DataStorage")
    ensureBindableFunction("ai.DataStorage_Add")
    ensureBindableFunction("ai.DataStorage_Get")
    ensureBindableEvent("ai.Learning")
    ensureBindableEvent("ai.Training")
    ensureBindableFunction("ai.Learning_Supervised_Predict")
    ensureBindableFunction("ai.Unsupervised_GetTopics")
    return folder
end

local function try_get(url)
    local ok, body = pcall(function() return game:HttpGet(url, true) end)
    if ok and body and #body > 5 then return true, body end
    ok, body = pcall(function() return HttpService:GetAsync(url, true) end)
    if ok and body and #body > 5 then return true, body end
    return false, body
end

local loaded = {}
local errors = {}

-- always try bootstrap first
for i,info in ipairs(files) do
    local name, url = info[1], info[2]
    print("[Loader] Fetching:", name, url)
    local ok, body = try_get(url)
    if not ok then
        warn("[Loader] GET failed for", name, ":", tostring(body))
        errors[name] = tostring(body)
        -- if bootstrap fails, create polyfill immediately
        if name == "bootstrap" then
            ensure_ai_runtime_polyfill()
            print("[Loader] bootstrap polyfill created (ai_runtime + basic bindables).")
        end
    else
        -- run code safely
        local fn, err = loadstring(body)
        if not fn then
            warn("[Loader] loadstring error for", name, ":", tostring(err))
            errors[name] = tostring(err)
        else
            local ok2, r2 = pcall(fn)
            if not ok2 then
                warn("[Loader] runtime error for", name, ":", tostring(r2))
                errors[name] = tostring(r2)
                -- if bootstrap runtime failed, polyfill
                if name == "bootstrap" then
                    ensure_ai_runtime_polyfill()
                    print("[Loader] bootstrap polyfill created after runtime failure.")
                end
            else
                loaded[name] = true
                print("[Loader] Loaded:", name)
            end
        end
    end
    -- small delay between loads
    task.wait(0.08)
end

-- summary
print("----- Loader Summary -----")
for i,info in ipairs(files) do
    local name = info[1]
    if loaded[name] then
        print("[OK] ", name)
    else
        print("[FAIL]", name, errors[name] or "unknown")
    end
end
print("If bootstrap failed, ai_runtime polyfill was created. Now run your controller script.")
