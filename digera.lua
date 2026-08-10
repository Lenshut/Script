--[[
    IBdihP Hub - Digimon Era Standalone (v3.2 - Emergency Retreat & Slot 4 Heal)
    Logic:
      • Sequential Auto Farm (Skills 1, 2, 3)
      • Emergency Retreat: Clicks "Back" button if Alive Digimon <= 1
      • Auto-Heal: Uses hotbar Slot 4 (Key 4) during combat
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

print("[IBdihP] Initializing Dedicated Auto Farm v3.2...")

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
    AutoFarm = false,
    AutoHealSlot4 = true,       -- Automatically taps Slot 4 during combat
    EmergencyRetreat = true,    -- Taps "Back" button when Alive Digimon <= 1
    FarmDistance = 5,
    FarmDelay = 1.0,            -- Controlled by UI slider (1.0s to 5.0s)
    HealInterval = 3.0          -- Taps Slot 4 every 3 seconds while fighting
}

-- ==========================================
-- 3. BULLETPROOF UI MOUNTING (SWITCH UI)
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
MainFrame.Size = UDim2.new(0, 240, 0, 150)
MainFrame.Position = UDim2.new(0.05, 0, 0.35, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 32)
TitleLabel.BackgroundColor3 = Color3.fromRGB(32, 32, 45)
TitleLabel.Text = "IBdihP | Sequential Auto Farm"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleLabel

local ColorOFF = Color3.fromRGB(150, 45, 45)
local ColorON = Color3.fromRGB(45, 160, 80)
local ColorCLOSE = Color3.fromRGB(70, 70, 90)

-- Section Container
local SectionFrame = Instance.new("Frame")
SectionFrame.Size = UDim2.new(1, -20, 0, 62)
SectionFrame.Position = UDim2.new(0, 10, 0, 40)
SectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
SectionFrame.Parent = MainFrame

local SectionCorner = Instance.new("UICorner")
SectionCorner.CornerRadius = UDim.new(0, 6)
SectionCorner.Parent = SectionFrame

-- Switch Label
local SwitchLabel = Instance.new("TextLabel")
SwitchLabel.Size = UDim2.new(0.6, 0, 0, 26)
SwitchLabel.Position = UDim2.new(0, 10, 0, 6)
SwitchLabel.BackgroundTransparency = 1
SwitchLabel.Text = "Auto Farm"
SwitchLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
SwitchLabel.TextSize = 12
SwitchLabel.Font = Enum.Font.GothamBold
SwitchLabel.TextXAlignment = Enum.TextXAlignment.Left
SwitchLabel.Parent = SectionFrame

-- Switch Pill Background
local SwitchBG = Instance.new("TextButton")
SwitchBG.Size = UDim2.new(0, 46, 0, 22)
SwitchBG.Position = UDim2.new(1, -56, 0, 8)
SwitchBG.BackgroundColor3 = ColorOFF
SwitchBG.Text = ""
SwitchBG.AutoButtonColor = false
SwitchBG.Parent = SectionFrame

local SwitchBGCorner = Instance.new("UICorner")
SwitchBGCorner.CornerRadius = UDim.new(1, 0)
SwitchBGCorner.Parent = SwitchBG

-- Switch Knob (White Circle)
local SwitchKnob = Instance.new("Frame")
SwitchKnob.Size = UDim2.new(0, 18, 0, 18)
SwitchKnob.Position = UDim2.new(0, 2, 0.5, 0)
SwitchKnob.AnchorPoint = Vector2.new(0, 0.5)
SwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwitchKnob.BorderSizePixel = 0
SwitchKnob.Parent = SwitchBG

local KnobCorner = Instance.new("UICorner")
KnobCorner.CornerRadius = UDim.new(1, 0)
KnobCorner.Parent = SwitchKnob

-- Switch Click Logic
SwitchBG.MouseButton1Click:Connect(function()
    Config.AutoFarm = not Config.AutoFarm
    SwitchBG.BackgroundColor3 = Config.AutoFarm and ColorON or ColorOFF
    SwitchKnob.Position = Config.AutoFarm and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    print("[IBdihP] Auto Farm toggled: " .. tostring(Config.AutoFarm))
end)

-- Delay Slider Bar (1.0s - 5.0s)
local SliderBG = Instance.new("TextButton")
SliderBG.Size = UDim2.new(1, -20, 0, 18)
SliderBG.Position = UDim2.new(0, 10, 0, 36)
SliderBG.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
SliderBG.Text = ""
SliderBG.AutoButtonColor = false
SliderBG.Parent = SectionFrame

local SliderBGCorner = Instance.new("UICorner")
SliderBGCorner.CornerRadius = UDim.new(0, 4)
SliderBGCorner.Parent = SliderBG

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new((Config.FarmDelay - 1) / 4, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(90, 110, 200)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderBG

local SliderFillCorner = Instance.new("UICorner")
SliderFillCorner.CornerRadius = UDim.new(0, 4)
SliderFillCorner.Parent = SliderFill

local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(1, 0, 1, 0)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = string.format("Delay: %.1fs", Config.FarmDelay)
SliderLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
SliderLabel.TextSize = 10
SliderLabel.Font = Enum.Font.GothamBold
SliderLabel.ZIndex = 2
SliderLabel.Parent = SliderBG

local isDraggingSlider = false
local function updateSlider(input)
    local pos = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
    local value = 1.0 + (pos * 4.0)
    value = math.floor(value * 10 + 0.5) / 10
    Config.FarmDelay = value
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

-- Stop & Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(1, -20, 0, 32)
CloseBtn.Position = UDim2.new(0, 10, 0, 107)
CloseBtn.BackgroundColor3 = ColorCLOSE
CloseBtn.Text = "Stop & Close UI"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    Config.AutoFarm = false
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
-- 4. HELPER & CORE FUNCTIONS
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

-- Counts currently alive Digimon in your party / workspace
local function getAliveDigimonCount()
    local count = 0
    -- Check LocalPlayer character first
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        if LocalPlayer.Character.Humanoid.Health > 0 then
            count = count + 1
        end
    end

    -- Scan Workspace for friendly partner models owned by LocalPlayer
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local ownerAttr = obj:GetAttribute("Owner") or obj:GetAttribute("Player")
            if ownerAttr == LocalPlayer.Name or ownerAttr == LocalPlayer.UserId then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- Automatically clicks the "Back" / Retreat button inside PlayerGui
local function pressBackButton()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    for _, desc in ipairs(playerGui:GetDescendants()) do
        if desc:IsA("TextButton") or desc:IsA("ImageButton") then
            local btnName = desc.Name:lower()
            local btnText = desc:IsA("TextButton") and desc.Text:lower() or ""
            
            if btnName == "back" or btnName == "retreat" or btnText == "back" or btnText == "retreat" then
                if desc.Visible and desc.Active then
                    print("[IBdihP] Emergency Retreat: Clicking Back Button (" .. desc.Name .. ")")
                    pcall(function()
                        desc:Activate()
                    end)
                end
            end
        end
    end
end

-- Fires Digimon partner skills 1, 2, and 3 only (Slot 4 excluded)
local function fireSkills()
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("Events")
        local useMove = events and events:FindFirstChild("UseMove")
        if useMove then
            for i = 1, 3 do
                useMove:FireServer(i)
            end
        end
    end)

    for _, keyCode in ipairs({Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three}) do
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end
end

-- Uses Recovery Item equipped on Hotbar Slot 4 (Key 4)
local function useSlot4Item()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Four, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Four, false, game)
    end)
