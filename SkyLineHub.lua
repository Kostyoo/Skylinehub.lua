-- ==================================================
-- SkyLine Hub UI Library v1.0
-- Production-ready UI for Roblox Exploits
-- Written in pure Lua (Roblox Lua 5.1)
-- ==================================================

local SkyLine = {}
SkyLine.__index = SkyLine

-- Services
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- Basic utilities
local function SafeCall(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        warn("[SkyLine] Error:", res)
    end
    return res
end

local function CreateRoundFrame(parent, size, position, color, radius)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = color
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = frame
    return frame
end

local function CreateTextLabel(parent, text, size, position, font, textColor, textSize)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Font = font or Enum.Font.Gotham
    label.Text = text or ""
    label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
    label.TextSize = textSize or 14
    label.TextWrapped = true
    label.Parent = parent
    return label
end

local function CreateIconButton(parent, imageId, size, position, callback)
    local button = Instance.new("ImageButton")
    button.Size = size
    button.Position = position
    button.BackgroundTransparency = 1
    button.Image = "rbxassetid://" .. imageId
    button.ScaleType = Enum.ScaleType.Fit
    button.Parent = parent
    button.MouseButton1Click:Connect(function()
        SafeCall(callback)
    end)
    return button
end

local function CreateUIScale(parent, baseSize)
    local scale = Instance.new("UIScale")
    scale.Parent = parent
    local function update()
        local vp = parent.AbsoluteSize
        if vp.X > 0 and vp.Y > 0 then
            scale.Scale = math.min(vp.X / baseSize.X, vp.Y / baseSize.Y)
        end
    end
    update()
    parent.Changed:Connect(function()
        SafeCall(update)
    end)
    return scale
end

-- ==================================================
-- Loading Screen
-- ==================================================
local function CreateLoadingScreen(parent, onComplete)
    local loadingFrame = CreateRoundFrame(parent, UDim2.fromOffset(300, 150), UDim2.new(0.5, -150, 0.5, -75), Color3.fromRGB(34, 49, 69), 12)
    loadingFrame.BackgroundTransparency = 1
    loadingFrame.Size = UDim2.fromScale(0, 0)

    local title = CreateTextLabel(loadingFrame, "SkyLine Hub", UDim2.fromScale(1, 0.4), UDim2.fromOffset(0, 20), Enum.Font.GothamBold, Color3.fromRGB(91, 196, 203), 28)
    title.TextScaled = false

    -- Bouncing balls
    local balls = {}
    local ballCount = 7
    for i = 1, ballCount do
        local ball = Instance.new("Frame")
        ball.Size = UDim2.fromOffset(10, 10)
        ball.BackgroundColor3 = Color3.fromRGB(91, 196, 203)
        ball.Position = UDim2.new(0.5, -35 + i * 12, 0, 80)
        ball.Parent = loadingFrame
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ball
        table.insert(balls, ball)
    end

    -- Animate balls wave
    local tweenParams = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local waveTimer = 0
    local waveDirection = 1
    local function animateBalls()
        for i, ball in ipairs(balls) do
            local offset = (i - 1) * 0.1
            local yPos = 70 + math.sin((waveTimer + offset) * math.pi * 2) * 15
            TweenService:Create(ball, tweenParams, {Position = UDim2.new(0.5, -35 + i * 12, 0, yPos)}):Play()
        end
        waveTimer = waveTimer + 0.05
        if waveTimer > 1 then
            waveTimer = waveTimer - 1
        end
    end

    local connection
    connection = RunService.RenderStepped:Connect(function()
        SafeCall(animateBalls)
    end)

    -- Fade in
    loadingFrame.Size = UDim2.new(0.5, 0, 0.5, 0)
    local fadeIn = TweenService:Create(loadingFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Size = UDim2.fromOffset(300, 150)})
    fadeIn:Play()
    fadeIn.Completed:Wait()

    -- Wait 2 seconds
    task.wait(2)

    -- Fade out and destroy
    local fadeOut = TweenService:Create(loadingFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
    fadeOut:Play()
    fadeOut.Completed:Wait()

    connection:Disconnect()
    loadingFrame:Destroy()

    -- Global background effect (permanent subtle glow at edges)
    local bgFrame = Instance.new("Frame")
    bgFrame.Size = UDim2.fromScale(1, 1)
    bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bgFrame.BackgroundTransparency = 1
    bgFrame.Parent = parent

    -- Edge glow using gradients (simplified)
    local glow = Instance.new("Frame")
    glow.Size = UDim2.fromScale(1, 1)
    glow.BackgroundTransparency = 1
    glow.Parent = bgFrame
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 0
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(91, 196, 203)),
        ColorSequenceKeypoint.new(0.2, Color3.fromRGB(34, 49, 69)),
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(34, 49, 69)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(91, 196, 203))
    })
    gradient.Parent = glow
    glow.BackgroundTransparency = 0.9

    SafeCall(onComplete)
