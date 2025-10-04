-- Training_BatchEpoch.lua
-- Simulate batch/epoch training loops that call Learning modules.
-- Listens to ai.Training BindableEvent:
--  - ai.Training:Fire("start", {mode="supervised", epochs=3, batchSize=32})
--  - ai.Training:Fire("stop")
-- Emits progress events by printing and can call ai.Learning with 'train_supervised' etc.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end
local folder = player:WaitForChild("ai_runtime", 5)
local EV_TRAIN = folder:WaitForChild("ai.Training")
local EV_LEARN  = folder:WaitForChild("ai.Learning")

local running = false
local currentJob = nil

local function doEpochs(mode, epochs, batchSize, onProgress)
    -- mode: "supervised" / "unsupervised" / "reinforcement"
    epochs = math.max(1, tonumber(epochs) or 1)
    batchSize = math.max(1, tonumber(batchSize) or 32)
    for e = 1, epochs do
        if not running then break end
        -- For supervised: trigger train in learning module (which consumes DataStorage)
        if mode == "supervised" then
            EV_LEARN:Fire("train_supervised")
            if onProgress then onProgress(e, epochs, "supervised") end
        elseif mode == "unsupervised" then
            EV_LEARN:Fire("train_unsupervised")
            if onProgress then onProgress(e, epochs, "unsupervised") end
        elseif mode == "reinforcement" then
            -- reinforcement may require environment interactions; here we simulate a policy pass
            EV_LEARN:Fire("rl_dump")
            if onProgress then onProgress(e, epochs, "reinforcement") end
        end
        -- small wait to simulate work & yield UI
        task.wait(0.12)
    end
end

-- Listen for train commands
EV_TRAIN.Event:Connect(function(cmd, params)
    cmd = tostring(cmd or "")
    if cmd == "start" then
        if running then print("[ai.Training] already running") return end
        running = true
        params = params or {}
        local mode = params.mode or "supervised"
        local epochs = params.epochs or 3
        local batchSize = params.batchSize or 32
        print("[ai.Training] Starting job:", mode, "epochs=", epochs, "batchSize=", batchSize)
        currentJob = task.spawn(function()
            doEpochs(mode, epochs, batchSize, function(step, total, m)
                print(("[ai.Training] progress %d/%d mode=%s"):format(step, total, tostring(m)))
            end)
            running = false
            print("[ai.Training] Job finished")
        end)
    elseif cmd == "stop" then
        running = false
        print("[ai.Training] Stop requested")
    end
end)

print("[ai.Training.BatchEpoch] Ready. Use ai.Training:Fire('start', {mode='supervised', epochs=5, batchSize=32})")
