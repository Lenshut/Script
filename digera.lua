--[[
    IBdihP Hub - Lightweight Digimon Era Standalone (Zero-Lag)
    Features: Auto Farm & Auto Collect Chests (Standard/Royal Treasure Only)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- CONFIGURATION (Change to false to disable)
-- ==========================================
local Config = {
    AutoFarm = true,
    AutoCollectTreasure = true,
    FarmDistance = 5,           -- Studs away from the enemy
    TreasureCheckDelay = 1.5,   -- Seconds between chest scans
    FarmCheckDelay = 0.2        -- Seconds between target updates
}

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================
local function getCharacter()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
        if char.Humanoid.Health > 0 then
            return char, char.HumanoidRootPart
        end
    end
    return nil, nil
end

local function firePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0.1)
            prompt:InputHoldEnd()
        end
    end
end

-- ==========================================
-- 1. AUTO COLLECT CHESTS / TREASURE
-- ==========================================
task.spawn(function()
    while true do
        if Config.AutoCollectTreasure then
            local char, root = getCharacter()
            local gameMap = Workspace:FindFirstChild("GameMap") or Workspace
            
            if char and root and gameMap then
                for _, obj in ipairs(gameMap:GetDescendants()) do
                    -- Target strictly Royal & Standard Treasure chests
                    if obj:IsA("Model") or obj:IsA("BasePart") then
                        if obj.Name == "Standard Treasure" or obj.Name == "Royal Treasure" then
                            local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
                            local targetPart = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                            
                            if prompt and targetPart then
                                -- Move to chest and fire ProximityPrompt
                                root.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                                task.wait(0.25)
                                firePrompt(prompt)
                                task.wait(0.25)
                            end
                        end
                    end
                end
            end
        end
        task.wait(Config.TreasureCheckDelay)
    end
end)

-- ==========================================
-- 2. AUTO FARM ENEMIES
-- ==========================================
local function getClosestEnemy(root)
    local closestEnemy = nil
    local shortestDistance = math.huge
    
    -- Checks standard workspace enemy folders
    local enemyFolder = Workspace:FindFirstChild("Enemies") 
        or (Workspace:FindFirstChild("GameMap") and Workspace.GameMap:FindFirstChild("Enemies"))
        or Workspace
        
    for _, obj in ipairs(enemyFolder:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local enemyRoot = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
            
            if hum and hum.Health > 0 and enemyRoot then
                local dist = (root.Position - enemyRoot.Position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestEnemy = enemyRoot
                end
            end
        end
    end
    
    return closestEnemy
end

task.spawn(function()
    while true do
        if Config.AutoFarm then
            local char, root = getCharacter()
            if char and root then
                local targetEnemyRoot = getClosestEnemy(root)
                if targetEnemyRoot then
                    -- Position directly above/behind the enemy to avoid collision physics lag
                    root.CFrame = targetEnemyRoot.CFrame * CFrame.new(0, 0, Config.FarmDistance)
                end
            end
        end
        task.wait(Config.FarmCheckDelay)
    end
end)

print("[IBdihP Simplified] Auto Farm & Treasure Collector Running.")
