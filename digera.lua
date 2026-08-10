--[[
    IBdihP Hub - Digimon Era Standalone (v3.4 - Guard Priority & Auto Chest Switch)
    Logic:
      • Priority 1: Guard Enemy Alive -> Lock On & Kill (Skills 1, 2, 3) -> Collect Drops
      • Priority 2: Auto Chests ON -> Open Chest -> Wait for Guard -> Kill Guard -> Collect Drops
      • Priority 3: Auto Farm ON -> Farm Normal Enemies -> Collect Drops
      • Emergency Retreat: Clicks "Back" button immediately if Alive Digimon == 1
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

print("[IBdihP] Initializing Dedicated Auto Farm & Chests v3.4...")

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
    AutoChests = false,
    EmergencyRetreat = true,
    FarmDistance = 5,
    FarmDelay = 1.0,        -- Controlled by Farm UI slider (1.0s to 5.0s)
    ChestsDelay = 1.5       -- Controlled by Chests UI slider (1.0s to 5.0s)
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
MainFrame.Size = UDim2.new(0, 240, 0, 215)
MainFrame.Position = UDim2.new(0.05, 0, 0.30, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 32)
TitleLabel.BackgroundColor3 = Color3.fromRGB(32, 32, 45)
TitleLabel.Text = "IBdihP | Sequential Farm & Chests"
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

-- ==========================================
-- 4. SWITCH SECTION BUILDER
-- ==========================================
local function createSwitchSection(name, configToggleKey, configDelayKey, posY)
    local SectionFrame = Instance.new("Frame")
    SectionFrame.Size = UDim2.new(1, -20, 0, 62)
    SectionFrame.Position = UDim2.new(0, 10, 0, posY)
    SectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    SectionFrame.Parent = MainFrame

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
    SwitchBG.BackgroundColor3 = ColorOFF
    SwitchBG.Text = ""
    SwitchBG.AutoButtonColor = false
    SwitchBG.Parent = SectionFrame

    local SwitchBGCorner = Instance.new("UICorner")
    SwitchBGCorner.CornerRadius = UDim.new(1, 0)
    SwitchBGCorner.Parent = SwitchBG

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

    SwitchBG.MouseButton1Click:Connect(function()
        Config[configToggleKey] = not Config[configToggleKey]
        SwitchBG.BackgroundColor3 = Config[configToggleKey] and ColorON or ColorOFF
        SwitchKnob.Position = Config[configToggleKey] and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        print("[IBdihP] " .. name .. " toggled: " .. tostring(Config[configToggleKey]))
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

    local isDraggingSlider = false
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
        local value = 1.0 + (pos * 4.0)
        value = math.floor(value * 10 + 0.5) / 10
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

    return SwitchBG, SwitchKnob
end

local FarmSwitchBG, FarmSwitchKnob = createSwitchSection("Auto Farm", "AutoFarm", "FarmDelay", 40)
local ChestsSwitchBG, ChestsSwitchKnob = createSwitchSection("Auto Chests", "AutoChests", "ChestsDelay", 108)

-- Stop & Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(1, -20, 0, 30)
CloseBtn.Position = UDim2.new(0, 10, 0, 176)
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
    Config.AutoChests = false
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

local function getAliveDigimonCount()
    local count = 0
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        if LocalPlayer.Character.Humanoid.Health > 0 then
            count = count + 1
        end
    end

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

-- Fires Digimon partner skills 1, 2, and 3 only
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
            local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
            if prompt and prompt.Enabled then
                firePrompt(prompt)
            end
            task.wait(0.15)
        end
    end
end

-- ==========================================
-- 6. TARGET SELECTORS (GUARD / CHEST / ENEMY)
-- ==========================================
local function getGuardEnemy(root)
    local closestGuard = nil
    local closestHum = nil
    local shortestDistance = math.huge
    
    local searchScope = Workspace:FindFirstChild("Enemies") 
        or (Workspace:FindFirstChild("GameMap") and Workspace.GameMap:FindFirstChild("Enemies"))
        or Workspace

    for _, obj in ipairs(searchScope:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character and isGuardEnemy(obj) then
            if not Players:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local enemyRoot = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                
                if hum and hum.Health > 0 and enemyRoot then
                    local dist = (root.Position - enemyRoot.Position).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestGuard = enemyRoot
                        closestHum = hum
                    end
                end
            end
        end
    end
    return closestGuard, closestHum
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

-- Combat executor (handles both normal enemies and Guards)
local function battleEnemy(enemyRoot, enemyHum, targetLabel)
    local combatStart = tick()
    print("[IBdihP] Engaging Target: " .. targetLabel .. " (" .. enemyRoot.Parent.Name .. ")")

    while Config.ScriptRunning and (Config.AutoFarm or Config.AutoChests) and enemyHum.Health > 0 and enemyRoot.Parent do
        if (tick() - combatStart) > 15.0 then break end
        
        -- Emergency Retreat Check
        if Config.EmergencyRetreat and getAliveDigimonCount() == 1 then
            print("[IBdihP] Emergency! Alive Digimon == 1. Retreating from combat...")
            Config.AutoFarm = false
            Config.AutoChests = false
            FarmSwitchBG.BackgroundColor3 = ColorOFF
            FarmSwitchKnob.Position = UDim2.new(0, 2, 0.5, 0)
            ChestsSwitchBG.BackgroundColor3 = ColorOFF
            ChestsSwitchKnob.Position = UDim2.new(0, 2, 0.5, 0)
            
            pressBackButton()
            task.wait(2.0)
            return false
        end

        local currentRoot = getRoot()
        if not currentRoot then break end
        
        currentRoot.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, Config.FarmDistance)
        fireSkills()
        task.wait(0.2)
    end
    
    task.wait(0.35)
    local postKillRoot = getRoot()
    if postKillRoot then
        collectDropsSequence(postKillRoot)
    end
    return true
end

-- ==========================================
-- 7. MASTER WORKER LOOP (PRIORITY ENGINE)
-- ==========================================
task.spawn(function()
    while Config.ScriptRunning do
        if Config.AutoFarm or Config.AutoChests then
            -- 0. Standalone Emergency Retreat check before selecting targets
            if Config.EmergencyRetreat and getAliveDigimonCount() == 1 then
                print("[IBdihP] Emergency Retreat Triggered (Alive Digimon == 1).")
                Config.AutoFarm = false
                Config.AutoChests = false
                FarmSwitchBG.BackgroundColor3 = ColorOFF
                FarmSwitchKnob.Position = UDim2.new(0, 2, 0.5, 0)
                ChestsSwitchBG.BackgroundColor3 = ColorOFF
                ChestsSwitchKnob.Position = UDim2.new(0, 2, 0.5, 0)
                
                pressBackButton()
                task.wait(2.0)
            else
                local root = getRoot()
                if root then
                    -- PRIORITY 1: Guard Digimon present anywhere -> Kill at all costs!
                    local guardRoot, guardHum = getGuardEnemy(root)
                    if guardRoot and guardHum then
                        battleEnemy(guardRoot, guardHum, "Guard Digimon [PRIORITY]")
                        task.wait(Config.FarmDelay)
                    else
                        -- PRIORITY 2: Auto Chests ON -> Open chest and wait for Guard to spawn
                        if Config.AutoChests then
                            local chestPart, chestPrompt = getAvailableChest(root)
                            if chestPart and chestPrompt then
                                root.CFrame = chestPart.CFrame + Vector3.new(0, 3, 0)
                                task.wait(0.3)
                                firePrompt(chestPrompt)
                                print("[IBdihP] Chest opened. Waiting for Guard to spawn...")
                                
                                -- Wait up to 2.0s for a Guard Digimon to spawn
                                local waitStart = tick()
                                while (tick() - waitStart) < 2.0 do
                                    local gRoot, gHum = getGuardEnemy(getRoot())
                                    if gRoot and gHum then
                                        battleEnemy(gRoot, gHum, "Chest Guard Digimon")
                                        break
                                    end
                                    task.wait(0.2)
                                end
                                task.wait(Config.ChestsDelay)
                            end
                        -- PRIORITY 3: Standard Auto Farm ON -> Farm normal closest enemies
                        elseif Config.AutoFarm then
                            local enemyRoot, enemyHum = getClosestEnemy(root)
                            if enemyRoot and enemyHum then
                                battleEnemy(enemyRoot, enemyHum, "Normal Enemy")
                                task.wait(Config.FarmDelay)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

StarterGui:SetCore("SendNotification", {
    Title = "IBdihP v3.4 Loaded";
    Text = "Guard Priority & Chest Switch Active!";
    Duration = 4;
})
print("[IBdihP] Dedicated Auto Farm & Chests v3.4 running successfully.")
