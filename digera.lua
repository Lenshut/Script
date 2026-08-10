--[[
    IBdihP Hub - Digimon Era Standalone (v4.2 - Dedicated Partner Ground-Truth Fix)
    Features:
      1. Auto Farm: Teleports Player + Partner -> Skills 1,2,3 -> Collect Drops -> Repeat
      2. Auto Chest: Teleports Player + Partner -> Open -> Kill Guard -> Re-open -> Repeat
      3. Open Map: Teleports to Carrots -> Collect -> Repeat
      4. Auto Potion: Reads InFight HealthText -> Uses Key 4 at Threshold -> Auto-Back when Empty
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

print("[IBdihP] Initializing v4.2 Standalone Engine...")

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
    OpenMap = false,
    AutoPotion = true,
    
    -- Delay Times & Thresholds
    FarmDelay = 1.0,
    ChestsDelay = 1.5,
    OpenMapDelay = 1.0,
    PotionThreshold = 60 -- Default 60% HP
}

local UIControllers = {}

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
MainFrame.Size = UDim2.new(0, 240, 0, 310)
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 32)
TitleLabel.BackgroundColor3 = Color3.fromRGB(32, 32, 45)
TitleLabel.Text = "IBdihP | Standalone Engine v4.2"
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
ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 320)
ContentContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ContentContainer

local ColorOFF = Color3.fromRGB(150, 45, 45)
local ColorON = Color3.fromRGB(45, 160, 80)
local ColorCLOSE = Color3.fromRGB(70, 70, 90)