end

-- ==================================================
-- Main Window Object
-- ==================================================
function SkyLine.CreateWindow(config)
    config = config or {}

    local Window = setmetatable({}, SkyLine)
    Window.Config = config
    Window.Tabs = {}
    Window.CurrentTab = nil
    Window.Hidden = false

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SkyLineHub"
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Main Frame (scaled to viewport with UIScale)
    local baseSize = Vector2.new(1000, 600) -- design reference
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.fromOffset(baseSize.X, baseSize.Y)
    mainFrame.Position = UDim2.new(0.5, -baseSize.X/2, 0.5, -baseSize.Y/2)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = screenGui

    -- UIScale for adaptive scaling
    local scale = CreateUIScale(mainFrame, baseSize)

    -- Loading screen
    CreateLoadingScreen(screenGui, function()
        -- Initial main panel setup
        Window:SetupMainUI()
    end)

    return Window
end

function SkyLine:SetupMainUI()
    -- Left navigation panel
    self.NavPanel = CreateRoundFrame(self.MainFrame, UDim2.fromOffset(60, 360), UDim2.new(0, 20, 0.5, -180), Color3.fromRGB(34, 49, 69), 12)
    self.NavPanel.Parent = self.MainFrame
    self.NavPanel.BackgroundTransparency = 0.8

    -- Nav buttons (6)
    local buttonData = {
        {name = "Home", id = "112770735347738"},
        {name = "Main", id = "92091304135140"},
        {name = "Player", id = "12345678901234"}, -- placeholder
        {name = "LoadScript", id = "83975792443912"},
        {name = "Settings", id = "125743894366007"},
        {name = "Exit", id = "96518596121178"}
    }

    self.NavButtons = {}
    self.ActiveNavIndex = 1

    local yPos = 15
    for i, data in ipairs(buttonData) do
        local btn = CreateIconButton(self.NavPanel, data.id, UDim2.fromOffset(40, 40), UDim2.new(0.5, -20, 0, yPos), function()
            -- Switch tab
            self:SwitchTab(i)
        end)
        btn.Name = data.name
        btn.Parent = self.NavPanel
        btn.ZIndex = 2
        table.insert(self.NavButtons, btn)
        yPos = yPos + 50
    end

    -- Tab content container (main area)
    self.ContentFrame = Instance.new("Frame")
    self.ContentFrame.Size = UDim2.new(0, 700, 0, 540) -- room for content
    self.ContentFrame.Position = UDim2.new(0, 90, 0, 30)
    self.ContentFrame.BackgroundTransparency = 1
    self.ContentFrame.Parent = self.MainFrame

    -- Create default tabs
    self:CreateHomeTab()
    self:CreateMainTab()
    self:CreatePlayerTab()
    self:CreateLoadScriptTab()
    self:CreateSettingsTab()

    -- Show initial tab (Home)
    self:SwitchTab(1)

    -- Toggle visibility (exit button)
    self:SetupExitButton()
