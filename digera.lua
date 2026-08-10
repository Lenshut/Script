--[[
    IBdihP Hub - Digimon Era Standalone (v2.0 - Multi-Feature & Custom Delays)
    Features:
      • Auto Farm (with 1.0s - 5.0s Delay Slider)
      • Auto Collect Chests (with 1.0s - 5.0s Delay Slider)
      • Auto Collect Drops (with 1.0s - 5.0s Delay Slider)
      • Auto Collect Carrots (with 1.0s - 5.0s Delay Slider)
      • Lightweight, Draggable Custom UI (gethui + DisplayOrder 9999)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

print("[IBdihP] Initializing v2.0 Standalone...")

-- ==========================================
-- 1. LOBBY & EXECUTOR ACCESS CHECK
-- ==========================================
if game.PlaceId == 70863683083739 then
    StarterGui:SetCore("SendNotification", {
        Title = "IBdihP - Execution Warning";
        Text = "You are in the Lobby! Go into a gamemode place to use Auto Farm.";
        Duration = 6;
    })
    print("[IBdihP] Stopped: Player is in Lobby.")
    return
end

-- ==========================================
-- 2. CONFIGURATION & STATE
-- ==========================================
local Config = {
    ScriptRunning = true,
    FarmDistance = 5,
    
    -- Feature Toggles
    AutoFarm = false,
    AutoChests = false,
    AutoDrops = false,
    AutoCarrots = false,
    
    -- Delay Times (Seconds: 1.0 to 5.0)
    FarmDelay = 1.0,
    ChestsDelay = 1.5,
    DropsDelay = 1.0,
    CarrotsDelay = 1.5
}

-- ==========================================
-- 3. BULLETPROOF UI MOUNTING
-- ==========================================
pcall(function()
    local oldGui = CoreGui:FindFirstChild("IBdihP_SimpleUI") 
        or (gethui and gethui():FindFirstChild("IBdihP_SimpleUI"))
        or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("IBdihP_SimpleUI"))
    if oldGui then oldGui:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IBdihP_SimpleUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local targetParent = (gethui and pcall(gethui) and gethui()) or CoreGui
local success = pcall(function() ScreenGui.Parent = targetParent end)
if not success or not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 310)
MainFrame.Position = UDim2.new(0.05, 0, 0.28, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 32)
TitleLabel.BackgroundColor3 = Color3.fromRGB(32, 32, 45)
TitleLabel.Text = "IBdihP | Simple Controls v2"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleLabel

local ContentContainer = Instance.new("ScrollingFrame")
ContentContainer.Size = UDim2.new(1, 0, 1, -36)
ContentContainer.Position = UDim2.new(0, 0, 0, 34)
ContentContainer.BackgroundTransparency = 1
ContentContainer.BorderSizePixel = 0
ContentContainer.ScrollBarThickness = 4
ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 340)
ContentContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ContentContainer

local ColorOFF = Color3.fromRGB(180, 50, 50)
local ColorON = Color3.fromRGB(45, 160, 80)
local ColorCLOSE = Color3.fromRGB(70, 70, 90)