end

-- Post-Kill Drop Sweeper with 2.0s hard timeout
local function collectDropsSequence(root)
    local dropScope = Workspace:FindFirstChild("Drops") 
        or Workspace:FindFirstChild("LootDrops")
        or (Workspace:FindFirstChild("GameMap") and Workspace.GameMap:FindFirstChild("Drops"))

    local scanList = dropScope and dropScope:GetDescendants() or Workspace:GetChildren()
    local startTime = tick()

    for _, obj in ipairs(scanList) do
        if not Config.ScriptRunning or not Config.AutoFarm then break end
        if (tick() - startTime) > 2.0 then break end

        if obj:IsA("BasePart") and (obj.Name:find("Drop") or obj.Name:find("Loot") or obj:GetAttribute("Drop") or (obj.Parent and (obj.Parent.Name == "Drops" or obj.Parent.Name == "LootDrops"))) then
            root.CFrame = obj.CFrame
            local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
            if prompt and prompt.Enabled then
                firePrompt(prompt)
            end
            task.wait(0.15)
        end
    end
end

-- ==========================================
-- 5. EMERGENCY RETREAT MONITOR LOOP
-- ==========================================
task.spawn(function()
    while Config.ScriptRunning do
        if Config.AutoFarm and Config.EmergencyRetreat then
            local aliveCount = getAliveDigimonCount()
            -- If only 1 Digimon remains alive, automatically trigger retreat
            if aliveCount <= 1 and aliveCount > 0 then
                print("[IBdihP] Emergency! Alive Digimon count <= 1. Pressing Back...")
                Config.AutoFarm = false
                SwitchBG.BackgroundColor3 = ColorOFF
                SwitchKnob.Position = UDim2.new(0, 2, 0.5, 0)
                ToggleBtn.Text = "Auto Farm: OFF (Retreated)"
                
                pressBackButton()
                task.wait(2.0) -- Cooldown after retreating
            end
        end
        task.wait(0.5)
    end
end)