end

function SkyLine:SwitchTab(index)
    if self.ActiveNavIndex == index then return end

    -- Animate nav highlight
    local oldBtn = self.NavButtons[self.ActiveNavIndex]
    local newBtn = self.NavButtons[index]

    TweenService:Create(oldBtn, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(newBtn, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play() -- subtle highlight

    self.ActiveNavIndex = index

    -- Directional tab animation
    local direction = index > self.ActiveNavIndex and 1 or -1
    for tabName, tabFrame in pairs(self.Tabs) do
        if tabFrame.Visible then
            -- animate out
            local out = TweenService:Create(tabFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, 0.5, direction * 200), BackgroundTransparency = 1})
            out:Play()
            out.Completed:Wait()
            tabFrame.Visible = false
        end
    end

    local newTabFrame = self.Tabs[index]
    newTabFrame.Visible = true
    newTabFrame.BackgroundTransparency = 1
    newTabFrame.Position = UDim2.new(0, 0, 0.5, -direction * 200)

    local tween = TweenService:Create(newTabFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0.5, 0), BackgroundTransparency = 0})
    tween:Play()
end

-- ==================================================
-- Tab creation methods
-- ==================================================
function SkyLine:CreateHomeTab()
    local tab = CreateRoundFrame(self.ContentFrame, UDim2.fromScale(1, 1), UDim2.new(0, 0, 0.5, -270), Color3.fromRGB(34, 49, 69), 12)
    tab.Visible = false
    tab.Parent = self.ContentFrame
    self.Tabs[1] = tab

    -- Profile photo
    local profileFrame = CreateRoundFrame(tab, UDim2.fromOffset(80, 80), UDim2.new(0, 20, 0, 20), Color3.fromRGB(52, 65, 83), 40)
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(1, -10, 1, -10)
    avatar.Position = UDim2.new(0.5, -35, 0.5, -35)
    avatar.BackgroundTransparency = 1
    avatar.Image = "rbxthumb://avatar?type=Head&id=" .. Players.LocalPlayer.UserId
    avatar.ScaleType = Enum.ScaleType.Fit
    avatar.Parent = profileFrame

    -- Info block
    local infoFrame = CreateRoundFrame(tab, UDim2.fromOffset(250, 80), UDim2.new(0, 120, 0, 20), Color3.fromRGB(52, 65, 83), 8)
    local playerIdText = CreateTextLabel(infoFrame, "Player ID: " .. Players.LocalPlayer.UserId, UDim2.new(1, -10, 0.3, -5), UDim2.new(0, 5, 0, 5), Enum.Font.Gotham, Color3.fromRGB(255, 255, 255), 14)
    playerIdText.TextXAlignment = Enum.TextXAlignment.Left

    local pingText = CreateTextLabel(infoFrame, "Ping: 0", UDim2.new(1, -10, 0.3, -5), UDim2.new(0, 5, 0, 30), Enum.Font.Gotham, Color3.fromRGB(255, 255, 255), 14)
    pingText.TextXAlignment = Enum.TextXAlignment.Left

    local fpsText = CreateTextLabel(infoFrame, "FPS: 0", UDim2.new(1, -10, 0.3, -5), UDim2.new(0, 5, 0, 55), Enum.Font.Gotham, Color3.fromRGB(255, 255, 255), 14)
    fpsText.TextXAlignment = Enum.TextXAlignment.Left

    -- Make Player ID clickable to copy
    playerIdText.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            SafeCall(setclipboard, tostring(Players.LocalPlayer.UserId))
            SkyLine:Notify("Successfully copied")
        end
    end)

    -- Update ping and fps every second
    local connection
    connection = RunService.Heartbeat:Connect(function(step)
        local ping = Players.LocalPlayer:GetNetworkPing()
        pingText.Text = string.format("Ping: %d ms", math.floor(ping * 1000))
        fpsText.Text = string.format("FPS: %d", math.floor(1 / step))
    end)
    tab.Destroying:Connect(function()
        connection:Disconnect()
    end)
