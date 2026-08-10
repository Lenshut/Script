--[[
    IBdihP Hub - Digimon Era Standalone (With Toggle UI)
    Features: Auto Farm, Auto Collect Chests, and a Lightweight Control Panel
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- 1. LOBBY & EXECUTOR ACCESS CHECK
-- ==========================================
if game.PlaceId == 70863683083739 then
    StarterGui:SetCore("SendNotification", {
        Title = "IBdihP - Execution Warning";
        Text = "You are in the Lobby! Go into a gamemode place to use Auto Farm.";
        Duration = 6;
    })
    return
end

-- ==========================================
-- 2. CONFIGURATION & STATE
-- ==========================================
local Config = {
    AutoFarm = false,            -- Starts OFF so you can toggle it when ready
    AutoCollectTreasure = false, -- Starts OFF so you can toggle it when ready
    ScriptRunning = true,
    FarmDistance = 5,
    TreasureCheckDelay = 1.5,
    FarmCheckDelay = 0.2
}

-- ==========================================
-- 3. LIGHTWEIGHT GRAPHICAL UI
-- ==========================================
-- Clean up any existing instance of the UI
pcall(function()
    if CoreGui:FindFirstChild("IBdihP_SimpleUI") then
        CoreGui.IBdihP_SimpleUI:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IBdihP_SimpleUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Try parenting to CoreGui for safety, fallback to PlayerGui
local success = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 160)
MainFrame.Position = UDim2.new(0.05, 0, 0.35, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 32)
TitleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
TitleLabel.Text = "IBdihP | Simple Controls"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleLabel

-- Button Helper
local function createButton(text, positionY, defaultColor)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 32)
    button.Position = UDim2.new(0, 10, 0, positionY)
    button.BackgroundColor3 = defaultColor
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = false
    button.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    return button
end

local ColorOFF = Color3.fromRGB(180, 50, 50)
local ColorON = Color3.fromRGB(45, 160, 80)
local ColorCLOSE = Color3.fromRGB(70, 70, 90)

local FarmBtn = createButton("Auto Farm: OFF", 42, ColorOFF)
local TreasureBtn = createButton("Auto Chests: OFF", 80, ColorOFF)
local CloseBtn = createButton("Stop & Close UI", 118, ColorCLOSE)

-- UI Toggle Logic
FarmBtn.MouseButton1Click:Connect(function()
    Config.AutoFarm = not Config.AutoFarm
    FarmBtn.Text = Config.AutoFarm and "Auto Farm: ON" or "Auto Farm: OFF"
    FarmBtn.BackgroundColor3 = Config.AutoFarm and ColorON or ColorOFF
end)

TreasureBtn.MouseButton1Click:Connect(function()
    Config.AutoCollectTreasure = not Config.AutoCollectTreasure
    TreasureBtn.Text = Config.AutoCollectTreasure and "Auto Chests: ON" or "Auto Chests: OFF"
    TreasureBtn.BackgroundColor3 = Config.AutoCollectTreasure and ColorON or ColorOFF
end)

CloseBtn.MouseButton1Click:Connect(function()
    Config.AutoFarm = false
    Config.AutoCollectTreasure = false
    Config.ScriptRunning = false
    ScreenGui:Destroy()
    print("[IBdihP] Script stopped and UI closed.")
end)

-- Make UI Draggable
local dragging, dragInput, dragStart, startPos
TitleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleLabel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- 4. HELPER FUNCTIONS
-- ==========================================
local function getRoot()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
        if char.Humanoid.Health > 0 then
            return char.HumanoidRootPart
        end
    end
    return nil
end

local function firePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration or 0.2)
        prompt:InputHoldEnd()
    end
end

-- ==========================================
-- 5. TREASURE COLLECTOR LOOP
-- ==========================================
task.spawn(function()
    while Config.ScriptRunning do
        if Config.AutoCollectTreasure then
            local root = getRoot()
            if root then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if not Config.AutoCollectTreasure or not Config.ScriptRunning then break end
                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        local parentModel = obj.Parent
                        local name = parentModel and parentModel.Name or ""
                        
                        if name == "Standard Treasure" or name == "Royal Treasure" or name:find("Treasure") then
                            local targetPart = parentModel:IsA("BasePart") and parentModel 
                                or parentModel:FindFirstChildWhichIsA("BasePart")
                            
                            if targetPart then
                                root.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                                task.wait(0.3)
                                firePrompt(obj)
                                task.wait(0.3)
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
-- 6. ENEMY FARMER LOOP
-- ==========================================
local function getClosestEnemy(root)
    local closestEnemy = nil
    local shortestDistance = math.huge
    
    local searchScope = Workspace:FindFirstChild("Enemies") 
        or (Workspace:FindFirstChild("GameMap") and Workspace.GameMap:FindFirstChild("Enemies"))
        or Workspace

    for _, obj in ipairs(searchScope:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            if not Players:GetPlayerFromCharacter(obj) then
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
    end
    
    return closestEnemy
end

task.spawn(function()
    while Config.ScriptRunning do
        if Config.AutoFarm then
            local root = getRoot()
            if root then
                local targetEnemyRoot = getClosestEnemy(root)
                if targetEnemyRoot then
                    root.CFrame = targetEnemyRoot.CFrame * CFrame.new(0, 0, Config.FarmDistance)
                end
            end
        end
        task.wait(Config.FarmCheckDelay)
    end
end)

StarterGui:SetCore("SendNotification", {
    Title = "IBdihP Simple UI";
    Text = "Loaded! Use the menu on-screen to start farming.";
    Duration = 4;
})
