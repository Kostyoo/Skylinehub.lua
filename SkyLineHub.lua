-- ==================================================
-- SkyLine Hub UI Library v1.1 (Fixed & Enhanced)
-- Production-ready UI for Roblox Exploits
-- ==================================================

local SkyLine = {}
SkyLine.__index = SkyLine

-- Services
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Utilities
local function SafeCall(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then warn("[SkyLine] Error:", res) end
    return ok, res
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
    parent.Changed:Connect(update)
    return scale
end

-- ==================================================
-- КРАСИВЫЙ ЗАГРУЗОЧНЫЙ ЭКРАН (Enhanced)
-- ==================================================
local function CreateLoadingScreen(parent, onComplete)
    -- Фон затемнения
    local bgFrame = Instance.new("Frame")
    bgFrame.Size = UDim2.fromScale(1, 1)
    bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bgFrame.BackgroundTransparency = 0
    bgFrame.Parent = parent

    -- Центральное окно с градиентом и свечением
    local loadingFrame = Instance.new("Frame")
    loadingFrame.Size = UDim2.fromOffset(0, 0)
    loadingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    loadingFrame.BackgroundColor3 = Color3.fromRGB(34, 49, 69)
    loadingFrame.BackgroundTransparency = 1
    loadingFrame.Parent = bgFrame
    loadingFrame.ZIndex = 10

    -- Градиент на фоне
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 45
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 65, 83)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 49, 69))
    })
    gradient.Parent = loadingFrame

    -- Светящаяся обводка (UIStroke)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(91, 196, 203)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = loadingFrame

    -- Скругление
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = loadingFrame

    -- Заголовок с градиентом
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0.3, 0)
    title.Position = UDim2.new(0, 10, 0, 25)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "SkyLine Hub"
    title.TextSize = 35
    title.TextColor3 = Color3.fromRGB(91, 196, 203)
    title.Parent = loadingFrame
    title.ZIndex = 2

    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color = Color3.fromRGB(91, 196, 203)
    titleStroke.Thickness = 1
    titleStroke.Transparency = 0.2
    titleStroke.Parent = title

    -- Текст "Загрузка..."
    local loadingText = CreateTextLabel(loadingFrame, "Загрузка...", UDim2.new(1, 0, 0.2, 0), UDim2.new(0, 0, 0, 130), Enum.Font.Gotham, Color3.fromRGB(255, 255, 255), 14)
    loadingText.TextTransparency = 0.5

    -- Анимированные шарики (9 штук)
    local balls = {}
    local ballCount = 9
    for i = 1, ballCount do
        local ball = Instance.new("Frame")
        ball.Size = UDim2.fromOffset(12, 12)
        ball.Position = UDim2.new(0.5, -48 + i * 12, 0, 180)
        ball.BackgroundColor3 = Color3.fromRGB(91, 196, 203)
        ball.Parent = loadingFrame
        ball.ZIndex = 2

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(1, 0)
        bCorner.Parent = ball

        -- Свечение шариков
        local bStroke = Instance.new("UIStroke")
        bStroke.Color = Color3.fromRGB(91, 196, 203)
        bStroke.Thickness = 1
        bStroke.Transparency = 0.4
        bStroke.Parent = ball

        table.insert(balls, ball)
    end

    -- Анимация появления (Scale + Transparency)
    loadingFrame.Size = UDim2.fromOffset(340, 220)
    loadingFrame.BackgroundTransparency = 1
    TweenService:Create(loadingFrame, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.1}):Play()
    TweenService:Create(loadingFrame, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(340, 220)}):Play()

    -- Волна из шариков
    local waveTimer = 0
    local waveConnection
    waveConnection = RunService.RenderStepped:Connect(function()
        waveTimer = waveTimer + 0.03
        for i, ball in ipairs(balls) do
            local yPos = 180 + math.sin((waveTimer + i * 0.2) * math.pi * 2) * 12
            TweenService:Create(ball, TweenInfo.new(0.2), {Position = UDim2.new(0.5, -48 + i * 12, 0, yPos)}):Play()
        end
    end)

    -- Небольшая задержка для красоты
    task.wait(2.5)

    -- Убираем загрузочный экран
    waveConnection:Disconnect()
    TweenService:Create(loadingFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
    task.wait(0.4)
    bgFrame:Destroy()

    -- Вызываем создание главного окна
    SafeCall(onComplete)
end

-- ==================================================
-- MAIN WINDOW
-- ==================================================
function SkyLine.CreateWindow(config)
    config = config or {}
    local Window = setmetatable({}, SkyLine)
    Window.Config = config
    Window.Tabs = {}
    Window.Hidden = false
    Window.Blocks = {}

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SkyLineHub"
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Основной фрейм
    local baseSize = Vector2.new(1000, 600)
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.fromOffset(baseSize.X, baseSize.Y)
    mainFrame.Position = UDim2.new(0.5, -baseSize.X/2, 0.5, -baseSize.Y/2)
    mainFrame.BackgroundColor3 = Color3.fromRGB(34, 49, 69)
    mainFrame.BackgroundTransparency = 0
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    mainFrame.Visible = false -- Скроем до загрузки

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 15)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(52, 65, 83)
    mainStroke.Thickness = 2
    mainStroke.Parent = mainFrame

    -- Сохраняем ссылки
    Window.MainFrame = mainFrame
    Window.ScreenGui = screenGui

    -- UIScale для адаптивности
    CreateUIScale(mainFrame, baseSize)

    -- Загрузка (красивый экран)
    CreateLoadingScreen(screenGui, function()
        mainFrame.Visible = true
        Window:SetupMainUI()
    end)

    return Window