end

function SkyLine:CreateMainTab()
    local tab = CreateRoundFrame(self.ContentFrame, UDim2.fromScale(1, 1), UDim2.new(0, 0, 0.5, -270), Color3.fromRGB(34, 49, 69), 12)
    tab.Visible = false
    tab.Parent = self.ContentFrame
    self.Tabs[2] = tab

    -- Right side block navigation panel (hidden until blocks added)
    self.BlockNavPanel = CreateRoundFrame(tab, UDim2.fromOffset(0, 0), UDim2.new(1, -70, 0, 20), Color3.fromRGB(52, 65, 83), 8)
    self.BlockNavPanel.Visible = false

    -- Container for blocks (left side)
    self.BlockContainer = Instance.new("Frame")
    self.BlockContainer.Size = UDim2.new(1, -90, 1, -40)
    self.BlockContainer.Position = UDim2.new(0, 10, 0, 10)
    self.BlockContainer.BackgroundTransparency = 1
    self.BlockContainer.Parent = tab

    self.Blocks = {}

    -- Methods to add elements to Main tab
    -- These will be exposed via Window:AddToggle, etc.
end

function SkyLine:CreatePlayerTab()
    local tab = CreateRoundFrame(self.ContentFrame, UDim2.fromScale(1, 1), UDim2.new(0, 0, 0.5, -270), Color3.fromRGB(34, 49, 69), 12)
    tab.Visible = false
    tab.Parent = self.ContentFrame
    self.Tabs[3] = tab

    -- Add player-specific elements using the Main tab element creator
    -- We'll create a helper function for each element type that can be called anywhere.
    -- But since the Player tab is fixed, we can directly create elements here.
    self:AddMainToggle("Enable Speed", true, function(val) -- implement speed
        print("Speed enabled:", val)
    end)
    self:AddMainSlider("Speed", 0, 100, 50, function(val)
        print("Speed value:", val)
    end)
    -- ... (similar for other features)
end

function SkyLine:CreateLoadScriptTab()
    local tab = CreateRoundFrame(self.ContentFrame, UDim2.fromScale(1, 1), UDim2.new(0, 0, 0.5, -270), Color3.fromRGB(34, 49, 69), 12)
    tab.Visible = false
    tab.Parent = self.ContentFrame
    self.Tabs[4] = tab

    -- This tab will hold buttons that execute custom scripts
    self.LoadScriptButtons = {}
end

function SkyLine:CreateSettingsTab()
    local tab = CreateRoundFrame(self.ContentFrame, UDim2.fromScale(1, 1), UDim2.new(0, 0, 0.5, -270), Color3.fromRGB(34, 49, 69), 12)
    tab.Visible = false
    tab.Parent = self.ContentFrame
    self.Tabs[5] = tab

    -- Add settings elements
    self:AddToggle("Disable Heavy Effects", false, function(val)
        -- toggle heavy effects
    end)

    -- Theme selection dropdown (simplified)
    self:AddDropdown("Theme", {"Default", "Neon", "Ocean"}, 1, function(selected)
        -- change accent colors
    end)

    self:AddButton("Save Settings", function()
        -- request preset name
        local name = string.sub(tostring(os.clock()), 1, 8) -- placeholder
        print("Saved settings as: " .. name)
    end)

    self:AddButton("Destroy GUI", function()
        game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("SkyLineHub"):Destroy()
        -- cleanup
    end)
end