-- ==========================================
-- 6. SEQUENTIAL ENEMY FARMER & SKILL LOOP
-- ==========================================
local function getClosestEnemy(root)
    local closestEnemy = nil
    local closestHum = nil
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
                        closestHum = hum
                    end
                end
            end
        end
    end
    
    return closestEnemy, closestHum
end

task.spawn(function()
    local lastHealTime = 0

    while Config.ScriptRunning do
        if Config.AutoFarm then
            local root = getRoot()
            if root then
                local targetEnemyRoot, targetHum = getClosestEnemy(root)
                if targetEnemyRoot and targetHum then
                    local combatStart = tick()

                    -- 1. Battle enemy until dead (15s timeout fail-safe)
                    while Config.AutoFarm and Config.ScriptRunning and targetHum.Health > 0 and targetEnemyRoot.Parent do
                        if (tick() - combatStart) > 15.0 then break end
                        local currentRoot = getRoot()
                        if not currentRoot then break end
                        
                        -- Maintain combat position
                        currentRoot.CFrame = targetEnemyRoot.CFrame * CFrame.new(0, 0, Config.FarmDistance)
                        
                        -- Fire Skills 1, 2, 3
                        fireSkills()

                        -- Check and tap Slot 4 item at safe interval
                        if Config.AutoHealSlot4 and (tick() - lastHealTime) >= Config.HealInterval then
                            useSlot4Item()
                            lastHealTime = tick()
                        end

                        task.wait(0.2)
                    end
                    
                    -- 2. Enemy died: wait briefly for loot drops to spawn
                    task.wait(0.35)
                    
                    -- 3. Sweep and collect dropped loot items (capped at 2 seconds)
                    local postKillRoot = getRoot()
                    if postKillRoot then
                        collectDropsSequence(postKillRoot)
                    end
                    
                    -- 4. Wait slider delay before moving to the next target
                    task.wait(Config.FarmDelay)
                end
            end
        end
        task.wait(0.2)
    end
end)

StarterGui:SetCore("SendNotification", {
    Title = "IBdihP v3.2 Loaded";
    Text = "Sequential Farm, Emergency Retreat & Slot 4 Heal Active!";
    Duration = 4;
})
print("[IBdihP] Dedicated Auto Farm v3.2 running successfully.")