-- ==========================================
-- 4. SWITCH SECTION BUILDERS
-- ==========================================
local function createSwitchSection(name, configToggleKey, configDelayKey, isThreshold, order)
    local SectionFrame = Instance.new("Frame")
    SectionFrame.Size = UDim2.new(1, -20, 0, 62)
    SectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    SectionFrame.LayoutOrder = order
    SectionFrame.Parent = ContentContainer

    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 6)
    SectionCorner.Parent = SectionFrame

    local SwitchLabel = Instance.new("TextLabel")
    SwitchLabel.Size = UDim2.new(0.6, 0, 0, 26)
    SwitchLabel.Position = UDim2.new(0, 10, 0, 6)
    SwitchLabel.BackgroundTransparency = 1
    SwitchLabel.Text = name
    SwitchLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
    SwitchLabel.TextSize = 12
    SwitchLabel.Font = Enum.Font.GothamBold
    SwitchLabel.TextXAlignment = Enum.TextXAlignment.Left
    SwitchLabel.Parent = SectionFrame

    local SwitchBG = Instance.new("TextButton")
    SwitchBG.Size = UDim2.new(0, 46, 0, 22)
    SwitchBG.Position = UDim2.new(1, -56, 0, 8)
    SwitchBG.BackgroundColor3 = Config[configToggleKey] and ColorON or ColorOFF
    SwitchBG.Text = ""
    SwitchBG.AutoButtonColor = false
    SwitchBG.Parent = SectionFrame

    local SwitchBGCorner = Instance.new("UICorner")
    SwitchBGCorner.CornerRadius = UDim.new(1, 0)
    SwitchBGCorner.Parent = SwitchBG

    local SwitchKnob = Instance.new("Frame")
    SwitchKnob.Size = UDim2.new(0, 18, 0, 18)
    SwitchKnob.Position = Config[configToggleKey] and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    SwitchKnob.AnchorPoint = Vector2.new(0, 0.5)
    SwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SwitchKnob.BorderSizePixel = 0
    SwitchKnob.Parent = SwitchBG

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = SwitchKnob

    local function setToggleState(state)
        Config[configToggleKey] = state
        SwitchBG.BackgroundColor3 = state and ColorON or ColorOFF
        SwitchKnob.Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        print("[IBdihP] " .. name .. " toggled: " .. tostring(state))
    end

    UIControllers[configToggleKey] = setToggleState

    SwitchBG.MouseButton1Click:Connect(function()
        setToggleState(not Config[configToggleKey])
    end)

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

    local initialPos = isThreshold and ((Config[configDelayKey] - 10) / 80) or ((Config[configDelayKey] - 1) / 4)
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new(math.clamp(initialPos, 0, 1), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(90, 110, 200)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBG

    local SliderFillCorner = Instance.new("UICorner")
    SliderFillCorner.CornerRadius = UDim.new(0, 4)
    SliderFillCorner.Parent = SliderFill

    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Size = UDim2.new(1, 0, 1, 0)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = isThreshold and string.format("HP Threshold: %d%%", Config[configDelayKey]) or string.format("Delay: %.1fs", Config[configDelayKey])
    SliderLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    SliderLabel.TextSize = 10
    SliderLabel.Font = Enum.Font.GothamBold
    SliderLabel.ZIndex = 2
    SliderLabel.Parent = SliderBG

    local isDraggingSlider = false
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
        if isThreshold then
            local val = math.floor(10 + (pos * 80) + 0.5)
            Config[configDelayKey] = val
            SliderFill.Size = UDim2.new(pos, 0, 1, 0)
            SliderLabel.Text = string.format("HP Threshold: %d%%", val)
        else
            local value = 1.0 + (pos * 4.0)
            value = math.floor(value * 10 + 0.5) / 10
            Config[configDelayKey] = value
            SliderFill.Size = UDim2.new(pos, 0, 1, 0)
            SliderLabel.Text = string.format("Delay: %.1fs", value)
        end
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

-- Create Menu Sections
createSwitchSection("Auto Farm", "AutoFarm", "FarmDelay", false, 1)
createSwitchSection("Auto Chest", "AutoChests", "ChestsDelay", false, 2)
createSwitchSection("Open Map", "OpenMap", "OpenMapDelay", false, 3)
createSwitchSection("Auto Potion", "AutoPotion", "PotionThreshold", true, 4)

-- Stop & Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(1, -20, 0, 30)
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
    Config.OpenMap = false
    Config.AutoPotion = false
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
-- 5. HELPER & CORE FUNCTIONS
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

-- Ground Truth: Grabs your Digimon models from Workspace.PlayersDigimons["Player_" .. UserId]
local function getMyDigimons()
    local digimonList = {}
    local playersDigimons = Workspace:FindFirstChild("PlayersDigimons")
    if playersDigimons then
        local myFolder = playersDigimons:FindFirstChild("Player_" .. tostring(LocalPlayer.UserId))
        if myFolder then
            for _, model in ipairs(myFolder:GetChildren()) do
                if model:IsA("Model") then
                    table.insert(digimonList, model)
                end
            end
        end
    end
    return digimonList
end

-- Teleports all your partner Digimon models instantly next to your character
local function teleportPartner(targetCFrame)
    for _, obj in ipairs(getMyDigimons()) do
        local partnerRoot = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
        if partnerRoot then
            partnerRoot.CFrame = targetCFrame * CFrame.new(3, 0, 2)
        end
    end
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

-- Clicks the in-game Back / Retreat button inside PlayerGui
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

-- Counts currently alive Digimon in your party using Ground Truth
local function getAliveDigimonCount()
    local count = 0
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        if LocalPlayer.Character.Humanoid.Health > 0 then
            count = count + 1
        end
    end

    for _, obj in ipairs(getMyDigimons()) do
        local hum = obj:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            count = count + 1
        end
    end
    return count
end

-- Reads active Digimon HP percentage from PlayerGui HealthText
local function getInFightHPPercentage()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return 100 end
    
    local mainUI = playerGui:FindFirstChild("Mobile_MainUI")
    if not mainUI then return 100 end
    
    local partyFrame = mainUI:FindFirstChild("PartyFrame")
    if not partyFrame then return 100 end
    
    local inFight = partyFrame:FindFirstChild("InFight")
    if not inFight then return 100 end
    
    local healthFrame = inFight:FindFirstChild("HealthFrame")
    if not healthFrame then return 100 end
    
    local healthText = healthFrame:FindFirstChild("HealthText")
    if not healthText or not healthText:IsA("TextLabel") then return 100 end
    
    local text = healthText.Text
    local cur, max = text:match("(%d+)%s*/%s*(%d+)")
    if cur and max and tonumber(max) > 0 then
        return (tonumber(cur) / tonumber(max)) * 100
    end
    
    local pct = text:match("(%d+)%%")
    if pct then
        return tonumber(pct)
    end
    
    return 100
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

-- Checks if an enemy model is a "Guard" type Digimon
local function isGuardEnemy(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name
    if name:find("Guard") then return true end
    
    for _, attr in ipairs({"Type", "EnemyType", "Rank", "Title", "Class", "Prefix"}) do
        local val = model:GetAttribute(attr)
        if type(val) == "string" and val:find("Guard") then
            return true
        end
    end
    return false
end

-- Post-Kill Drop Sweeper with 2.0s hard timeout
local function collectDropsSequence(root)
    local dropScope = Workspace:FindFirstChild("Drops") 
        or Workspace:FindFirstChild("LootDrops")
        or (Workspace:FindFirstChild("GameMap") and Workspace.GameMap:FindFirstChild("Drops"))

    local scanList = dropScope and dropScope:GetDescendants() or Workspace:GetChildren()
    local startTime = tick()

    for _, obj in ipairs(scanList) do
        if not Config.ScriptRunning or (not Config.AutoFarm and not Config.AutoChests) then break end
        if (tick() - startTime) > 2.0 then break end

        if obj:IsA("BasePart") and (obj.Name:find("Drop") or obj.Name:find("Loot") or obj:GetAttribute("Drop") or (obj.Parent and (obj.Parent.Name == "Drops" or obj.Parent.Name == "LootDrops"))) then
            root.CFrame = obj.CFrame
            teleportPartner(root.CFrame)
            local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
            if prompt and prompt.Enabled then
                firePrompt(prompt)
            end
            task.wait(0.15)
        end
    end
end

-- Ground Truth: Enforces 3x movement speed (48 WalkSpeed) on Player AND Partner Models
task.spawn(function()
    while Config.ScriptRunning do
        local targetSpeed = (Config.AutoFarm or Config.AutoChests) and 48 or 16
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = targetSpeed
        end
        for _, obj in ipairs(getMyDigimons()) do
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = targetSpeed
            end
        end
        task.wait(0.2)
    end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

-- ==========================================
-- 6. AUTO POTION & RETREAT LOOP
-- ==========================================
task.spawn(function()
    local lowHPChecks = 0
    while Config.ScriptRunning do
        -- 1. Check Emergency Retreat first (Alive Digimon == 1)
        if (Config.AutoFarm or Config.AutoChests) and getAliveDigimonCount() == 1 then
            print("[IBdihP] Emergency! Exactly 1 Alive Digimon remaining. Pressing Back...")
            if UIControllers.AutoFarm then UIControllers.AutoFarm(false) else Config.AutoFarm = false end
            if UIControllers.AutoChests then UIControllers.AutoChests(false) else Config.AutoChests = false end
            pressBackButton()
            task.wait(2.0)
        end

        -- 2. Check Auto Potion threshold
        if Config.AutoPotion and (Config.AutoFarm or Config.AutoChests) then
            local currentHP = getInFightHPPercentage()
            if currentHP <= Config.PotionThreshold then
                print(string.format("[IBdihP] Low HP detected (%d%% <= %d%%). Pressing Key 4 (Potion)...", math.floor(currentHP), Config.PotionThreshold))
                
                -- Press Key 4 (Hotbar Slot 4)
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Four, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Four, false, game)
                end)
                
                task.wait(0.6)
                local afterHP = getInFightHPPercentage()
                if afterHP <= Config.PotionThreshold then
                    lowHPChecks = lowHPChecks + 1
                    -- If HP remains low after 3 consecutive attempts (1.5s), potion is empty!
                    if lowHPChecks >= 3 then
                        print("[IBdihP] Potion empty/depleted! Triggering Emergency Retreat...")
                        if UIControllers.AutoFarm then UIControllers.AutoFarm(false) else Config.AutoFarm = false end
                        if UIControllers.AutoChests then UIControllers.AutoChests(false) else Config.AutoChests = false end
                        pressBackButton()
                        lowHPChecks = 0
                        task.wait(2.0)
                    end
                else
                    lowHPChecks = 0
                end
            else
                lowHPChecks = 0
            end
        end
        task.wait(0.5)
    end
end)

-- ==========================================
-- 7. TARGET SELECTORS
-- ==========================================
local function getClosestEnemy(root, requireGuard)
    local closestEnemy = nil
    local closestHum = nil
    local shortestDistance = math.huge
    
    local searchScope = Workspace:FindFirstChild("Enemies") 
        or (Workspace:FindFirstChild("GameMap") and Workspace.GameMap:FindFirstChild("Enemies"))
        or Workspace

    for _, obj in ipairs(searchScope:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            if not requireGuard or isGuardEnemy(obj) then
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
    end
    return closestEnemy, closestHum
end

local function getAvailableChest(root)
    local closestPart = nil
    local closestPrompt = nil
    local shortestDistance = math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local parentModel = obj.Parent
            local name = parentModel and parentModel.Name or ""
            
            if name == "Standard Treasure" or name == "Royal Treasure" or name:find("Treasure") then
                local targetPart = parentModel:IsA("BasePart") and parentModel 
                    or parentModel:FindFirstChildWhichIsA("BasePart")
                
                if targetPart then
                    local dist = (root.Position - targetPart.Position).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestPart = targetPart
                        closestPrompt = obj
                    end
                end
            end
        end
    end
    return closestPart, closestPrompt
end

local function getAvailableCarrot(root)
    local closestPart = nil
    local closestPrompt = nil
    local shortestDistance = math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Carrot" or obj.Name:find("Carrot") then
            local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
            if prompt and prompt.Enabled then
                local targetPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    local dist = (root.Position - targetPart.Position).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestPart = targetPart
                        closestPrompt = prompt
                    end
                end
            end
        end
    end
    return closestPart, closestPrompt
end

-- Core combat execution helper (Teleports partner continuously during fight)
local function battleEnemy(enemyRoot, enemyHum)
    local combatStart = tick()
    while Config.ScriptRunning and (Config.AutoFarm or Config.AutoChests) and enemyHum.Health > 0 and enemyRoot.Parent do
        if (tick() - combatStart) > 15.0 then break end
        local currentRoot = getRoot()
        if not currentRoot then break end
        
        currentRoot.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, Config.FarmDistance)
        teleportPartner(currentRoot.CFrame)
        fireSkills()
        task.wait(0.2)
    end
end

-- ==========================================
-- 8. AUTO FARM LOOP
-- ==========================================
task.spawn(function()
    while Config.ScriptRunning do
        if Config.AutoFarm then
            local root = getRoot()
            if root then
                local enemyRoot, enemyHum = getClosestEnemy(root, false)
                if enemyRoot and enemyHum then
                    battleEnemy(enemyRoot, enemyHum)
                    
                    task.wait(0.35)
                    local postKillRoot = getRoot()
                    if postKillRoot then
                        collectDropsSequence(postKillRoot)
                    end
                    
                    task.wait(Config.FarmDelay)
                end
            end
        end
        task.wait(0.2)
    end
end)

-- ==========================================
-- 9. AUTO CHEST LOOP (WITH GUARD KILL & AUTO-OFF)
-- ==========================================
task.spawn(function()
    while Config.ScriptRunning do
        if Config.AutoChests then
            local root = getRoot()
            if root then
                local chestPart, chestPrompt = getAvailableChest(root)
                if chestPart and chestPrompt then
                    -- 1. Teleport player and partner to chest and open it
                    root.CFrame = chestPart.CFrame + Vector3.new(0, 3, 0)
                    teleportPartner(root.CFrame)
                    task.wait(0.3)
                    firePrompt(chestPrompt)
                    
                    -- 2. Scan up to 1.5 seconds to detect if a Guard Digimon spawned
                    local waitStart = tick()
                    while (tick() - waitStart) < 1.5 do
                        local guardRoot, guardHum = getClosestEnemy(getRoot(), true)
                        if guardRoot and guardHum then
                            print("[IBdihP] Guard Digimon detected! Engaging...")
                            battleEnemy(guardRoot, guardHum)
                            task.wait(0.35)
                            collectDropsSequence(getRoot())
                            break
                        end
                        task.wait(0.2)
                    end
                    
                    -- 3. Teleport back to chest and re-open (if still present/enabled)
                    if chestPrompt and chestPrompt.Parent and chestPrompt.Enabled then
                        local returnRoot = getRoot()
                        if returnRoot then
                            returnRoot.CFrame = chestPart.CFrame + Vector3.new(0, 3, 0)
                            teleportPartner(returnRoot.CFrame)
                            task.wait(0.3)
                            firePrompt(chestPrompt)
                        end
                    end
                    
                    task.wait(Config.ChestsDelay)
                else
                    print("[IBdihP] No more unopened chests found. Disabling Auto Chest.")
                    if UIControllers.AutoChests then
                        UIControllers.AutoChests(false)
                    else
                        Config.AutoChests = false
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

-- ==========================================
-- 10. OPEN MAP LOOP (CARROTS WITH AUTO-OFF)
-- ==========================================
task.spawn(function()
    while Config.ScriptRunning do
        if Config.OpenMap then
            local root = getRoot()
            if root then
                local carrotPart, carrotPrompt = getAvailableCarrot(root)
                if carrotPart and carrotPrompt then
                    root.CFrame = carrotPart.CFrame + Vector3.new(0, 2, 0)
                    teleportPartner(root.CFrame)
                    task.wait(0.2)
                    firePrompt(carrotPrompt)
                    task.wait(Config.OpenMapDelay)
                else
                    print("[IBdihP] No more carrots found. Disabling Open Map.")
                    if UIControllers.OpenMap then
                        UIControllers.OpenMap(false)
                    else
                        Config.OpenMap = false
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

StarterGui:SetCore("SendNotification", {
    Title = "IBdihP v4.2 Loaded";
    Text = "Partner Ground-Truth & Potion Engine Active!";
    Duration = 4;
})
print("[IBdihP] Standalone Engine v4.2 running successfully.")