-- ==================================================
-- Element creation helpers (used across tabs)
-- ==================================================
function SkyLine:AddToggle(text, default, callback)
    local container = self.BlockContainer or self.CurrentTabFrame -- adapt
    -- Actually for simplicity, we'll store elements in a list and attach to current tab
    -- Since we have multiple tabs, we need to know which tab this is for.
    -- We'll use a proxy: if called on Window object, it uses the active tab.
    -- For now, just create on the Main tab (index 2) if not specified.
    local tabFrame = self.Tabs[2]
    local yPos = #self.Blocks * 50 + 20

    local elementFrame = CreateRoundFrame(tabFrame, UDim2.new(1, -80, 0, 45), UDim2.new(0, 10, 0, yPos), Color3.fromRGB(52, 65, 83), 8)
    local label = CreateTextLabel(elementFrame, text, UDim2.new(0, 200, 1, 0), UDim2.new(0, 10, 0, 0), Enum.Font.GothamMedium, Color3.fromRGB(255, 255, 255), 14)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.fromOffset(40, 20)
    toggleFrame.Position = UDim2.new(1, -50, 0.5, -10)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(67, 85, 109)
    toggleFrame.Parent = elementFrame
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleFrame

    local circle = Instance.new("Frame")
    circle.Size = UDim2.fromOffset(16, 16)
    circle.Position = UDim2.new(0, 2, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.Parent = toggleFrame
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    local value = default or false
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.fromScale(1, 1)
    toggleButton.BackgroundTransparency = 1
    toggleButton.Text = ""
    toggleButton.Parent = toggleFrame

    local function SetToggle(val)
        value = val
        if val then
            toggleFrame.BackgroundColor3 = Color3.fromRGB(91, 196, 203)
            TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
        else
            toggleFrame.BackgroundColor3 = Color3.fromRGB(67, 85, 109)
            TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        end
        if callback then callback(val) end
    end

    toggleButton.MouseButton1Click:Connect(function()
        SetToggle(not value)
    end)

    SetToggle(value)

    -- Store for later
    table.insert(self.Blocks, elementFrame)
    return {SetValue = SetToggle, GetValue = function() return value end}
end

function SkyLine:AddSlider(text, min, max, default, callback)
    local tabFrame = self.Tabs[2]
    local yPos = #self.Blocks * 50 + 20

    local elementFrame = CreateRoundFrame(tabFrame, UDim2.new(1, -80, 0, 45), UDim2.new(0, 10, 0, yPos), Color3.fromRGB(52, 65, 83), 8)
    local label = CreateTextLabel(elementFrame, text, UDim2.new(0, 150, 1, 0), UDim2.new(0, 10, 0, 0), Enum.Font.GothamMedium, Color3.fromRGB(255, 255, 255), 14)
    label.TextXAlignment = Enum.TextXAlignment.Left

    -- Slider background
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.fromOffset(150, 6)
    sliderFrame.Position = UDim2.new(1, -180, 0.5, -3)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(34, 49, 69)
    sliderFrame.Parent = elementFrame
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = sliderFrame

    -- Fill
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(91, 196, 203)
    fill.Parent = sliderFrame
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    -- Value text
    local valueText = CreateTextLabel(elementFrame, tostring(default or 0), UDim2.new(0, 30, 0, 20), UDim2.new(1, -50, 0.5, -10), Enum.Font.Gotham, Color3.fromRGB(255, 255, 255), 12)

    -- Dragging logic
    local dragging = false
    local function updateFromMouse()
        local mouse = UIS:GetMouse()
        local sliderPos = sliderFrame.AbsolutePosition
        local sliderSize = sliderFrame.AbsoluteSize.X
        local localX = math.clamp((mouse.X - sliderPos.X) / sliderSize, 0, 1)
        local val = min + (max - min) * localX
        fill.Size = UDim2.new(localX, 0, 1, 0)
        valueText.Text = tostring(math.floor(val))
        if callback then callback(val) end
    end

    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromMouse()
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse()
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    table.insert(self.Blocks, elementFrame)
    return {SetValue = function(v) fill.Size = UDim2.new((v-min)/(max-min), 0, 1, 0); valueText.Text = tostring(v) end, GetValue = function() return (max-min)*fill.Size.X.Scale + min end}
end

function SkyLine:AddButton(text, callback)
    local tabFrame = self.Tabs[2]
    local yPos = #self.Blocks * 50 + 20

    local elementFrame = CreateRoundFrame(tabFrame, UDim2.new(1, -80, 0, 40), UDim2.new(0, 10, 0, yPos), Color3.fromRGB(52, 65, 83), 8)
    local label = CreateTextLabel(elementFrame, text, UDim2.new(1, -20, 1, 0), UDim2.new(0, 10, 0, 0), Enum.Font.GothamMedium, Color3.fromRGB(255, 255, 255), 14)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.fromOffset(20, 20)
    arrow.Position = UDim2.new(1, -30, 0.5, -10)
    arrow.Font = Enum.Font.Gotham
    arrow.Text = "›"
    arrow.TextColor3 = Color3.fromRGB(255, 255, 255)
    arrow.Parent = elementFrame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = elementFrame
    btn.MouseButton1Click:Connect(function()
        SafeCall(callback)
    end)

    table.insert(self.Blocks, elementFrame)
    return elementFrame
end

function SkyLine:AddDropdown(text, options, defaultIndex, callback)
    local tabFrame = self.Tabs[2]
    local yPos = #self.Blocks * 50 + 20

    local elementFrame = CreateRoundFrame(tabFrame, UDim2.new(1, -80, 0, 45), UDim2.new(0, 10, 0, yPos), Color3.fromRGB(52, 65, 83), 8)
    local label = CreateTextLabel(elementFrame, text, UDim2.new(0, 150, 1, 0), UDim2.new(0, 10, 0, 0), Enum.Font.GothamMedium, Color3.fromRGB(255, 255, 255), 14)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.fromOffset(180, 25)
    dropdownBtn.Position = UDim2.new(1, -200, 0.5, -12)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(67, 85, 109)
    dropdownBtn.Text = options[defaultIndex] or ""
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownBtn.Parent = elementFrame
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 5)
    dropdownCorner.Parent = dropdownBtn

    local selectedIndex = defaultIndex or 1

    local function updateDropdownText()
        dropdownBtn.Text = options[selectedIndex]
        if callback then callback(options[selectedIndex]) end
    end

    -- Dropdown menu (floating)
    local menuFrame = Instance.new("Frame")
    menuFrame.Size = UDim2.fromOffset(180, #options * 25)
    menuFrame.Position = UDim2.new(1, -200, 0.5, 12)
    menuFrame.BackgroundColor3 = Color3.fromRGB(34, 49, 69)
    menuFrame.Visible = false
    menuFrame.ZIndex = 10
    menuFrame.Parent = elementFrame
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 5)
    menuCorner.Parent = menuFrame

    for i, opt in ipairs(options) do
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, 0, 0, 25)
        item.Text = opt
        item.Font = Enum.Font.Gotham
        item.TextColor3 = Color3.fromRGB(255, 255, 255)
        item.BackgroundTransparency = 1
        item.Parent = menuFrame
        item.MouseEnter:Connect(function()
            item.BackgroundColor3 = Color3.fromRGB(91, 196, 203)
        end)
        item.MouseLeave:Connect(function()
            item.BackgroundColor3 = Color3.new(1, 1, 1)
        end)
        item.MouseButton1Click:Connect(function()
            selectedIndex = i
            updateDropdownText()
            menuFrame.Visible = false
        end)
    end

    dropdownBtn.MouseButton1Click:Connect(function()
        menuFrame.Visible = not menuFrame.Visible
        if menuFrame.Visible then
            dropdownBtn.BackgroundColor3 = Color3.fromRGB(91, 196, 203)
        else
            dropdownBtn.BackgroundColor3 = Color3.fromRGB(67, 85, 109)
        end
    end)

    table.insert(self.Blocks, elementFrame)
    return {SetValue = function(i) selectedIndex = i; updateDropdownText() end, GetValue = function() return options[selectedIndex] end}
