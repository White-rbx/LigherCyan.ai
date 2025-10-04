-- bootstrap.lua
-- สร้างโฟลเดอร์ runtime และ BindableEvents/BindableFunctions ที่ใช้สื่อสารภายใน client
-- รันไฟล์นี้ก่อนไฟล์อื่นเสมอ

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then
    warn("[ai.bootstrap] No LocalPlayer found. Run as LocalScript or via executor after player exists.")
    return
end

-- สร้าง folder เก็บไอเท็มของระบบ AI ภายใน player (session-only)
local folder = player:FindFirstChild("ai_runtime")
if not folder then
    folder = Instance.new("Folder")
    folder.Name = "ai_runtime"
    folder.Parent = player
end

-- Helper: create BindableEvent/Function if not exists
local function ensureBindableEvent(name)
    local ev = folder:FindFirstChild(name)
    if ev and ev:IsA("BindableEvent") then return ev end
    if ev then ev:Destroy() end
    local be = Instance.new("BindableEvent")
    be.Name = name
    be.Parent = folder
    return be
end
local function ensureBindableFunction(name)
    local bf = folder:FindFirstChild(name)
    if bf and bf:IsA("BindableFunction") then return bf end
    if bf then bf:Destroy() end
    local bfn = Instance.new("BindableFunction")
    bfn.Name = name
    bfn.Parent = folder
    return bfn
end

-- ตามสเปค: สร้าง ai.DataStorage, ai.Learning, ai.Training (แบบ BindableEvent/Function)
local EV_DATA = ensureBindableEvent("ai.DataStorage")       -- event for adding raw data (Fire)
local FN_DATA_ADD = ensureBindableFunction("ai.DataStorage_Add") -- invoke to add and get ack
local FN_DATA_GET  = ensureBindableFunction("ai.DataStorage_Get") -- invoke to return all data (table)

local EV_LEARN = ensureBindableEvent("ai.Learning")         -- event to issue learning commands
local EV_TRAIN = ensureBindableEvent("ai.Training")         -- event to issue training commands

-- small debug print
print("[ai.bootstrap] runtime folder & bindables ready under Player.ai_runtime")
print("[ai.bootstrap] Events:", EV_DATA.Name, EV_LEARN.Name, EV_TRAIN.Name)
