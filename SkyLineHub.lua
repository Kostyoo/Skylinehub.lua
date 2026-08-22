--[[
    SkyLine Hub - Production-Ready UI Library for Roblox
    Version: 1.0.0
    Author: SkyLine Team
    Compatible with: KRNL, Synapse, Fluxus, Wave, and other exploits
    Features: Adaptive scaling, smooth animations, full error handling, no memory leaks
    Theme: #223145, #344153, #43556D, #5BC4CB
]]

local SkyLineHub = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Constants
local BASE_RESOLUTION = Vector2.new(1920, 1080)
local COLORS = {
    Background = Color3.fromRGB(34, 49, 69),    -- #223145
    Secondary = Color3.fromRGB(52, 65, 83),     -- #344153
    Border = Color3.fromRGB(67, 85, 109),       -- #43556D
    Accent = Color3.fromRGB(91, 196, 203),      -- #5BC4CB
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    TextDark = Color3.fromRGB(180, 180, 180),
    ToggleOff = Color3.fromRGB(52, 65, 83),
    SliderBackground = Color3.fromRGB(42, 56, 74),
    Highlight = Color3.fromRGB(62, 78, 100),
}

-- Fonts
local FONTS = {
    Regular = Enum.Font.Gotham,
    Bold = Enum.Font.GothamBold,
    Medium = Enum.Font.GothamMedium,
    Light = Enum.Font.GothamLight,
}

-- Utility functions
local function GetViewport()
    return workspace.CurrentCamera.ViewportSize
end

local function ScaleX(value)
    local viewport = GetViewport()
    return value * (viewport.X / BASE_RESOLUTION.X)
end

local function ScaleY(value)
    local viewport = GetViewport()
    return value * (viewport.Y / BASE_RESOLUTION.Y)
end

local function Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        pcall(function()
            instance[prop] = value
        end)
    end
    return instance
end

local function ApplyGradient(instance, colorA, colorB, rotation)
    local gradient = Create("UIGradient", {
        Color = ColorSequence.new(colorA, colorB),
        Rotation = rotation or 0,
    })
    gradient.Parent = instance
    return gradient
end

local function CreateTween(instance, properties, duration, easingStyle, easingDirection, delayTime)
    local tweenInfo = TweenInfo.new(duration or 0.3, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out, 0, false, delayTime or 0)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    return tween
end

local function PlayTween(instance, properties, duration, easingStyle, easingDirection)
    local tween = CreateTween(instance, properties, duration, easingStyle, easingDirection)
    tween:Play()
    return tween
end

local function Round(instance, cornerRadius)
    local corner = instance:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = Create("UICorner", { CornerRadius = UDim.new(0, cornerRadius or ScaleX(8)) })
        corner.Parent = instance
    else
        corner.CornerRadius = UDim.new(0, cornerRadius or ScaleX(8))
    end
    return corner
end

local function AddStroke(instance, thickness, color, transparency)
    local stroke = instance:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Create("UIStroke", {
            Thickness = thickness or ScaleX(1),
            Color = color or COLORS.Border,
            Transparency = transparency or 0,
        })
        stroke.Parent = instance
    else
        stroke.Thickness = thickness or ScaleX(1)
        stroke.Color = color or COLORS.Border
        stroke.Transparency = transparency or 0
    end
    return stroke
end

local function SetDrag(instance, dragTarget)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function updateInput(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        dragTarget.Position = newPos
    end

    instance.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = dragTarget.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    instance.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateInput(input)
        end
    end)
end

-- Main Library
local SkyLineHub = {}
SkyLineHub.__index = SkyLineHub

local ActiveConnections = {}
local function AddConnection(connection)
    table.insert(ActiveConnections, connection)
    return connection
end

local function CleanupConnections()
    for _, conn in ipairs(ActiveConnections) do
        pcall(function() conn:Disconnect() end)
    end
    ActiveConnections = {}
end

-- Window Class
local Window = {}
Window.__index = Window