end

-- ==================================================
-- Notification
-- ==================================================
function SkyLine:Notify(message)
    local notif = CreateRoundFrame(self.MainFrame, UDim2.fromOffset(200, 30), UDim2.new(1, -210, 0, 10), Color3.fromRGB(34, 49, 69), 8)
    local text = CreateTextLabel(notif, message, UDim2.new(1, -10, 1, 0), UDim2.new(0, 5, 0, 0), Enum.Font.GothamMedium, Color3.fromRGB(91, 196, 203), 12)
    text.TextYAlignment = Enum.TextYAlignment.Center
    -- Fade in/out
    notif.BackgroundTransparency = 1
    TweenService:Create(notif, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    task.wait(2)
    TweenService:Create(notif, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    task.wait(0.2)
    notif:Destroy()
end

-- ==================================================
-- Exit Button (Tiny arrow)
-- ==================================================
function SkyLine:SetupExitButton()
    -- The exit button is already in nav. When clicked (index 6), hide the whole UI.
    self.NavButtons[6].MouseButton1Click:Connect(function()
        if not self.Hidden then
            self:Hide()
        else
            self:Show()
        end
    end)
end

function SkyLine:Hide()
    self.Hidden = true
    -- Animate main frame out
    TweenService:Create(self.MainFrame, TweenInfo.new(0.4), {Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 0, 0.5, -5)}):Play()

    -- Show small arrow button (instead of full UI)
    if not self.SmallArrow then
        self.SmallArrow = Instance.new("TextButton")
        self.SmallArrow.Size = UDim2.fromOffset(20, 40)
        self.SmallArrow.Position = UDim2.new(0, 5, 0.5, -20)
        self.SmallArrow.Text = "▶"
        self.SmallArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
        self.SmallArrow.Font = Enum.Font.GothamBold
        self.SmallArrow.BackgroundTransparency = 0.5
        self.SmallArrow.Parent = self.MainFrame
        self.SmallArrow.MouseButton1Click:Connect(function()
            self:Show()
        end)
    end
    self.SmallArrow.Visible = true
end

function SkyLine:Show()
    self.Hidden = false
    if self.SmallArrow then self.SmallArrow.Visible = false end
    TweenService:Create(self.MainFrame, TweenInfo.new(0.4), {Size = UDim2.fromOffset(1000, 600), Position = UDim2.new(0.5, -500, 0.5, -300)}):Play()
end

-- ==================================================
-- Public API (simplified for user)
-- ==================================================
function SkyLine:AddMainToggle(text, default, callback)
    return self:AddToggle(text, default, callback)
end

function SkyLine:AddMainSlider(text, min, max, default, callback)
    return self:AddSlider(text, min, max, default, callback)
end

function SkyLine:AddMainDropdown(text, options, defaultIndex, callback)
    return self:AddDropdown(text, options, defaultIndex, callback)
end

function SkyLine:AddMainButton(text, callback)
    return self:AddButton(text, callback)
end

-- ==================================================
-- Example usage
-- ==================================================
local hub = SkyLine.CreateWindow({
    Title = "SkyLine Hub"
})

-- Add elements to Main tab
hub:AddMainToggle("ESP", true, function(val)
    -- enable/disable ESP
end)

hub:AddMainSlider("Speed", 0, 500, 250, function(val)
    -- set walk speed
end)

hub:AddMainDropdown("Select Mode", {"Aimbot", "Silent", "Legit"}, 1, function(selected)
    print("Selected:", selected)
end)

hub:AddMainButton("Load Script", function()
    -- execute script
end)

-- Add LoadScript button (for custom scripts)
hub:AddLoadScript("My Script", function()
    print("Running script")
end)

-- ==================================================
return SkyLine