end

function SkyLine:SetupMainUI()
    -- Боковая панель
    self.NavPanel = CreateRoundFrame(self.MainFrame, UDim2.fromOffset(60, 360), UDim2.new(0, 20, 0.5, -180), Color3.fromRGB(52, 65, 83), 12)
    self.NavPanel.ZIndex = 2

    -- Кнопки навигации
    local buttonData = {
        {name = "Home", id = "112770735347738"},
        {name = "Main", id = "92091304135140"},
        {name = "Player", id = "12345678901234"},
        {name = "LoadScript", id = "83975792443912"},
        {name = "Settings", id = "125743894366007"},
        {name = "Exit", id = "96518596121178"}
    }

    self.NavButtons = {}
    self.ActiveNavIndex = 1

    local yPos = 15
    for i, data in ipairs(buttonData) do
        local btn = Instance.new("ImageButton")
        btn.Size = UDim2.fromOffset(40, 40)
        btn.Position = UDim2.new(0.5, -20, 0, yPos)
        btn.BackgroundTransparency = 1
        btn.Image = "rbxassetid://" .. data.id
        btn.ScaleType = Enum.ScaleType.Fit
        btn.Parent = self.NavPanel
        btn.ZIndex = 3
        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(i)
        end)
        table.insert(self.NavButtons, btn)
        yPos = yPos + 50
    end

    -- Контент
    self.ContentFrame = Instance.new("Frame")
    self.ContentFrame.Size = UDim2.new(0, 700, 0, 540)
    self.ContentFrame.Position = UDim2.new(0, 90, 0, 30)
    self.ContentFrame.BackgroundTransparency = 1
    self.ContentFrame.Parent = self.MainFrame

    -- Создаем вкладки
    self:CreateHomeTab()
    self:CreateMainTab()
    self:CreatePlayerTab()
    self:CreateLoadScriptTab()
    self:CreateSettingsTab()

    -- Показываем первую вкладку
    self:SwitchTab(1)

    -- Кнопка выхода (стрелочка)
    self:SetupExitButton()
end