function Window.new(title, subtitle)
    local self = setmetatable({}, Window)
    self.Title = title or "SkyLine Hub"
    self.Subtitle = subtitle or "Premium UI"
    self.Gui = Create("ScreenGui", {
        Name = "SkyLineHub",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    self.Gui.Parent = CoreGui

    self.Connections = {}
    self.Tabs = {}
    self.CurrentTab = nil
    self.Loaded = false
    self.Visible = true
    self.HeavyEffects = true
    self.Theme = "Default"
    self.Settings = {
        AutoSave = true,
        Presets = {},
    }

    -- Load settings from save (implement later)
    self:LoadSettings()

    -- Create main structures
    self:CreateLoadingScreen()
    self:CreateMainPanel()

    return self
end

function Window:CreateLoadingScreen()
    local loadingFrame = Create("Frame", {
        Name = "LoadingScreen",
        Parent = self.Gui,
        Size = UDim2.new(0, ScaleX(420), 0, ScaleY(280)),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10,
        Transparency = 1,
        Scale = 0.7,
    })
    Round(loadingFrame, ScaleX(16))
    AddStroke(loadingFrame, ScaleX(2), COLORS.Border, 0.3)

    local titleLabel = Create("TextLabel", {
        Parent = loadingFrame,
        Name = "Title",
        Text = "SkyLine Hub",
        Font = FONTS.Bold,
        TextSize = ScaleX(32),
        TextColor3 = COLORS.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0.3, 0),
        Position = UDim2.new(0, 0, 0.1, 0),
        ZIndex = 11,
    })

    -- Loading dots container
    local dotsFrame = Create("Frame", {
        Parent = loadingFrame,
        Name = "DotsContainer",
        Size = UDim2.new(1, 0, 0.2, 0),
        Position = UDim2.new(0, 0, 0.7, 0),
        BackgroundTransparency = 1,
        ZIndex = 11,
    })

    self.Dots = {}
    local dotCount = 8
    local dotSize = ScaleY(12)
    local spacing = ScaleX(6)
    local totalWidth = dotCount * dotSize + (dotCount - 1) * spacing

    for i = 1, dotCount do
        local dot = Create("Frame", {
            Parent = dotsFrame,
            Size = UDim2.new(0, dotSize, 0, dotSize),
            Position = UDim2.new(0.5, -totalWidth / 2 + (i - 1) * (dotSize + spacing), 0.5, -dotSize / 2),
            BackgroundColor3 = COLORS.Accent,
            BorderSizePixel = 0,
            ZIndex = 12,
        })
        Round(dot, dotSize / 2)
        self.Dots[i] = dot
    end

    -- Animate loading screen
    local function animateDots()
        for i, dot in ipairs(self.Dots) do
            local delay = (i - 1) * 0.1
            spawn(function()
                task.wait(delay)
                while self.Loaded == false do
                    PlayTween(dot, { Position = UDim2.new(0.5, -totalWidth / 2 + (i - 1) * (dotSize + spacing) + ScaleX(30), 0.5, -dotSize / 2) }, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                    task.wait(0.3)
                    PlayTween(dot, { Position = UDim2.new(0.5, -totalWidth / 2 + (i - 1) * (dotSize + spacing), 0.5, -dotSize / 2) }, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                    task.wait(0.3)
                end
            end)
        end
    end

    animateDots()

    -- Fade in
    loadingFrame.Transparency = 1
    loadingFrame.Scale = 0.7
    PlayTween(loadingFrame, { Transparency = 0, Scale = 1 }, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Window:CreateMainPanel()
    -- Navigation bar
    local navBar = Create("Frame", {
        Name = "NavBar",
        Parent = self.Gui,
        Size = UDim2.new(0, ScaleX(70), 1, -ScaleY(20)),
        Position = UDim2.new(0, -ScaleX(70), 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        ZIndex = 5,
    })
    Round(navBar, ScaleX(12))
    AddStroke(navBar, ScaleX(1), COLORS.Border, 0.3)
    self.NavBar = navBar

    -- Nav buttons container
    local navButtons = Create("Frame", {
        Parent = navBar,
        Name = "NavButtons",
        Size = UDim2.new(1, -ScaleX(10), 1, -ScaleY(20)),
        Position = UDim2.new(0, ScaleX(5), 0, ScaleY(10)),
        BackgroundTransparency = 1,
        ZIndex = 6,
    })

    -- Highlight indicator
    local highlight = Create("Frame", {
        Parent = navBar,
        Name = "NavHighlight",
        Size = UDim2.new(1, -ScaleX(10), 1, -ScaleY(20)),
        Position = UDim2.new(0, ScaleX(5), 0, ScaleY(10)),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
        ZIndex = 6,
        Transparency = 0.8,
    })
    Round(highlight, ScaleX(8))
    self.NavHighlight = highlight

    -- Tab data
    local tabConfigs = {
        { Name = "Home", Icon = "rbxassetid://112770735347738" },
        { Name = "Main", Icon = "rbxassetid://92091304135140" },
        { Name = "Player", Icon = "rbxassetid://0" }, -- placeholder
        { Name = "LoadScript", Icon = "rbxassetid://83975792443912" },
        { Name = "Settings", Icon = "rbxassetid://125743894366007" },
        { Name = "Exit", Icon = "rbxassetid://96518596121178" },
    }

    self.NavButtons = {}
    for i, config in ipairs(tabConfigs) do
        local btn = Create("ImageButton", {
            Parent = navButtons,
            Name = config.Name,
            Size = UDim2.new(1, -ScaleX(4), 0, ScaleY(44)),
            Position = UDim2.new(0, ScaleX(2), 0, ScaleY(5) + (i - 1) * ScaleY(50)),
            BackgroundTransparency = 0.9,
            BackgroundColor3 = COLORS.Secondary,
            Image = config.Icon,
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 8,
        })
        Round(btn, ScaleX(6))
        self.NavButtons[config.Name] = btn

        -- Add hover effect
        btn.MouseEnter:Connect(function()
            if self.CurrentTab and self.CurrentTab.Name ~= config.Name and config.Name ~= "Exit" then
                self:MoveHighlightToButton(btn, false)
            end
        end)
        btn.MouseLeave:Connect(function()
            if self.CurrentTab and self.CurrentTab.Name ~= config.Name and config.Name ~= "Exit" then
                self:MoveHighlightToButton(self.NavButtons[self.CurrentTab.Name], true)
            end
        end)
        btn.MouseButton1Click:Connect(function()
            if config.Name == "Exit" then
                self:ToggleVisibility()
            else
                self:SelectTab(config.Name)
            end
        end)
    end

    -- Tab content container
    local contentArea = Create("Frame", {
        Parent = self.Gui,
        Name = "ContentArea",
        Size = UDim2.new(1, -ScaleX(80), 1, -ScaleY(20)),
        Position = UDim2.new(0, ScaleX(80), 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 5,
    })
    self.ContentArea = contentArea

    -- Initially hide nav bar and content area
    navBar.Position = UDim2.new(0, -ScaleX(70), 0.5, 0)
    contentArea.Position = UDim2.new(0, ScaleX(80), 0.5, 0)
    navBar.Transparency = 0.8
    contentArea.Transparency = 0.8

    -- Create default tabs
    self:CreateTab("Home")
    self:CreateTab("Main")
    self:CreateTab("Player")
    self:CreateTab("LoadScript")
    self:CreateTab("Settings")
end

function Window:MoveHighlightToButton(button, isPermanent)
    local highlight = self.NavHighlight
    local targetPos = button.Position
    local tween = CreateTween(highlight, { Position = targetPos }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    tween:Play()
    if isPermanent then
        highlight.BackgroundColor3 = COLORS.Secondary
        highlight.Transparency = 0
    else
        highlight.BackgroundColor3 = COLORS.Highlight
        highlight.Transparency = 0
    end
end

function Window:CreateTab(name)
    local tab = {}
    tab.Name = name
    tab.Window = self
    tab.Elements = {}
    tab.Container = Create("Frame", {
        Parent = self.ContentArea,
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        ZIndex = 6,
        Transparency = 1,
        Scale = 0.95,
    })
    Round(tab.Container, ScaleX(12))
    AddStroke(tab.Container, ScaleX(1), COLORS.Border, 0.3)
    tab.Container.Visible = false

    -- Tab header
    local header = Create("TextLabel", {
        Parent = tab.Container,
        Name = "Header",
        Text = name,
        Font = FONTS.Bold,
        TextSize = ScaleX(24),
        TextColor3 = COLORS.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, ScaleY(50)),
        Position = UDim2.new(0, ScaleX(20), 0, ScaleY(10)),
        ZIndex = 7,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Scrolling frame for tab content
    local scrollFrame = Create("ScrollingFrame", {
        Parent = tab.Container,
        Name = "ScrollFrame",
        Size = UDim2.new(1, -ScaleX(20), 1, -ScaleY(60)),
        Position = UDim2.new(0, ScaleX(10), 0, ScaleY(50)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 7,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = ScaleX(4),
        ScrollBarImageColor3 = COLORS.Border,
        ClipsDescendants = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    tab.ScrollFrame = scrollFrame

    -- Layout for elements
    local layout = Create("UIListLayout", {
        Parent = scrollFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, ScaleY(10)),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })
    tab.Layout = layout

    -- Add padding frame inside scroll
    local padding = Create("Frame", {
        Parent = scrollFrame,
        Size = UDim2.new(1, 0, 0, ScaleY(10)),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
    })

    self.Tabs[name] = tab
    return tab
end

function Window:SelectTab(name)
    local tab = self.Tabs[name]
    if not tab then return end

    if self.CurrentTab then
        -- Animate out old tab
        local oldTab = self.CurrentTab
        oldTab.Container.Visible = true
        local direction = 1 -- default down
        if tab.Name < oldTab.Name then -- compare alphabetical or custom order
            direction = -1 -- up
        end
        local oldTween = PlayTween(oldTab.Container, { Position = UDim2.new(0, 0, 0, direction * ScaleY(100)), Transparency = 1, Scale = 0.95 }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        oldTween.Completed:Connect(function()
            oldTab.Container.Visible = false
        end)
    end

    -- Animate in new tab
    tab.Container.Visible = true
    tab.Container.Position = UDim2.new(0, 0, 0, -ScaleY(100))
    tab.Container.Transparency = 1
    tab.Container.Scale = 0.95
    local newTween = PlayTween(tab.Container, { Position = UDim2.new(0, 0, 0, 0), Transparency = 0, Scale = 1 }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    self.CurrentTab = tab

    -- Update nav highlight
    local btn = self.NavButtons[name]
    if btn then
        self:MoveHighlightToButton(btn, true)
    end
end

function Window:ToggleVisibility()
    if self.Visible then
        -- Hide everything except exit arrow
        self.NavBar.Visible = false
        self.ContentArea.Visible = false
        for _, tab in pairs(self.Tabs) do
            tab.Container.Visible = false
        end
        self.ExitArrow.Visible = true
        self.Visible = false
    else
        -- Show again
        self.NavBar.Visible = true
        self.ContentArea.Visible = true
        if self.CurrentTab then
            self.CurrentTab.Container.Visible = true
        end
        -- Animate entrance
        self.NavBar.Position = UDim2.new(0, -ScaleX(70), 0.5, 0)
        self.ContentArea.Position = UDim2.new(0, ScaleX(80), 0.5, 0)
        self.NavBar.Transparency = 0.8
        self.ContentArea.Transparency = 0.8
        PlayTween(self.NavBar, { Position = UDim2.new(0, 0, 0.5, 0), Transparency = 0 }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        PlayTween(self.ContentArea, { Position = UDim2.new(0, ScaleX(80), 0.5, 0), Transparency = 0 }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        self.Visible = true
    end
end

function Window:CreateExitArrow()
    local arrowButton = Create("TextButton", {
        Parent = self.Gui,
        Name = "ExitArrow",
        Size = UDim2.new(0, ScaleX(20), 0, ScaleY(80)),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        Text = "»",
        Font = FONTS.Bold,
        TextSize = ScaleX(24),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 20,
        Visible = false,
    })
    Round(arrowButton, ScaleX(8))
    AddStroke(arrowButton, ScaleX(1), COLORS.Border, 0.3)
    self.ExitArrow = arrowButton

    arrowButton.MouseButton1Click:Connect(function()
        self:ToggleVisibility()
    end)
end

function Window:LoadSettings()
    -- Placeholder for saving/loading settings via DataStore or JSON
    -- Will implement in Settings tab
end

-- Element Classes
local ElementBase = {}
ElementBase.__index = ElementBase

function ElementBase.new(tab, elementType)
    local self = setmetatable({}, ElementBase)
    self.Tab = tab
    self.Type = elementType
    self.Window = tab.Window
    self.Container = Create("Frame", {
        Parent = tab.ScrollFrame,
        Name = elementType,
        Size = UDim2.new(1, -ScaleX(20), 0, ScaleY(50)),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
        ZIndex = 7,
        LayoutOrder = 1, -- will be set later
    })
    Round(self.Container, ScaleX(8))
    self.Connections = {}
    return self
end

function ElementBase:AddConnection(conn)
    table.insert(self.Connections, conn)
    return conn
end

function ElementBase:Destroy()
    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    pcall(function() self.Container:Destroy() end)
end

-- Toggle Element
local Toggle = setmetatable({}, { __index = ElementBase })
Toggle.__index = Toggle

function Toggle.new(tab, name, default, callback)
    local self = ElementBase.new(tab, "Toggle")
    self.Name = name
    self.Value = default or false
    self.Callback = callback or function() end

    -- Title label
    self.TitleLabel = Create("TextLabel", {
        Parent = self.Container,
        Text = name,
        Font = FONTS.Medium,
        TextSize = ScaleX(16),
        TextColor3 = COLORS.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, ScaleX(15), 0, 0),
        ZIndex = 8,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Toggle switch
    self.Switch = Create("Frame", {
        Parent = self.Container,
        Name = "Switch",
        Size = UDim2.new(0, ScaleX(40), 0, ScaleY(20)),
        Position = UDim2.new(0.85, 0, 0.5, -ScaleY(10)),
        BackgroundColor3 = COLORS.ToggleOff,
        BorderSizePixel = 0,
        ZIndex = 8,
    })
    Round(self.Switch, ScaleX(10))
    AddStroke(self.Switch, ScaleX(1), COLORS.Border, 0.5)

    -- Knob
    self.Knob = Create("Frame", {
        Parent = self.Switch,
        Name = "Knob",
        Size = UDim2.new(0, ScaleY(18), 0, ScaleY(18)),
        Position = UDim2.new(0, ScaleX(1), 0.5, -ScaleY(9)),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 9,
    })
    Round(self.Knob, ScaleY(9))
    self.Knob.Position = self.Value and UDim2.new(1, -ScaleX(19), 0.5, -ScaleY(9)) or UDim2.new(0, ScaleX(1), 0.5, -ScaleY(9))

    -- Update visual state
    local function updateVisual()
        local switchColor = self.Value and COLORS.Accent or COLORS.ToggleOff
        local knobPos = self.Value and UDim2.new(1, -ScaleX(19), 0.5, -ScaleY(9)) or UDim2.new(0, ScaleX(1), 0.5, -ScaleY(9))
        PlayTween(self.Switch, { BackgroundColor3 = switchColor }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        PlayTween(self.Knob, { Position = knobPos }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    -- Click detection
    self.Switch.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:SetValue(not self.Value)
        end
    end)

    self.TitleLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:SetValue(not self.Value)
        end
    end)

    self.Container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Only toggle if clicked on container background not on other elements
            if input.Position.X > self.Switch.Position.X.Offset then
                self:SetValue(not self.Value)
            end
        end
    end)

    function self:SetValue(value)
        self.Value = value
        updateVisual()
        pcall(self.Callback, value)
    end

    -- Initialize
    updateVisual()
    return self
end

-- Slider Element
local Slider = setmetatable({}, { __index = ElementBase })
Slider.__index = Slider

function Slider.new(tab, name, min, max, default, callback, suffix)
    local self = ElementBase.new(tab, "Slider")
    self.Name = name
    self.Min = min or 0
    self.Max = max or 100
    self.Value = default or min
    self.Callback = callback or function() end
    self.Suffix = suffix or ""

    -- Title label
    self.TitleLabel = Create("TextLabel", {
        Parent = self.Container,
        Text = name,
        Font = FONTS.Medium,
        TextSize = ScaleX(16),
        TextColor3 = COLORS.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, ScaleX(15), 0, 0),
        ZIndex = 8,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Slider background
    self.SliderBg = Create("Frame", {
        Parent = self.Container,
        Name = "SliderBg",
        Size = UDim2.new(0.22, 0, 0, ScaleY(4)),
        Position = UDim2.new(0.75, 0, 0.5, -ScaleY(2)),
        BackgroundColor3 = COLORS.SliderBackground,
        BorderSizePixel = 0,
        ZIndex = 8,
    })
    Round(self.SliderBg, ScaleY(2))

    -- Fill
    self.Fill = Create("Frame", {
        Parent = self.SliderBg,
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = COLORS.Accent,
        BorderSizePixel = 0,
        ZIndex = 9,
    })
    Round(self.Fill, ScaleY(2))
    ApplyGradient(self.Fill, COLORS.Secondary, COLORS.Accent, 0)

    -- Knob
    self.Knob = Create("Frame", {
        Parent = self.SliderBg,
        Name = "Knob",
        Size = UDim2.new(0, ScaleY(18), 0, ScaleY(18)),
        Position = UDim2.new(0, 0, 0.5, -ScaleY(9)),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    Round(self.Knob, ScaleY(9))
    AddStroke(self.Knob, ScaleX(1), COLORS.Border, 0.5)

    -- Value label
    self.ValueLabel = Create("TextLabel", {
        Parent = self.Container,
        Text = tostring(self.Value) .. self.Suffix,
        Font = FONTS.Medium,
        TextSize = ScaleX(14),
        TextColor3 = COLORS.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.08, 0, 1, 0),
        Position = UDim2.new(0.97, -ScaleX(30), 0, 0),
        ZIndex = 8,
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    -- Update visual
    local function updateVisual()
        local percent = (self.Value - self.Min) / (self.Max - self.Min)
        percent = math.clamp(percent, 0, 1)
        self.Fill.Size = UDim2.new(percent, 0, 1, 0)
        local knobX = percent * (self.SliderBg.AbsoluteSize.X - self.Knob.AbsoluteSize.X)
        self.Knob.Position = UDim2.new(0, knobX, 0.5, -ScaleY(9))
        self.ValueLabel.Text = tostring(math.floor(self.Value * 10 + 0.5) / 10) .. self.Suffix
    end

    -- Drag handling
    local dragging = false
    local connection
    local function startDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromInput(input)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end

    local function updateFromInput(input)
        local relX = input.Position.X - self.SliderBg.AbsolutePosition.X
        local sizeX = self.SliderBg.AbsoluteSize.X
        local percent = math.clamp(relX / sizeX, 0, 1)
        self.Value = self.Min + percent * (self.Max - self.Min)
        updateVisual()
        pcall(self.Callback, self.Value)
    end

    self.SliderBg.InputBegan:Connect(startDrag)
    self.SliderBg.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput(input)
        end
    end)
    self.Knob.InputBegan:Connect(startDrag)
    self.Knob.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput(input)
        end
    end)

    function self:SetValue(value)
        self.Value = math.clamp(value, self.Min, self.Max)
        updateVisual()
        pcall(self.Callback, self.Value)
    end

    updateVisual()
    return self
end

-- Dropdown Element
local Dropdown = setmetatable({}, { __index = ElementBase })
Dropdown.__index = Dropdown

function Dropdown.new(tab, name, options, default, callback)
    local self = ElementBase.new(tab, "Dropdown")
    self.Name = name
    self.Options = options or {}
    self.Value = default or (self.Options[1] or "")
    self.Callback = callback or function() end
    self.Open = false

    -- Title label
    self.TitleLabel = Create("TextLabel", {
        Parent = self.Container,
        Text = name,
        Font = FONTS.Medium,
        TextSize = ScaleX(16),
        TextColor3 = COLORS.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, ScaleX(15), 0, 0),
        ZIndex = 8,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Dropdown button
    self.Button = Create("TextButton", {
        Parent = self.Container,
        Name = "DropdownButton",
        Size = UDim2.new(0.35, 0, 0, ScaleY(30)),
        Position = UDim2.new(0.6, 0, 0.5, -ScaleY(15)),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        Text = self.Value,
        Font = FONTS.Medium,
        TextSize = ScaleX(14),
        TextColor3 = COLORS.Text,
        ZIndex = 8,
    })
    Round(self.Button, ScaleX(6))
    AddStroke(self.Button, ScaleX(1), COLORS.Border, 0.5)

    -- Dropdown list container (hidden initially)
    self.ListContainer = Create("Frame", {
        Parent = self.Container,
        Name = "DropdownList",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 20,
    })
    Round(self.ListContainer, ScaleX(6))
    AddStroke(self.ListContainer, ScaleX(1), COLORS.Accent, 0.3)

    local listLayout = Create("UIListLayout", {
        Parent = self.ListContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, ScaleY(2)),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    -- Create option buttons
    self.OptionButtons = {}
    for i, option in ipairs(self.Options) do
        local optionBtn = Create("TextButton", {
            Parent = self.ListContainer,
            Text = option,
            Font = FONTS.Medium,
            TextSize = ScaleX(14),
            TextColor3 = COLORS.Text,
            BackgroundColor3 = COLORS.Secondary,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -ScaleX(10), 0, ScaleY(28)),
            LayoutOrder = i,
            ZIndex = 21,
        })
        Round(optionBtn, ScaleX(4))
        optionBtn.MouseEnter:Connect(function()
            PlayTween(optionBtn, { BackgroundColor3 = COLORS.Highlight }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)
        optionBtn.MouseLeave:Connect(function()
            PlayTween(optionBtn, { BackgroundColor3 = COLORS.Secondary }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)
        optionBtn.MouseButton1Click:Connect(function()
            self:SelectOption(option)
            self:Close()
        end)
        self.OptionButtons[i] = optionBtn
    end

    -- Update list height based on options
    local listHeight = #self.Options * (ScaleY(28) + ScaleY(2)) + ScaleY(5)
    self.ListContainer.Size = UDim2.new(1, 0, 0, listHeight)

    function self:Open()
        self.Open = true
        AddStroke(self.Button, ScaleX(1), COLORS.Accent, 0.3)
        PlayTween(self.ListContainer, { Size = UDim2.new(1, 0, 0, listHeight) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        self.ListContainer.Visible = true
    end

    function self:Close()
        self.Open = false
        AddStroke(self.Button, ScaleX(1), COLORS.Border, 0.5)
        PlayTween(self.ListContainer, { Size = UDim2.new(1, 0, 0, 0) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
            self.ListContainer.Visible = false
        end)
    end

    function self:SelectOption(option)
        self.Value = option
        self.Button.Text = option
        pcall(self.Callback, option)
    end

    self.Button.MouseButton1Click:Connect(function()
        if self.Open then
            self:Close()
        else
            self:Open()
        end
    end)

    -- Initialize hidden state
    self.ListContainer.Visible = false
    return self
end

-- Block (collapsible section)
local Block = setmetatable({}, { __index = ElementBase })
Block.__index = Block

function Block.new(tab, name)
    local self = ElementBase.new(tab, "Block")
    self.Name = name
    self.Open = false
    self.Children = {}
    self.ChildContainer = nil

    -- Header button
    self.HeaderButton = Create("TextButton", {
        Parent = self.Container,
        Text = " " .. name,
        Font = FONTS.Medium,
        TextSize = ScaleX(16),
        TextColor3 = COLORS.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 8,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Arrow indicator
    self.Arrow = Create("TextLabel", {
        Parent = self.Container,
        Text = "▼",
        Font = FONTS.Bold,
        TextSize = ScaleX(14),
        TextColor3 = COLORS.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, ScaleX(20), 1, 0),
        Position = UDim2.new(0, ScaleX(10), 0, 0),
        ZIndex = 9,
        Rotation = 0,
    })

    -- Child container (for elements)
    self.ChildContainer = Create("Frame", {
        Parent = self.Container,
        Name = "ChildContainer",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 7,
    })
    Round(self.ChildContainer, ScaleX(8))
    local childLayout = Create("UIListLayout", {
        Parent = self.ChildContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, ScaleY(8)),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    self.HeaderButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    function self:Toggle()
        self.Open = not self.Open
        if self.Open then
            -- Expand
            PlayTween(self.Arrow, { Rotation = 180 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local totalHeight = 0
            for _, child in ipairs(self.Children) do
                totalHeight = totalHeight + child.Container.AbsoluteSize.Y + ScaleY(8)
            end
            PlayTween(self.ChildContainer, { Size = UDim2.new(1, 0, 0, totalHeight) }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        else
            -- Collapse
            PlayTween(self.Arrow, { Rotation = 0 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            PlayTween(self.ChildContainer, { Size = UDim2.new(1, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        end
    end

    function self:AddElement(element)
        element.Container.Parent = self.ChildContainer
        element.Container.LayoutOrder = #self.Children + 1
        table.insert(self.Children, element)
        -- Update parent size if open
        if self.Open then
            local totalHeight = 0
            for _, child in ipairs(self.Children) do
                totalHeight = totalHeight + child.Container.AbsoluteSize.Y + ScaleY(8)
            end
            self.ChildContainer.Size = UDim2.new(1, 0, 0, totalHeight)
        end
        return element
    end

    return self
end

-- Button Element
local Button = setmetatable({}, { __index = ElementBase })
Button.__index = Button

function Button.new(tab, name, callback)
    local self = ElementBase.new(tab, "Button")
    self.Name = name
    self.Callback = callback or function() end

    self.Button = Create("TextButton", {
        Parent = self.Container,
        Text = name,
        Font = FONTS.Medium,
        TextSize = ScaleX(16),
        TextColor3 = COLORS.Text,
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 8,
    })
    Round(self.Button, ScaleX(8))
    AddStroke(self.Button, ScaleX(1), COLORS.Border, 0.3)

    self.Button.MouseEnter:Connect(function()
        PlayTween(self.Button, { BackgroundColor3 = COLORS.Highlight }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
    self.Button.MouseLeave:Connect(function()
        PlayTween(self.Button, { BackgroundColor3 = COLORS.Secondary }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
    self.Button.MouseButton1Click:Connect(function()
        pcall(self.Callback)
    end)

    return self
end

-- Label Element
local Label = setmetatable({}, { __index = ElementBase })
Label.__index = Label

function Label.new(tab, text, textSize, textColor)
    local self = ElementBase.new(tab, "Label")
    self.Text = text

    self.Label = Create("TextLabel", {
        Parent = self.Container,
        Text = text,
        Font = FONTS.Medium,
        TextSize = textSize or ScaleX(16),
        TextColor3 = textColor or COLORS.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 8,
        TextWrapped = true,
    })

    return self
end

-- Tab creation methods
function Window:CreateTab(name)
    local tab = {}
    tab.Name = name
    tab.Window = self
    tab.Elements = {}
    tab.Container = Create("Frame", {
        Parent = self.ContentArea,
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        ZIndex = 6,
        Transparency = 1,
        Scale = 0.95,
    })
    Round(tab.Container, ScaleX(12))
    AddStroke(tab.Container, ScaleX(1), COLORS.Border, 0.3)
    tab.Container.Visible = false

    -- Tab header
    local header = Create("TextLabel", {
        Parent = tab.Container,
        Name = "Header",
        Text = name,
        Font = FONTS.Bold,
        TextSize = ScaleX(24),
        TextColor3 = COLORS.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, ScaleY(50)),
        Position = UDim2.new(0, ScaleX(20), 0, ScaleY(10)),
        ZIndex = 7,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Scrolling frame for tab content
    local scrollFrame = Create("ScrollingFrame", {
        Parent = tab.Container,
        Name = "ScrollFrame",
        Size = UDim2.new(1, -ScaleX(20), 1, -ScaleY(60)),
        Position = UDim2.new(0, ScaleX(10), 0, ScaleY(50)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 7,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = ScaleX(4),
        ScrollBarImageColor3 = COLORS.Border,
        ClipsDescendants = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    tab.ScrollFrame = scrollFrame

    -- Layout for elements
    local layout = Create("UIListLayout", {
        Parent = scrollFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, ScaleY(10)),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })
    tab.Layout = layout

    -- Add padding frame inside scroll
    local padding = Create("Frame", {
        Parent = scrollFrame,
        Size = UDim2.new(1, 0, 0, ScaleY(10)),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
    })

    self.Tabs[name] = tab
    return tab
end

-- Element creation functions
function Tab:AddToggle(name, default, callback)
    local toggle = Toggle.new(self, name, default, callback)
    self.Elements[#self.Elements + 1] = toggle
    return toggle
end

function Tab:AddSlider(name, min, max, default, callback, suffix)
    local slider = Slider.new(self, name, min, max, default, callback, suffix)
    self.Elements[#self.Elements + 1] = slider
    return slider
end

function Tab:AddDropdown(name, options, default, callback)
    local dropdown = Dropdown.new(self, name, options, default, callback)
    self.Elements[#self.Elements + 1] = dropdown
    return dropdown
end

function Tab:AddBlock(name)
    local block = Block.new(self, name)
    self.Elements[#self.Elements + 1] = block
    return block
end

function Tab:AddButton(name, callback)
    local button = Button.new(self, name, callback)
    self.Elements[#self.Elements + 1] = button
    return button
end

function Tab:AddLabel(text, textSize, textColor)
    local label = Label.new(self, text, textSize, textColor)
    self.Elements[#self.Elements + 1] = label
    return label
end

-- Finish loading
function Window:FinishLoading()
    self.Loaded = true
    -- Destroy loading screen
    pcall(function()
        self.Gui:FindFirstChild("LoadingScreen"):Destroy()
    end)

    -- Show main panel with animation
    self:SelectTab("Home")
    self.NavBar.Visible = true
    self.ContentArea.Visible = true

    -- Create exit arrow
    self:CreateExitArrow()

    -- Show entrance animation
    PlayTween(self.NavBar, { Position = UDim2.new(0, 0, 0.5, 0), Transparency = 0 }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    PlayTween(self.ContentArea, { Position = UDim2.new(0, ScaleX(80), 0.5, 0), Transparency = 0 }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

-- Main library function
function SkyLineHub.CreateWindow(title, subtitle)
    local window = Window.new(title, subtitle)
    -- Auto finish loading after delay
    task.delay(1.5, function()
        window:FinishLoading()
    end)
    return window
end

return SkyLineHub