-- ==========================================
-- 4. UI COMPONENT BUILDERS (BUTTON + SLIDER)
-- ==========================================
local function createFeatureSection(name, configToggleKey, configDelayKey, order)
    local SectionFrame = Instance.new("Frame")
    SectionFrame.Size = UDim2.new(1, -20, 0, 58)
    SectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    SectionFrame.LayoutOrder = order
    SectionFrame.Parent = ContentContainer

    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 6)
    SectionCorner.Parent = SectionFrame

    -- Toggle Button
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, -12, 0, 26)
    ToggleBtn.Position = UDim2.new(0, 6, 0, 5)
    ToggleBtn.BackgroundColor3 = ColorOFF
    ToggleBtn.Text = name .. ": OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 11
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Parent = SectionFrame

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 4)
    BtnCorner.Parent = ToggleBtn

    ToggleBtn.MouseButton1Click:Connect(function()
        Config[configToggleKey] = not Config[configToggleKey]
        ToggleBtn.Text = Config[configToggleKey] and (name .. ": ON") or (name .. ": OFF")
        ToggleBtn.BackgroundColor3 = Config[configToggleKey] and ColorON or ColorOFF
        print("[IBdihP] " .. name .. " toggled: " .. tostring(Config[configToggleKey]))
    end)

    -- Delay Slider Bar
    local SliderBG = Instance.new("TextButton")
    SliderBG.Size = UDim2.new(1, -12, 0, 18)
    SliderBG.Position = UDim2.new(0, 6, 0, 35)
    SliderBG.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    SliderBG.Text = ""
    SliderBG.AutoButtonColor = false
    SliderBG.Parent = SectionFrame

    local SliderBGCorner = Instance.new("UICorner")
    SliderBGCorner.CornerRadius = UDim.new(0, 4)
    SliderBGCorner.Parent = SliderBG

    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((Config[configDelayKey] - 1) / 4, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(90, 110, 200)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBG

    local SliderFillCorner = Instance.new("UICorner")
    SliderFillCorner.CornerRadius = UDim.new(0, 4)
    SliderFillCorner.Parent = SliderFill

    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Size = UDim2.new(1, 0, 1, 0)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = string.format("Delay: %.1fs", Config[configDelayKey])
    SliderLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    SliderLabel.TextSize = 10
    SliderLabel.Font = Enum.Font.GothamBold
    SliderLabel.ZIndex = 2
    SliderLabel.Parent = SliderBG

    -- Slider Drag Calculation
    local isDraggingSlider = false
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
        local value = 1.0 + (pos * 4.0) -- Maps 0..1 to 1s..5s
        value = math.floor(value * 10 + 0.5) / 10 -- Round to 1 decimal place
        Config[configDelayKey] = value
        SliderFill.Size = UDim2.new((value - 1) / 4, 0, 1, 0)
        SliderLabel.Text = string.format("Delay: %.1fs", value)
    end

    SliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = true
            updateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
end

-- Create Sections
createFeatureSection("Auto Farm", "AutoFarm", "FarmDelay", 1)
createFeatureSection("Auto Chests", "AutoChests", "ChestsDelay", 2)
createFeatureSection("Auto Drops", "AutoDrops", "DropsDelay", 3)
createFeatureSection("Auto Carrots", "AutoCarrots", "CarrotsDelay", 4)

-- Stop & Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(1, -20, 0, 32)
CloseBtn.BackgroundColor3 = ColorCLOSE
CloseBtn.Text = "Stop & Close UI"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.LayoutOrder = 10
CloseBtn.Parent = ContentContainer

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    Config.AutoFarm = false
    Config.AutoChests = false
    Config.AutoDrops = false
    Config.AutoCarrots = false
    Config.ScriptRunning = false
    ScreenGui:Destroy()
    print("[IBdihP] Script stopped and UI closed.")
end)

-- Draggable Title Logic
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
-- 5. HELPER FUNCTIONS
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
-- 6. AUTO CHESTS / TREASURE LOOP
-- ==========================================
task.spawn(function()
    while Config.ScriptRunning do
        if Config.AutoChests then
            local root = getRoot()
            if root then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if not Config.AutoChests or not Config.ScriptRunning then break end
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
        task.wait(Config.ChestsDelay)
    end
end)

-- ==========================================
-- 7. AUTO DROPS / LOOT LOOP
-- ==========================================
task.spawn(function()
    while Config.ScriptRunning do
        if Config.AutoDrops then
            local root = getRoot()
            if root then
                -- Check standard Drops/LootDrops folders first, then fallback to Workspace
                local dropScope = Workspace:FindFirstChild("Drops") 
                    or Workspace:FindFirstChild("LootDrops")
                    or (Workspace:FindFirstChild("GameMap") and Workspace.GameMap:FindFirstChild("Drops"))
                    or Workspace

                for _, obj in ipairs(dropScope:GetDescendants()) do
                    if not Config.AutoDrops or not Config.ScriptRunning then break end
                    
                    -- Look for dropped items (Models or BaseParts with Drop names/attributes)
                    if obj:IsA("BasePart") and (obj.Name:find("Drop") or obj.Name:find("Loot") or obj:GetAttribute("Drop") or obj.Parent.Name == "Drops" or obj.Parent.Name == "LootDrops") then
                        root.CFrame = obj.CFrame + Vector3.new(0, 2, 0)
                        
                        -- Fire prompt if it requires holding, otherwise touching BasePart collects it
                        local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                        if prompt and prompt.Enabled then
                            firePrompt(prompt)
                        end
                        task.wait(0.15)
                    end
                end
            end
        end
        task.wait(Config.DropsDelay)
    end
end)

-- ==========================================
-- 8. AUTO CARROTS LOOP
-- ==========================================
task.spawn(function()
    while Config.ScriptRunning do
        if Config.AutoCarrots then
            local root = getRoot()
            if root then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if not Config.AutoCarrots or not Config.ScriptRunning then break end
                    
                    -- Look for Carrots scattered around the map
                    if obj.Name == "Carrot" or obj.Name:find("Carrot") then
                        local targetPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                        if targetPart then
                            root.CFrame = targetPart.CFrame + Vector3.new(0, 2, 0)
                            local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
                            if prompt and prompt.Enabled then
                                firePrompt(prompt)
                            end
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
        task.wait(Config.CarrotsDelay)
    end
end)

-- ==========================================
-- 9. ENEMY FARMER LOOP
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
        task.wait(Config.FarmDelay)
    end
end)

StarterGui:SetCore("SendNotification", {
    Title = "IBdihP v2 Loaded";
    Text = "All features & custom delay sliders active!";
    Duration = 4;
})
print("[IBdihP] v2.0 UI mounted and running successfully.")
