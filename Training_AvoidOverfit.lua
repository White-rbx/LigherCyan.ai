-- Training_AvoidOverfit.lua
-- Simple overfitting detector & early stopping heuristic:
--  - keeps short history of training 'loss' (simulated) and validation 'loss' (simulated)
--  - if val loss increases for N steps, triggers EV_TRAIN:Fire("stop")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end
local folder = player:WaitForChild("ai_runtime", 5)
local EV_TRAIN = folder:WaitForChild("ai.Training")

local history = { trainLoss = {}, valLoss = {} }
local patience = 3  -- number of epochs with no improvement before stopping

-- This module subscribes to training progress prints to estimate losses (simulation)
-- In real system you'd get real metrics; here we simulate small fluctuations.
local function simulateEpochMetrics(epoch)
    -- produce decaying train loss and fluctuating val loss
    local base = 1 / (epoch + 0.5)
    local trainLoss = base + (math.random() * 0.05)
    local valLoss = base + (math.random() * 0.12) - (epoch*0.01)
    return trainLoss, valLoss
end

-- External API: you can call folder.ai.Overfit_Check:Invoke(epoch) if you want
local FN_CHECK = folder:FindFirstChild("ai.Overfit_Check") or Instance.new("BindableFunction")
FN_CHECK.Name = "ai.Overfit_Check"
FN_CHECK.Parent = folder

FN_CHECK.OnInvoke = function(epoch)
    epoch = tonumber(epoch) or 1
    local tr, va = simulateEpochMetrics(epoch)
    table.insert(history.trainLoss, tr)
    table.insert(history.valLoss, va)
    -- compute if valLoss hasn't improved
    local bestVal = math.huge
    local lastImprovedAt = 0
    for i,v in ipairs(history.valLoss) do
        if v < bestVal then bestVal = v; lastImprovedAt = i end
    end
    local epochsSinceImprovement = #history.valLoss - lastImprovedAt
    print(("[ai.Overfit] epoch %d: train=%.4f val=%.4f bestVal=%.4f sinceImp=%d"):format(epoch,tr,va,bestVal, epochsSinceImprovement))
    if epochsSinceImprovement >= patience then
        print("[ai.Overfit] Early stopping triggered (patience exceeded). Firing ai.Training stop.")
        EV_TRAIN:Fire("stop")
        return true, "stopped"
    end
    return false, "continue"
end

print("[ai.Training.Overfit] Ready. You can call ai.Overfit_Check:Invoke(epoch) each epoch.")