function SkyLine:SwitchTab(index)
    if self.ActiveNavIndex == index then return end
    local oldBtn = self.NavButtons[self.ActiveNavIndex]
    local newBtn = self.NavButtons[index]

    TweenService:Create(oldBtn, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(newBtn, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()

    self.ActiveNavIndex = index
    local direction = index > self.ActiveNavIndex and 1 or -1

    for tabName, tabFrame in pairs(self.Tabs) do
        if tabFrame.Visible then
            TweenService:Create(tabFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
                {Position = UDim2.new(0, 0, 0.5, direction * 200), BackgroundTransparency = 1}):Play()
            task.wait(0.05)
            tabFrame.Visible = false
        end
    end

    local newTabFrame = self.Tabs[index]
    newTabFrame.Visible = true
    newTabFrame.BackgroundTransparency = 1
    newTabFrame.Position = UDim2.new(0, 0, 0.5, -direction * 200)
    TweenService:Create(newTabFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        {Position = UDim2.new(0, 0, 0.5, 0), BackgroundTransparency = 0}):Play()
end

-- Вкладки
function SkyLine:CreateHomeTab()
    local tab = CreateRoundFrame(self.ContentFrame, UDim2.fromScale(1, 1), UDim2.new(0, 0, 0.5, -270), Color3.fromRGB(52, 65, 83), 12)
    tab.Visible = false
    tab.Parent = self.ContentFrame
    self.Tabs[1] = tab

    local profileFrame = CreateRoundFrame(tab, UDim2.fromOffset(80, 80), UDim2.new(0, 20, 0, 20), Color3.fromRGB(34, 49, 69), 40)
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(1, -10, 1, -10)
    avatar.Position = UDim2.new(0.5, -35, 0.5, -35)
    avatar.BackgroundTransparency = 1
    avatar.Image = "rbxthumb://avatar?type=Head&id=" .. Players.LocalPlayer.UserId
    avatar.ScaleType = Enum.ScaleType.Fit
    avatar.Parent = profileFrame

    local infoFrame = CreateRoundFrame(tab, UDim2.fromOffset(250, 80), UDim2.new(0, 120, 0, 20), Color3.fromRGB(34, 49, 69), 8)
    local playerIdText = CreateTextLabel(infoFrame, "ID: " .. Players.LocalPlayer.UserId, UDim2.new(1, -10, 0.3, -5), UDim2.new(0, 5, 0, 5), Enum.Font.Gotham, Color3.fromRGB(255, 255, 255), 14)
    playerIdText.TextXAlignment = Enum.TextXAlignment.Left
    local pingText = CreateTextLabel(infoFrame, "Ping: 0", UDim2.new(1, -10, 0.3, -5), UDim2.new(0, 5, 0, 30), Enum.Font.Gotham, Color3.fromRGB(255, 255, 255), 14)
    pingText.TextXAlignment = Enum.TextXAlignment.Left
    local fpsText = CreateTextLabel(infoFrame, "FPS: 0", UDim2.new(1, -10, 0.3, -5), UDim2.new(0, 5, 0, 55), Enum.Font.Gotham, Color3.fromRGB(255, 255, 255), 14)
    fpsText.TextXAlignment = Enum.TextXAlignment.Left

    playerIdText.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            setclipboard(tostring(Players.LocalPlayer.UserId))
            SkyLine:Notify("ID скопирован")
        end
    end)

    RunService.Heartbeat:Connect(function(step)
        pingText.Text = "Ping: " .. math.floor(Players.LocalPlayer:GetNetworkPing() * 1000)
        fpsText.Text = "FPS: " .. math.floor(1 / step)
    end)
end

function SkyLine:CreateMainTab()
    local tab = CreateRoundFrame(self.ContentFrame, UDim2.fromScale(1, 1), UDim2.new(0, 0, 0.5, -270), Color3.fromRGB(52, 65, 83), 12)
    tab.Visible = false
    tab.Parent = self.ContentFrame
    self.Tabs[2] = tab

    self.BlockContainer = Instance.new("Frame")
    self.BlockContainer.Size = UDim2.new(1, -90, 1, -40)
    self.BlockContainer.Position = UDim2.new(0, 10, 0, 10)
    self.BlockContainer.BackgroundTransparency = 1
    self.BlockContainer.Parent = tab
end

function SkyLine:CreatePlayerTab()
    local tab = CreateRoundFrame(self.ContentFrame, UDim2.fromScale(1, 1), UDim2.new(0, 0, 0.5, -270), Color3.fromRGB(52, 65, 83), 12)
    tab.Visible = false
    tab.Parent = self.ContentFrame
    self.Tabs[3] = tab
end

function SkyLine:CreateLoadScriptTab()
    local tab = CreateRoundFrame(self.ContentFrame, UDim2.fromScale(1, 1), UDim2.new(0, 0, 0.5, -270), Color3.fromRGB(52, 65, 83), 12)
    tab.Visible = false
    tab.Parent = self.ContentFrame
    self.Tabs[4] = tab

    self.LoadScriptContainer = Instance.new("Frame")
    self.LoadScriptContainer.Size = UDim2.new(1, -20, 1, -20)
    self.LoadScriptContainer.Position = UDim2.new(0, 10, 0, 10)
    self.LoadScriptContainer.BackgroundTransparency = 1
    self.LoadScriptContainer.Parent = tab
end

function SkyLine:CreateSettingsTab()
    local tab = CreateRoundFrame(self.ContentFrame, UDim2.fromScale(1, 1), UDim2.new(0, 0, 0.5, -270), Color3.fromRGB(52, 65, 83), 12)
    tab.Visible = false
    tab.Parent = self.ContentFrame
    self.Tabs[5] = tab

    self:AddMainToggle("Отключить тяжёлые эффекты", false, function() end)
    self:AddMainDropdown("Тема", {"Default", "Neon", "Ocean"}, 1, function() end)
    self:AddMainButton("Save Settings", function() end)
    self:AddMainButton("Destroy GUI", function()
        self.ScreenGui:Destroy()
    end)
end

-- Элементы (Toggle, Slider, Dropdown, Button)
function SkyLine:AddToggle(text, default, callback)
    local tabFrame = self.Tabs[2]
    local yPos = #self.Blocks * 50 + 10

    local elementFrame = CreateRoundFrame(tabFrame, UDim2.new(1, -80, 0, 45), UDim2.new(0, 10, 0, yPos), Color3.fromRGB(34, 49, 69), 8)
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

    toggleButton.MouseButton1Click:Connect(function() SetToggle(not value) end)
    SetToggle(value)

    table.insert(self.Blocks, elementFrame)
    return {SetValue = SetToggle, GetValue = function() return value end}
end

function SkyLine:AddSlider(text, min, max, default, callback)
    local tabFrame = self.Tabs[2]
    local yPos = #self.Blocks * 50 + 10

    local elementFrame = CreateRoundFrame(tabFrame, UDim2.new(1, -80, 0, 45), UDim2.new(0, 10, 0, yPos), Color3.fromRGB(34, 49, 69), 8)
    local label = CreateTextLabel(elementFrame, text, UDim2.new(0, 150, 1, 0), UDim2.new(0, 10, 0, 0), Enum.Font.GothamMedium, Color3.fromRGB(255, 255, 255), 14)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.fromOffset(150, 6)
    sliderFrame.Position = UDim2.new(1, -180, 0.5, -3)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(34, 49, 69)
    sliderFrame.Parent = elementFrame
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = sliderFrame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(91, 196, 203)
    fill.Parent = sliderFrame
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local valueText = CreateTextLabel(elementFrame, tostring(default or 0), UDim2.new(0, 30, 0, 20), UDim2.new(1, -50, 0.5, -10), Enum.Font.Gotham, Color3.fromRGB(255, 255, 255), 12)

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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; updateFromMouse() end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateFromMouse() end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    table.insert(self.Blocks, elementFrame)
    return {SetValue = function(v) fill.Size = UDim2.new((v-min)/(max-min), 0, 1, 0); valueText.Text = tostring(v) end, GetValue = function() return (max-min)*fill.Size.X.Scale + min end}
end

function SkyLine:AddButton(text, callback)
    local tabFrame = self.Tabs[2]
    local yPos = #self.Blocks * 50 + 10

    local elementFrame = CreateRoundFrame(tabFrame, UDim2.new(1, -80, 0, 40), UDim2.new(0, 10, 0, yPos), Color3.fromRGB(34, 49, 69), 8)
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
    btn.MouseButton1Click:Connect(function() SafeCall(callback) end)

    table.insert(self.Blocks, elementFrame)
    return elementFrame
end

function SkyLine:AddDropdown(text, options, defaultIndex, callback)
    local tabFrame = self.Tabs[2]
    local yPos = #self.Blocks * 50 + 10

    local elementFrame = CreateRoundFrame(tabFrame, UDim2.new(1, -80, 0, 45), UDim2.new(0, 10, 0, yPos), Color3.fromRGB(34, 49, 69), 8)
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
        item.MouseEnter:Connect(function() item.BackgroundColor3 = Color3.fromRGB(91, 196, 203) end)
        item.MouseLeave:Connect(function() item.BackgroundColor3 = Color3.new(1, 1, 1) end)
        item.MouseButton1Click:Connect(function()
            selectedIndex = i
            updateDropdownText()
            menuFrame.Visible = false
        end)
    end

    dropdownBtn.MouseButton1Click:Connect(function()
        menuFrame.Visible = not menuFrame.Visible
        dropdownBtn.BackgroundColor3 = menuFrame.Visible and Color3.fromRGB(91, 196, 203) or Color3.fromRGB(67, 85, 109)
    end)

    table.insert(self.Blocks, elementFrame)
    return {SetValue = function(i) selectedIndex = i; updateDropdownText() end, GetValue = function() return options[selectedIndex] end}
end

-- ДОБАВЛЕННЫЙ МЕТОД AddLoadScript
function SkyLine:AddLoadScript(text, callback)
    local container = self.LoadScriptContainer
    if not container then return end
    local yPos = 10
    local elementFrame = CreateRoundFrame(container, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, yPos), Color3.fromRGB(34, 49, 69), 8)
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
    btn.MouseButton1Click:Connect(function() SafeCall(callback) end)
end

-- Уведомления
function SkyLine:Notify(message)
    local notif = CreateRoundFrame(self.MainFrame, UDim2.fromOffset(200, 30), UDim2.new(1, -210, 0, 10), Color3.fromRGB(34, 49, 69), 8)
    local text = CreateTextLabel(notif, message, UDim2.new(1, -10, 1, 0), UDim2.new(0, 5, 0, 0), Enum.Font.GothamMedium, Color3.fromRGB(91, 196, 203), 12)
    text.TextYAlignment = Enum.TextYAlignment.Center
    notif.BackgroundTransparency = 1
    TweenService:Create(notif, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    task.wait(2)
    TweenService:Create(notif, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    task.wait(0.2)
    notif:Destroy()
end

-- Кнопка Exit (сворачивание)
function SkyLine:SetupExitButton()
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
end

-- Публичный API
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

return SkyLine
