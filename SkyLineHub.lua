--[[
    SkyLine Hub - UI Library for Roblox
    Version: 1.0.0
    Compatible with: KRNL, Synapse, Fluxus, Wave, and other exploits
]]

local SkyLine = {}
SkyLine.__index = SkyLine

-- ============================================================
-- CONSTANTS & CONFIGURATION
-- ============================================================

local CONFIG = {
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    FontSource = Enum.Font.SourceSansPro,
    
    Colors = {
        Main = Color3.fromRGB(34, 49, 69),
        Secondary = Color3.fromRGB(52, 65, 83),
        Border = Color3.fromRGB(67, 85, 109),
        Accent = Color3.fromRGB(91, 196, 203),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(200, 210, 220),
        Black = Color3.fromRGB(0, 0, 0),
        White = Color3.fromRGB(255, 255, 255),
        
        GlowIndigo = Color3.fromRGB(75, 0, 130),
        GlowCyan = Color3.fromRGB(0, 191, 255),
    },
    
    Theme = {
        Default = {
            Accent = Color3.fromRGB(91, 196, 203),
            Glow1 = Color3.fromRGB(75, 0, 130),
            Glow2 = Color3.fromRGB(0, 191, 255),
        },
        Purple = {
            Accent = Color3.fromRGB(186, 85, 211),
            Glow1 = Color3.fromRGB(138, 43, 226),
            Glow2 = Color3.fromRGB(216, 191, 216),
        },
        Orange = {
            Accent = Color3.fromRGB(255, 165, 0),
            Glow1 = Color3.fromRGB(255, 69, 0),
            Glow2 = Color3.fromRGB(255, 215, 0),
        },
    },
    
    Spacing = {
        XS = 4,
        S = 8,
        M = 12,
        L = 16,
        XL = 24,
        XXL = 32,
    },
    
    CornerRadius = {
        Small = UDim.new(0, 6),
        Medium = UDim.new(0, 10),
        Large = UDim.new(0, 16),
        Round = UDim.new(1, 0),
    },
    
    DefaultHeight = 36,
    DefaultWidth = 180,
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

local Utility = {}
SkyLine.Utility = Utility

function Utility:IsAlive(obj)
    return pcall(function()
        return obj and obj.Parent ~= nil
    end) and true or false
end

function Utility:SafeDestroy(obj)
    pcall(function()
        if obj and obj:IsA("Instance") then
            obj:Destroy()
        end
    end)
end

function Utility:Create(className, properties)
    local instance = Instance.new(className)
    if properties then
        for k, v in pairs(properties) do
            pcall(function()
                instance[k] = v
            end)
        end
    end
    return instance
end

function Utility:MakeCorner(radius)
    return Utility:Create("UICorner", {
        CornerRadius = radius or CONFIG.CornerRadius.Medium
    })
end

function Utility:MakeGradient(colors, rotation)
    local gradient = Utility:Create("UIGradient", {
        Rotation = rotation or 0,
    })
    
    if colors then
        local colorSequence = {}
        for i, color in ipairs(colors) do
            table.insert(colorSequence, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), color, color))
        end
        gradient.Color = ColorSequence.new(colorSequence)
    end
    
    return gradient
end

function Utility:MakeStroke(color, thickness, transparency)
    return Utility:Create("UIStroke", {
        Color = color or CONFIG.Colors.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

function Utility:MakeShadow(transparency)
    return Utility:Create("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1,
        Transparency = transparency or 0.7,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

function Utility:RoundToNearest(value, step)
    return math.floor(value / step + 0.5) * step
end

function Utility:Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function Utility:Lerp(a, b, t)
    return a + (b - a) * t
end

function Utility:CopyToClipboard(text)
    pcall(function()
        setclipboard(text)
    end)
end

function Utility:GetPlayers()
    return game:GetService("Players"):GetPlayers()
end

function Utility:GetLocalPlayer()
    return game:GetService("Players").LocalPlayer
end

-- ============================================================
-- ANIMATION SYSTEM
-- ============================================================

local AnimationSystem = {}
SkyLine.AnimationSystem = AnimationSystem

local TweenService = game:GetService("TweenService")

function AnimationSystem:Tween(instance, properties, time, easingStyle, easingDirection)
    local tweenInfo = TweenInfo.new(
        time or 0.3,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    
    return TweenService:Create(instance, tweenInfo, properties)
end

function AnimationSystem:FadeIn(instance, time)
    local tween = self:Tween(instance, {
        Transparency = 0,
        Scale = 1,
    }, time or 0.3)
    tween:Play()
    return tween
end

function AnimationSystem:FadeOut(instance, time)
    local tween = self:Tween(instance, {
        Transparency = 1,
        Scale = 0.8,
    }, time or 0.3)
    tween:Play()
    return tween
end

function AnimationSystem:SlideIn(instance, direction, time)
    local originalPos = instance.Position
    local offset = UDim2.new(
        direction == "Left" and -1 or direction == "Right" and 1 or 0,
        0,
        direction == "Up" and -1 or direction == "Down" and 1 or 0,
        0
    )
    
    instance.Position = originalPos + offset
    instance.Transparency = 1
    
    local tween = self:Tween(instance, {
        Position = originalPos,
        Transparency = 0,
    }, time or 0.4)
    tween:Play()
    return tween
end

function AnimationSystem:SlideOut(instance, direction, time)
    local offset = UDim2.new(
        direction == "Left" and -1 or direction == "Right" and 1 or 0,
        0,
        direction == "Up" and -1 or direction == "Down" and 1 or 0,
        0
    )
    
    local tween = self:Tween(instance, {
        Position = instance.Position + offset,
        Transparency = 1,
        Scale = 0.8,
    }, time or 0.3)
    tween:Play()
    return tween
end

function AnimationSystem:BounceIn(instance, time)
    instance.Scale = 0.7
    instance.Transparency = 1
    
    local tween = self:Tween(instance, {
        Scale = 1,
        Transparency = 0,
    }, time or 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tween:Play()
    return tween
end

-- ============================================================
-- LOADING SCREEN
-- ============================================================

local LoadingScreen = {}
SkyLine.LoadingScreen = LoadingScreen

function LoadingScreen:Show(parent, onComplete)
    local screenGui = Utility:Create("ScreenGui", {
        Name = "SkyLineLoading",
        Parent = parent,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    local background = Utility:Create("Frame", {
        Name = "Background",
        Parent = screenGui,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = CONFIG.Colors.Main,
        BorderSizePixel = 0,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Small)
    
    local mainFrame = Utility:Create("Frame", {
        Name = "MainFrame",
        Parent = background,
        Size = UDim2.new(0, 400, 0, 250),
        Position = UDim2.new(0.5, -200, 0.5, -125),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Large)
    Utility:MakeStroke(CONFIG.Colors.Border, 2)
    
    local title = Utility:Create("TextLabel", {
        Name = "Title",
        Parent = mainFrame,
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "SkyLine Hub",
        TextColor3 = CONFIG.Colors.White,
        TextSize = 36,
        Font = CONFIG.FontBold,
        TextStrokeTransparency = 0.5,
    })
    
    local subtitle = Utility:Create("TextLabel", {
        Name = "Subtitle",
        Parent = mainFrame,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 80),
        BackgroundTransparency = 1,
        Text = "Loading...",
        TextColor3 = CONFIG.Colors.Accent,
        TextSize = 14,
        Font = CONFIG.Font,
    })
    
    -- Loading wave animation
    local waveContainer = Utility:Create("Frame", {
        Name = "WaveContainer",
        Parent = mainFrame,
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 1, -70),
        BackgroundTransparency = 1,
    })
    
    local waveCircles = {}
    local circleCount = 9
    
    for i = 1, circleCount do
        local circle = Utility:Create("Frame", {
            Name = "Circle" .. i,
            Parent = waveContainer,
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0, (i - 1) * 32 + 20, 0.5, -6),
            BackgroundColor3 = CONFIG.Colors.Accent,
            BorderSizePixel = 0,
        })
        Utility:MakeCorner(CONFIG.CornerRadius.Round)
        table.insert(waveCircles, circle)
    end
    
    -- Wave animation loop
    local waveTask = task.spawn(function()
        while true do
            for i, circle in ipairs(waveCircles) do
                pcall(function()
                    local tween = TweenService:Create(circle, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                        Position = UDim2.new(circle.Position.X.Scale, circle.Position.X.Offset, 0.5, -14),
                        Size = UDim2.new(0, 16, 0, 16),
                    })
                    tween:Play()
                    
                    task.delay(0.3 / circleCount, function()
                        pcall(function()
                            local tweenBack = TweenService:Create(circle, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                                Position = UDim2.new(circle.Position.X.Scale, circle.Position.X.Offset, 0.5, -6),
                                Size = UDim2.new(0, 12, 0, 12),
                            })
                            tweenBack:Play()
                        end)
                    end)
                end)
            end
            task.wait(0.5)
        end
    end)
    
    -- Bounce-in animation
    local bounceTween = AnimationSystem:BounceIn(mainFrame, 0.6)
    
    -- Complete loading
    task.delay(2, function()
        pcall(function()
            task.cancel(waveTask)
            
            local fadeOut = TweenService:Create(screenGui, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Transparency = 1,
            })
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                Utility:SafeDestroy(screenGui)
                if onComplete then
                    pcall(onComplete)
                end
            end)
        end)
    end)
end

-- ============================================================
-- GLOW EFFECT SYSTEM
-- ============================================================

local GlowSystem = {}
SkyLine.GlowSystem = GlowSystem

function GlowSystem:CreateGlow(parent, color1, color2)
    local glowFrame = Utility:Create("Frame", {
        Name = "Glow",
        Parent = parent,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = -1,
    })
    
    -- Create multiple glow blobs
    local blobs = {}
    
    for i = 1, 8 do
        local blob = Utility:Create("Frame", {
            Name = "Blob" .. i,
            Parent = glowFrame,
            Size = UDim2.new(0, 300 + i * 40, 0, 300 + i * 40),
            Position = UDim2.new(
                math.random(0, 100) / 100,
                0,
                math.random(0, 100) / 100,
                0
            ),
            BackgroundColor3 = i % 2 == 0 and color1 or color2,
            BorderSizePixel = 0,
            Transparency = 0.85,
        })
        Utility:MakeCorner(CONFIG.CornerRadius.Round)
        table.insert(blobs, blob)
    end
    
    -- Animate blobs
    local animationTask = task.spawn(function()
        while true do
            for i, blob in ipairs(blobs) do
                pcall(function()
                    local scale = 0.5 + (i % 3) * 0.3
                    local position = UDim2.new(
                        math.random(-10, 110) / 100,
                        0,
                        math.random(-10, 110) / 100,
                        0
                    )
                    
                    local tween = TweenService:Create(blob, TweenInfo.new(4 + i, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Position = position,
                        Size = UDim2.new(0, 200 + i * 30, 0, 200 + i * 30),
                        Transparency = 0.7 + math.random() * 0.2,
                    })
                    tween:Play()
                end)
            end
            task.wait(4)
        end
    end)
    
    return glowFrame, animationTask
end

function GlowSystem:DisableHeavyEffects()
    return CONFIG.DisableHeavyEffects or false
end

-- ============================================================
-- CORE UI COMPONENT
-- ============================================================

local UIComponent = {}
UIComponent.__index = UIComponent

function UIComponent:CreateElement(className, properties)
    return Utility:Create(className, properties)
end

function UIComponent:AddCorner(radius)
    return Utility:MakeCorner(radius)
end

function UIComponent:AddStroke(color, thickness)
    return Utility:MakeStroke(color, thickness)
end

function UIComponent:AddGradient(colors, rotation)
    return Utility:MakeGradient(colors, rotation)
end

function UIComponent:AddShadow()
    return Utility:MakeShadow()
end

function UIComponent:OnMouseEnter(callback)
    if self.Instance then
        self.Instance.MouseEnter:Connect(function()
            pcall(callback)
        end)
    end
end

function UIComponent:OnMouseLeave(callback)
    if self.Instance then
        self.Instance.MouseLeave:Connect(function()
            pcall(callback)
        end)
    end
end

function UIComponent:OnClick(callback)
    if self.Instance then
        self.Instance.MouseButton1Click:Connect(function()
            pcall(callback)
        end)
    end
end

function UIComponent:SetText(text)
    pcall(function()
        if self.Instance:IsA("TextLabel") or self.Instance:IsA("TextButton") then
            self.Instance.Text = text
        end
    end)
end

function UIComponent:SetVisible(visible)
    pcall(function()
        self.Instance.Visible = visible
    end)
end

function UIComponent:SetPosition(position)
    pcall(function()
        self.Instance.Position = position
    end)
end

function UIComponent:SetSize(size)
    pcall(function()
        self.Instance.Size = size
    end)
end

function UIComponent:SetBackgroundColor(color)
    pcall(function()
        self.Instance.BackgroundColor3 = color
    end)
end

function UIComponent:SetTextColor(color)
    pcall(function()
        if self.Instance:IsA("TextLabel") or self.Instance:IsA("TextButton") then
            self.Instance.TextColor3 = color
        end
    end)
end

-- ============================================================
-- TOGGLE COMPONENT
-- ============================================================

local Toggle = {}
Toggle.__index = Toggle
setmetatable(Toggle, { __index = UIComponent })

function Toggle.new(parent, title, defaultState, callback)
    local self = setmetatable({}, Toggle)
    
    self.Title = title or "Toggle"
    self.Value = defaultState or false
    self.Callback = callback
    
    -- Main container
    self.Instance = Utility:Create("TextButton", {
        Name = "Toggle_" .. self.Title,
        Parent = parent,
        Size = UDim2.new(1, -20, 0, CONFIG.DefaultHeight + 8),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Medium)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    -- Title label
    self.TitleLabel = Utility:Create("TextLabel", {
        Name = "Title",
        Parent = self.Instance,
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = CONFIG.Colors.White,
        TextSize = 14,
        Font = CONFIG.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    -- Toggle background
    self.ToggleBackground = Utility:Create("Frame", {
        Name = "ToggleBG",
        Parent = self.Instance,
        Size = UDim2.new(0, 45, 0, 22),
        Position = UDim2.new(1, -60, 0.5, -11),
        BackgroundColor3 = CONFIG.Colors.Main,
        BorderSizePixel = 0,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Round)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    -- Toggle knob
    self.ToggleKnob = Utility:Create("Frame", {
        Name = "ToggleKnob",
        Parent = self.ToggleBackground,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 2, 0.5, -9),
        BackgroundColor3 = CONFIG.Colors.White,
        BorderSizePixel = 0,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Round)
    
    -- Click handler
    self.Instance.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    self:UpdateVisual()
    
    return self
end

function Toggle:Toggle()
    self.Value = not self.Value
    self:UpdateVisual()
    
    if self.Callback then
        pcall(self.Callback, self.Value)
    end
end

function Toggle:Set(value)
    self.Value = value
    self:UpdateVisual()
end

function Toggle:UpdateVisual()
    local targetColor = self.Value and CONFIG.Colors.Accent or CONFIG.Colors.Main
    local targetPosition = self.Value and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    
    local tween = TweenService:Create(self.ToggleBackground, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = targetColor,
    })
    tween:Play()
    
    local knobTween = TweenService:Create(self.ToggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetPosition,
    })
    knobTween:Play()
    
    -- Update stroke color
    local stroke = self.Instance:FindFirstChildOfClass("UIStroke")
    if stroke then
        local strokeTween = TweenService:Create(stroke, TweenInfo.new(0.2), {
            Color = self.Value and CONFIG.Colors.Accent or CONFIG.Colors.Border,
        })
        strokeTween:Play()
    end
end

-- ============================================================
-- SLIDER COMPONENT
-- ============================================================

local Slider = {}
Slider.__index = Slider
setmetatable(Slider, { __index = UIComponent })

function Slider.new(parent, title, min, max, default, callback)
    local self = setmetatable({}, Slider)
    
    self.Title = title or "Slider"
    self.Min = min or 0
    self.Max = max or 100
    self.Value = default or min
    self.Callback = callback
    
    -- Main container
    self.Instance = Utility:Create("TextButton", {
        Name = "Slider_" .. self.Title,
        Parent = parent,
        Size = UDim2.new(1, -20, 0, CONFIG.DefaultHeight + 8),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Medium)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    -- Title label
    self.TitleLabel = Utility:Create("TextLabel", {
        Name = "Title",
        Parent = self.Instance,
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = CONFIG.Colors.White,
        TextSize = 14,
        Font = CONFIG.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    -- Slider background
    self.SliderBackground = Utility:Create("Frame", {
        Name = "SliderBG",
        Parent = self.Instance,
        Size = UDim2.new(0, 100, 0, 6),
        Position = UDim2.new(1, -120, 0.5, -3),
        BackgroundColor3 = CONFIG.Colors.Main,
        BorderSizePixel = 0,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Round)
    
    -- Slider fill
    self.SliderFill = Utility:Create("Frame", {
        Name = "SliderFill",
        Parent = self.SliderBackground,
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CONFIG.Colors.Accent,
        BorderSizePixel = 0,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Round)
    Utility:MakeGradient({
        CONFIG.Colors.Secondary,
        CONFIG.Colors.Accent,
    }, 90)
    
    -- Slider knob
    self.SliderKnob = Utility:Create("Frame", {
        Name = "SliderKnob",
        Parent = self.SliderBackground,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 0, 0.5, -7),
        BackgroundColor3 = CONFIG.Colors.White,
        BorderSizePixel = 0,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Round)
    
    -- Value label
    self.ValueLabel = Utility:Create("TextLabel", {
        Name = "Value",
        Parent = self.Instance,
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(1, -170, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(self.Value),
        TextColor3 = CONFIG.Colors.Accent,
        TextSize = 12,
        Font = CONFIG.Font,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    
    -- Drag logic
    local dragging = false
    
    self.Instance.MouseButton1Down:Connect(function()
        dragging = true
        self.Instance:SetAttribute("Dragging", true)
    end)
    
    self.Instance.MouseButton1Up:Connect(function()
        dragging = false
        self.Instance:SetAttribute("Dragging", false)
    end)
    
    self.Instance.MouseMoved:Connect(function(input)
        if dragging then
            local sliderPos = self.SliderBackground.AbsolutePosition
            local sliderSize = self.SliderBackground.AbsoluteSize
            local mouseX = input.Position.X
            local relativeX = (mouseX - sliderPos.X) / sliderSize.X
            relativeX = Utility:Clamp(relativeX, 0, 1)
            
            local value = self.Min + (self.Max - self.Min) * relativeX
            self:SetValue(value)
        end
    end)
    
    -- Initialize
    self:SetValue(default or min)
    
    return self
end

function Slider:SetValue(value)
    value = Utility:Clamp(value, self.Min, self.Max)
    self.Value = value
    
    local percent = (value - self.Min) / (self.Max - self.Min)
    local fillWidth = percent * 100
    local knobX = percent * 86
    
    local fillTween = TweenService:Create(self.SliderFill, TweenInfo.new(0.15), {
        Size = UDim2.new(fillWidth / 100, 0, 1, 0),
    })
    fillTween:Play()
    
    local knobTween = TweenService:Create(self.SliderKnob, TweenInfo.new(0.15), {
        Position = UDim2.new(knobX / 86, 0, 0.5, -7),
    })
    knobTween:Play()
    
    self.ValueLabel.Text = tostring(math.floor(value * 10) / 10)
    
    if self.Callback then
        pcall(self.Callback, value)
    end
end

function Slider:GetValue()
    return self.Value
end

-- ============================================================
-- DROPDOWN COMPONENT
-- ============================================================

local Dropdown = {}
Dropdown.__index = Dropdown
setmetatable(Dropdown, { __index = UIComponent })

function Dropdown.new(parent, title, items, defaultIndex, callback)
    local self = setmetatable({}, Dropdown)
    
    self.Title = title or "Dropdown"
    self.Items = items or {}
    self.Callback = callback
    self.SelectedIndex = defaultIndex or 1
    self.IsOpen = false
    
    -- Main container
    self.Instance = Utility:Create("TextButton", {
        Name = "Dropdown_" .. self.Title,
        Parent = parent,
        Size = UDim2.new(1, -20, 0, CONFIG.DefaultHeight + 8),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Medium)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    -- Title label
    self.TitleLabel = Utility:Create("TextLabel", {
        Name = "Title",
        Parent = self.Instance,
        Size = UDim2.new(0, 120, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = CONFIG.Colors.White,
        TextSize = 14,
        Font = CONFIG.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    -- Selected value label
    self.SelectedLabel = Utility:Create("TextLabel", {
        Name = "Selected",
        Parent = self.Instance,
        Size = UDim2.new(1, -160, 1, 0),
        Position = UDim2.new(0, 130, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Items[self.SelectedIndex] or "Select...",
        TextColor3 = CONFIG.Colors.Accent,
        TextSize = 12,
        Font = CONFIG.Font,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    
    -- Arrow
    self.Arrow = Utility:Create("TextLabel", {
        Name = "Arrow",
        Parent = self.Instance,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -35, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = CONFIG.Colors.White,
        TextSize = 10,
        Font = CONFIG.Font,
    })
    
    -- Dropdown list container
    self.ListContainer = Utility:Create("ScrollingFrame", {
        Name = "List",
        Parent = self.Instance,
        Size = UDim2.new(0, 200, 0, 0),
        Position = UDim2.new(1, -220, 1, 5),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = CONFIG.Colors.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Medium)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    -- List items
    for i, item in ipairs(self.Items) do
        local itemButton = Utility:Create("TextButton", {
            Name = "Item_" .. i,
            Parent = self.ListContainer,
            Size = UDim2.new(1, -10, 0, CONFIG.DefaultHeight),
            Position = UDim2.new(0, 5, 0, (i - 1) * CONFIG.DefaultHeight),
            BackgroundColor3 = i == self.SelectedIndex and CONFIG.Colors.Main or CONFIG.Colors.Secondary,
            BorderSizePixel = 0,
            Text = item,
            TextColor3 = CONFIG.Colors.White,
            TextSize = 13,
            Font = CONFIG.Font,
            AutoButtonColor = false,
        })
        Utility:MakeCorner(CONFIG.CornerRadius.Small)
        
        itemButton.MouseButton1Click:Connect(function()
            self.SelectedIndex = i
            self.SelectedLabel.Text = item
            self:Close()
            
            if self.Callback then
                pcall(self.Callback, item, i)
            end
        end)
        
        itemButton.MouseEnter:Connect(function()
            local tween = TweenService:Create(itemButton, TweenInfo.new(0.15), {
                BackgroundColor3 = CONFIG.Colors.Main,
            })
            tween:Play()
        end)
        
        itemButton.MouseLeave:Connect(function()
            local tween = TweenService:Create(itemButton, TweenInfo.new(0.15), {
                BackgroundColor3 = i == self.SelectedIndex and CONFIG.Colors.Main or CONFIG.Colors.Secondary,
            })
            tween:Play()
        end)
    end
    
    -- Set list height
    self.ListContainer.Size = UDim2.new(0, 200, 0, math.min(#self.Items * CONFIG.DefaultHeight, 150))
    
    -- Click handler
    self.Instance.MouseButton1Click:Connect(function()
        self:ToggleOpen()
    end)
    
    -- Close on outside click
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.IsOpen and not self.Instance:IsDescendantOf(Utility:GetLocalPlayer().PlayerGui) then
                -- Check if click is outside dropdown
                local mousePos = input.Position
                local absolutePos = self.Instance.AbsolutePosition
                local absoluteSize = self.Instance.AbsoluteSize
                
                local inside = mousePos.X >= absolutePos.X and mousePos.X <= absolutePos.X + absoluteSize.X and
                              mousePos.Y >= absolutePos.Y and mousePos.Y <= absolutePos.Y + absoluteSize.Y
                
                if not inside then
                    self:Close()
                end
            end
        end
    end)
    
    return self
end

function Dropdown:ToggleOpen()
    if self.IsOpen then
        self:Close()
    else
        self:Open()
    end
end

function Dropdown:Open()
    self.IsOpen = true
    self.ListContainer.Visible = true
    
    -- Update stroke
    local stroke = self.Instance:FindFirstChildOfClass("UIStroke")
    if stroke then
        local tween = TweenService:Create(stroke, TweenInfo.new(0.2), {
            Color = CONFIG.Colors.Accent,
        })
        tween:Play()
    end
    
    -- Animate arrow
    local tween = TweenService:Create(self.Arrow, TweenInfo.new(0.2), {
        Rotation = 180,
    })
    tween:Play()
    
    -- Animate list appearance
    self.ListContainer.Size = UDim2.new(0, 200, 0, 0)
    local tween2 = TweenService:Create(self.ListContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 200, 0, math.min(#self.Items * CONFIG.DefaultHeight, 150)),
    })
    tween2:Play()
end

function Dropdown:Close()
    self.IsOpen = false
    
    -- Update stroke
    local stroke = self.Instance:FindFirstChildOfClass("UIStroke")
    if stroke then
        local tween = TweenService:Create(stroke, TweenInfo.new(0.2), {
            Color = CONFIG.Colors.Border,
        })
        tween:Play()
    end
    
    -- Animate arrow
    local tween = TweenService:Create(self.Arrow, TweenInfo.new(0.2), {
        Rotation = 0,
    })
    tween:Play()
    
    -- Animate list disappearance
    local tween2 = TweenService:Create(self.ListContainer, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 200, 0, 0),
    })
    tween2:Play()
    
    task.delay(0.2, function()
        if not self.IsOpen then
            self.ListContainer.Visible = false
        end
    end)
end

function Dropdown:AddItem(item)
    table.insert(self.Items, item)
    
    local itemButton = Utility:Create("TextButton", {
        Name = "Item_" .. #self.Items,
        Parent = self.ListContainer,
        Size = UDim2.new(1, -10, 0, CONFIG.DefaultHeight),
        Position = UDim2.new(0, 5, 0, (#self.Items - 1) * CONFIG.DefaultHeight),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        BorderSizePixel = 0,
        Text = item,
        TextColor3 = CONFIG.Colors.White,
        TextSize = 13,
        Font = CONFIG.Font,
        AutoButtonColor = false,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Small)
    
    itemButton.MouseButton1Click:Connect(function()
        self.SelectedIndex = #self.Items
        self.SelectedLabel.Text = item
        self:Close()
        
        if self.Callback then
            pcall(self.Callback, item, #self.Items)
        end
    end)
end

-- ============================================================
-- BLOCK (COLLAPSIBLE SECTION) COMPONENT
-- ============================================================

local Block = {}
Block.__index = Block
setmetatable(Block, { __index = UIComponent })

function Block.new(parent, title, defaultOpen)
    local self = setmetatable({}, Block)
    
    self.Title = title or "Block"
    self.IsOpen = defaultOpen or false
    self.Elements = {}
    
    -- Main container
    self.Instance = Utility:Create("Frame", {
        Name = "Block_" .. self.Title,
        Parent = parent,
        Size = UDim2.new(1, -20, 0, CONFIG.DefaultHeight + 8),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        BorderSizePixel = 0,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Medium)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    -- Header button
    self.HeaderButton = Utility:Create("TextButton", {
        Name = "Header",
        Parent = self.Instance,
        Size = UDim2.new(1, 0, 0, CONFIG.DefaultHeight),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    })
    
    -- Title label
    self.TitleLabel = Utility:Create("TextLabel", {
        Name = "Title",
        Parent = self.HeaderButton,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = CONFIG.Colors.White,
        TextSize = 14,
        Font = CONFIG.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    -- Arrow
    self.Arrow = Utility:Create("TextLabel", {
        Name = "Arrow",
        Parent = self.HeaderButton,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -30, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = CONFIG.Colors.White,
        TextSize = 10,
        Font = CONFIG.Font,
    })
    
    -- Content container
    self.Content = Utility:Create("Frame", {
        Name = "Content",
        Parent = self.Instance,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, CONFIG.DefaultHeight),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    })
    
    -- Click handler
    self.HeaderButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    self:UpdateVisual()
    
    return self
end

function Block:AddElement(element)
    table.insert(self.Elements, element)
    
    -- Recalculate content height
    local totalHeight = 0
    for _, elem in ipairs(self.Elements) do
        totalHeight = totalHeight + elem.Instance.Size.Y.Offset + 8
    end
    
    self.Content.Size = UDim2.new(1, 0, 0, totalHeight)
    
    -- Reposition elements
    local currentY = 0
    for _, elem in ipairs(self.Elements) do
        elem.Instance.Position = UDim2.new(0, 10, 0, currentY)
        currentY = currentY + elem.Instance.Size.Y.Offset + 8
    end
    
    -- Update block size
    if self.IsOpen then
        self.Instance.Size = UDim2.new(1, -20, 0, CONFIG.DefaultHeight + totalHeight + 8)
    end
    
    return element
end

function Block:Toggle()
    self.IsOpen = not self.IsOpen
    self:UpdateVisual()
end

function Block:Open()
    self.IsOpen = true
    self:UpdateVisual()
end

function Block:Close()
    self.IsOpen = false
    self:UpdateVisual()
end

function Block:UpdateVisual()
    local contentHeight = self.Content.Size.Y.Offset
    local targetHeight = self.IsOpen and (CONFIG.DefaultHeight + contentHeight + 8) or CONFIG.DefaultHeight
    
    local tween = TweenService:Create(self.Instance, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, -20, 0, targetHeight),
    })
    tween:Play()
    
    -- Arrow rotation
    local tween2 = TweenService:Create(self.Arrow, TweenInfo.new(0.3), {
        Rotation = self.IsOpen and 180 or 0,
    })
    tween2:Play()
    
    -- Update stroke
    local stroke = self.Instance:FindFirstChildOfClass("UIStroke")
    if stroke then
        local tween3 = TweenService:Create(stroke, TweenInfo.new(0.2), {
            Color = self.IsOpen and CONFIG.Colors.Accent or CONFIG.Colors.Border,
        })
        tween3:Play()
    end
    
    -- Update block size
    if self.Instance.Parent then
        pcall(function()
            self.Instance.Parent:SetAttribute("BlockChanged", os.clock())
        end)
    end
end

-- ============================================================
-- BUTTON COMPONENT
-- ============================================================

local Button = {}
Button.__index = Button
setmetatable(Button, { __index = UIComponent })

function Button.new(parent, title, callback, iconId)
    local self = setmetatable({}, Button)
    
    self.Title = title or "Button"
    self.Callback = callback
    
    self.Instance = Utility:Create("TextButton", {
        Name = "Button_" .. self.Title,
        Parent = parent,
        Size = UDim2.new(1, -20, 0, CONFIG.DefaultHeight + 8),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Medium)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    -- Icon (if provided)
    if iconId then
        self.Icon = Utility:Create("ImageLabel", {
            Name = "Icon",
            Parent = self.Instance,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 15, 0.5, -10),
            BackgroundTransparency = 1,
            Image = "rbxassetid://" .. iconId,
        })
    end
    
    -- Title label
    self.TitleLabel = Utility:Create("TextLabel", {
        Name = "Title",
        Parent = self.Instance,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, iconId and 45 or 15, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = CONFIG.Colors.White,
        TextSize = 14,
        Font = CONFIG.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    -- Arrow
    self.Arrow = Utility:Create("TextLabel", {
        Name = "Arrow",
        Parent = self.Instance,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -30, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "▶",
        TextColor3 = CONFIG.Colors.Accent,
        TextSize = 10,
        Font = CONFIG.Font,
    })
    
    -- Click handler
    self.Instance.MouseButton1Click:Connect(function()
        if self.Callback then
            pcall(self.Callback)
        end
    end)
    
    -- Hover effect
    self.Instance.MouseEnter:Connect(function()
        local tween = TweenService:Create(self.Instance, TweenInfo.new(0.15), {
            BackgroundColor3 = CONFIG.Colors.Main,
        })
        tween:Play()
    end)
    
    self.Instance.MouseLeave:Connect(function()
        local tween = TweenService:Create(self.Instance, TweenInfo.new(0.15), {
            BackgroundColor3 = CONFIG.Colors.Secondary,
        })
        tween:Play()
    end)
    
    return self
end

-- ============================================================
-- LABEL COMPONENT
-- ============================================================

local Label = {}
Label.__index = Label
setmetatable(Label, { __index = UIComponent })

function Label.new(parent, text, size, textColor)
    local self = setmetatable({}, Label)
    
    self.Text = text or "Label"
    
    self.Instance = Utility:Create("TextLabel", {
        Name = "Label_" .. self.Text,
        Parent = parent,
        Size = UDim2.new(1, -20, 0, size or 30),
        BackgroundTransparency = 1,
        Text = self.Text,
        TextColor3 = textColor or CONFIG.Colors.White,
        TextSize = size and size - 10 or 16,
        Font = CONFIG.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    return self
end

-- ============================================================
-- NAVIGATION BAR
-- ============================================================

local NavigationBar = {}
NavigationBar.__index = NavigationBar

function NavigationBar.new(parent, onTabChange)
    local self = setmetatable({}, NavigationBar)
    
    self.Parent = parent
    self.OnTabChange = onTabChange
    self.ActiveTab = "Home"
    self.Tabs = {}
    
    -- Main bar frame
    self.Instance = Utility:Create("Frame", {
        Name = "NavigationBar",
        Parent = parent,
        Size = UDim2.new(0, 60, 0, 360),
        Position = UDim2.new(0, 10, 0.5, -180),
        BackgroundColor3 = CONFIG.Colors.Main,
        BorderSizePixel = 0,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Large)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    -- Highlight bar (animated background for active tab)
    self.HighlightBar = Utility:Create("Frame", {
        Name = "Highlight",
        Parent = self.Instance,
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        BorderSizePixel = 0,
        Transparency = 0.8,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Medium)
    
    -- Tab definitions
    local tabDefs = {
        { Name = "Home", Icon = "rbxassetid://112770735347738", Order = 1 },
        { Name = "Main", Icon = "rbxassetid://92091304135140", Order = 2 },
        { Name = "Player", Icon = "rbxassetid://125743894366007", Order = 3 },
        { Name = "LoadScript", Icon = "rbxassetid://83975792443912", Order = 4 },
        { Name = "Settings", Icon = "rbxassetid://125743894366007", Order = 5 },
        { Name = "Exit", Icon = "rbxassetid://96518596121178", Order = 6 },
    }
    
    -- Create tab buttons
    for _, tabDef in ipairs(tabDefs) do
        local tabButton = Utility:Create("TextButton", {
            Name = "Tab_" .. tabDef.Name,
            Parent = self.Instance,
            Size = UDim2.new(0, 50, 0, 50),
            Position = UDim2.new(0, 5, 0, 5 + (tabDef.Order - 1) * 55),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
        })
        
        local icon = Utility:Create("ImageLabel", {
            Name = "Icon",
            Parent = tabButton,
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(0.5, -14, 0.5, -14),
            BackgroundTransparency = 1,
            Image = tabDef.Icon,
            ImageColor3 = CONFIG.Colors.White,
        })
        
        tabButton.MouseButton1Click:Connect(function()
            if tabDef.Name == "Exit" then
                if self.OnTabChange then
                    pcall(self.OnTabChange, "Exit")
                end
            else
                self:SelectTab(tabDef.Name)
            end
        end)
        
        -- Hover effect
        tabButton.MouseEnter:Connect(function()
            if self.ActiveTab ~= tabDef.Name then
                local tween = TweenService:Create(self.HighlightBar, TweenInfo.new(0.2), {
                    Position = UDim2.new(0, 5, 0, 5 + (tabDef.Order - 1) * 55),
                })
                tween:Play()
            end
        end)
        
        tabButton.MouseLeave:Connect(function()
            -- Return highlight to active tab
            self:UpdateHighlight()
        end)
        
        table.insert(self.Tabs, {
            Name = tabDef.Name,
            Button = tabButton,
            Icon = icon,
            Order = tabDef.Order,
        })
    end
    
    -- Initialize with Home tab
    self:SelectTab("Home")
    
    return self
end

function NavigationBar:SelectTab(tabName)
    self.ActiveTab = tabName
    
    -- Update highlight position
    self:UpdateHighlight()
    
    -- Update icon colors
    for _, tab in ipairs(self.Tabs) do
        local iconColor = tab.Name == tabName and CONFIG.Colors.Accent or CONFIG.Colors.White
        local tween = TweenService:Create(tab.Icon, TweenInfo.new(0.2), {
            ImageColor3 = iconColor,
        })
        tween:Play()
    end
    
    -- Call callback
    if self.OnTabChange then
        pcall(self.OnTabChange, tabName)
    end
end

function NavigationBar:UpdateHighlight()
    for _, tab in ipairs(self.Tabs) do
        if tab.Name == self.ActiveTab then
            local tween = TweenService:Create(self.HighlightBar, TweenInfo.new(0.2), {
                Position = UDim2.new(0, 5, 0, 5 + (tab.Order - 1) * 55),
            })
            tween:Play()
            break
        end
    end
end

function NavigationBar:GetActiveTab()
    return self.ActiveTab
end

-- ============================================================
-- MAIN UI MANAGER
-- ============================================================

local SkyLineUI = {}
SkyLineUI.__index = SkyLineUI

function SkyLineUI.new()
    local self = setmetatable({}, SkyLineUI)
    
    self.ScreenGui = nil
    self.PlayerGui = nil
    self.MainFrame = nil
    self.NavigationBar = nil
    self.Tabs = {}
    self.ActiveTab = "Home"
    self.IsVisible = true
    self.Theme = CONFIG.Theme.Default
    self.Settings = {}
    self.Settings.Enabled = true
    
    -- Create default settings
    self.Settings = {
        DisableHeavyEffects = false,
        Theme = "Default",
        AutoSave = true,
        CurrentPreset = nil,
    }
    
    return self
end

function SkyLineUI:Create()
    local success, err = pcall(function()
        self.PlayerGui = Utility:GetLocalPlayer():WaitForChild("PlayerGui")
        
        self.ScreenGui = Utility:Create("ScreenGui", {
            Name = "SkyLineHub",
            Parent = self.PlayerGui,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        
        -- Create glow background
        local glowBackground = Utility:Create("Frame", {
            Name = "GlowBackground",
            Parent = self.ScreenGui,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = -10,
        })
        
        -- Create glow blobs
        self.GlowBlobs = {}
        for i = 1, 8 do
            local blob = Utility:Create("Frame", {
                Name = "GlowBlob" .. i,
                Parent = glowBackground,
                Size = UDim2.new(0, 200, 0, 200),
                Position = UDim2.new(0, math.random(-100, 900), 0, math.random(-100, 500)),
                BackgroundColor3 = i % 2 == 0 and self.Theme.Glow1 or self.Theme.Glow2,
                BorderSizePixel = 0,
                Transparency = 0.9,
            })
            Utility:MakeCorner(CONFIG.CornerRadius.Round)
            
            -- Animate glow
            local tween = TweenService:Create(blob, TweenInfo.new(5 + i * 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = UDim2.new(0, math.random(-100, 900), 0, math.random(-100, 500)),
                Size = UDim2.new(0, 150 + i * 20, 0, 150 + i * 20),
                Transparency = 0.7 + math.random() * 0.2,
            })
            tween:Play()
            tween:Repeat()
            
            table.insert(self.GlowBlobs, blob)
        end
        
        -- Create main frame
        self.MainFrame = Utility:Create("Frame", {
            Name = "Main",
            Parent = self.ScreenGui,
            Size = UDim2.new(0, 800, 0, 500),
            Position = UDim2.new(0.5, -400, 0.5, -250),
            BackgroundColor3 = CONFIG.Colors.Main,
            BorderSizePixel = 0,
            Visible = false,
        })
        Utility:MakeCorner(CONFIG.CornerRadius.Large)
        Utility:MakeStroke(CONFIG.Colors.Border, 2)
        
        -- Create navigation bar
        self.NavigationBar = NavigationBar.new(self.MainFrame, function(tabName)
            self:SwitchTab(tabName)
        end)
        
        -- Create tab content containers
        for _, tabName in ipairs({"Home", "Main", "Player", "LoadScript", "Settings"}) do
            local tabFrame = Utility:Create("Frame", {
                Name = "Tab_" .. tabName,
                Parent = self.MainFrame,
                Size = UDim2.new(1, -100, 1, -20),
                Position = UDim2.new(0, 90, 0, 10),
                BackgroundColor3 = CONFIG.Colors.Secondary,
                BorderSizePixel = 0,
                Visible = false,
            })
            Utility:MakeCorner(CONFIG.CornerRadius.Large)
            Utility:MakeStroke(CONFIG.Colors.Border, 1)
            
            self.Tabs[tabName] = tabFrame
        end
        
        -- Create Exit button and collapse functionality
        self:CreateExitButton()
        
        -- Show loading screen
        LoadingScreen:Show(self.ScreenGui, function()
            self:ShowUI()
        end)
    end)
    
    if not success then
        warn("SkyLine UI Error: " .. tostring(err))
    end
    
    return self
end

function SkyLineUI:ShowUI()
    self.MainFrame.Visible = true
    
    -- Animate main frame entrance
    local tween = TweenService:Create(self.MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = 1,
        Transparency = 0,
    })
    tween:Play()
    
    -- Show Home tab by default
    self:SwitchTab("Home")
end

function SkyLineUI:SwitchTab(tabName)
    if tabName == "Exit" then
        self:HideUI()
        return
    end
    
    if self.ActiveTab == tabName then
        return
    end
    
    -- Hide current tab
    local oldTab = self.Tabs[self.ActiveTab]
    if oldTab then
        local tween = TweenService:Create(oldTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Scale = 0.8,
            Transparency = 1,
        })
        tween:Play()
        tween.Completed:Connect(function()
            oldTab.Visible = false
        end)
    end
    
    -- Show new tab
    local newTab = self.Tabs[tabName]
    if newTab then
        newTab.Visible = true
        newTab.Scale = 0.8
        newTab.Transparency = 1
        
        local tween = TweenService:Create(newTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Scale = 1,
            Transparency = 0,
        })
        tween:Play()
    end
    
    self.ActiveTab = tabName
end

function SkyLineUI:HideUI()
    self.IsVisible = false
    
    -- Animate main frame out
    local tween = TweenService:Create(self.MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(-0.5, -400, 0.5, -250),
        Transparency = 1,
    })
    tween:Play()
    tween.Completed:Connect(function()
        self.MainFrame.Visible = false
    end)
    
    -- Show expand button
    self.ExpandButton.Visible = true
end

function SkyLineUI:ShowUIFromHidden()
    self.IsVisible = true
    
    self.MainFrame.Visible = true
    self.MainFrame.Position = UDim2.new(-0.5, -400, 0.5, -250)
    self.MainFrame.Transparency = 1
    
    local tween = TweenService:Create(self.MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -400, 0.5, -250),
        Transparency = 0,
    })
    tween:Play()
    
    -- Hide expand button
    self.ExpandButton.Visible = false
end

function SkyLineUI:CreateExitButton()
    -- Collapse arrow button (appears when UI is hidden)
    self.ExpandButton = Utility:Create("TextButton", {
        Name = "ExpandButton",
        Parent = self.ScreenGui,
        Size = UDim2.new(0, 30, 0, 60),
        Position = UDim2.new(0, 5, 0.5, -30),
        BackgroundColor3 = CONFIG.Colors.Main,
        BorderSizePixel = 0,
        Text = "»",
        TextColor3 = CONFIG.Colors.White,
        TextSize = 18,
        Font = CONFIG.FontBold,
        Visible = false,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Medium)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    self.ExpandButton.MouseButton1Click:Connect(function()
        self:ShowUIFromHidden()
    end)
end

-- ============================================================
-- TAB CONTENT BUILDERS
-- ============================================================

function SkyLineUI:BuildHomeTab()
    local homeTab = self.Tabs["Home"]
    
    -- Create profile section
    local profileFrame = Utility:Create("Frame", {
        Name = "Profile",
        Parent = homeTab,
        Size = UDim2.new(1, -20, 0, 80),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = CONFIG.Colors.Main,
        BorderSizePixel = 0,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Medium)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    -- Profile avatar
    local avatar = Utility:Create("ImageLabel", {
        Name = "Avatar",
        Parent = profileFrame,
        Size = UDim2.new(0, 60, 0, 60),
        Position = UDim2.new(0, 10, 0.5, -30),
        BackgroundColor3 = CONFIG.Colors.Border,
        BorderSizePixel = 0,
        Image = "rbxassetid://12020657755",
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Round)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    -- Player info
    local infoFrame = Utility:Create("Frame", {
        Name = "Info",
        Parent = profileFrame,
        Size = UDim2.new(1, -90, 1, -10),
        Position = UDim2.new(0, 80, 0, 5),
        BackgroundTransparency = 1,
    })
    
    local playerLabel = Utility:Create("TextLabel", {
        Name = "PlayerName",
        Parent = infoFrame,
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = "Username: " .. (Utility:GetLocalPlayer().Name or "Unknown"),
        TextColor3 = CONFIG.Colors.White,
        TextSize = 16,
        Font = CONFIG.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local idLabel = Utility:Create("TextButton", {
        Name = "PlayerID",
        Parent = infoFrame,
        Size = UDim2.new(0, 200, 0, 20),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundTransparency = 1,
        Text = "ID: " .. tostring(Utility:GetLocalPlayer().UserId),
        TextColor3 = CONFIG.Colors.Accent,
        TextSize = 13,
        Font = CONFIG.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    idLabel.MouseButton1Click:Connect(function()
        Utility:CopyToClipboard(tostring(Utility:GetLocalPlayer().UserId))
        -- Show notification
        self:ShowNotification("Successfully copied!")
    end)
    
    -- Stats
    local statsFrame = Utility:Create("Frame", {
        Name = "Stats",
        Parent = profileFrame,
        Size = UDim2.new(0, 150, 1, 0),
        Position = UDim2.new(1, -160, 0, 0),
        BackgroundTransparency = 1,
    })
    
    local pingLabel = Utility:Create("TextLabel", {
        Name = "Ping",
        Parent = statsFrame,
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = "Ping: 0 ms",
        TextColor3 = CONFIG.Colors.White,
        TextSize = 14,
        Font = CONFIG.Font,
    })
    
    local fpsLabel = Utility:Create("TextLabel", {
        Name = "FPS",
        Parent = statsFrame,
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundTransparency = 1,
        Text = "FPS: 60",
        TextColor3 = CONFIG.Colors.White,
        TextSize = 14,
        Font = CONFIG.Font,
    })
    
    -- Real-time updates
    task.spawn(function()
        local pingText = pingLabel
        local fpsText = fpsLabel
        local lastFPS = 0
        local frames = 0
        local time = os.clock()
        
        while true do
            task.wait(1)
            frames = frames + 1
            
            local currentTime = os.clock()
            if currentTime - time >= 1 then
                lastFPS = frames
                frames = 0
                time = currentTime
                
                pcall(function()
                    fpsText.Text = "FPS: " .. tostring(lastFPS)
                end)
            end
            
            pcall(function()
                local ping = game:GetService("Stats"):FindFirstChild("Network") and 
                           game:GetService("Stats").Network:FindFirstChild("Ping") or nil
                if ping then
                    pingText.Text = "Ping: " .. tostring(math.floor(ping.Value * 1000)) .. " ms"
                end
            end)
        end
    end)
    
    -- Recent activity section
    local activityFrame = Utility:Create("Frame", {
        Name = "RecentActivity",
        Parent = homeTab,
        Size = UDim2.new(1, -20, 0, 200),
        Position = UDim2.new(0, 10, 0, 100),
        BackgroundColor3 = CONFIG.Colors.Main,
        BorderSizePixel = 0,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Medium)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    local activityTitle = Utility:Create("TextLabel", {
        Name = "Title",
        Parent = activityFrame,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = "Recent Activity",
        TextColor3 = CONFIG.Colors.White,
        TextSize = 16,
        Font = CONFIG.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local activityList = Utility:Create("ScrollingFrame", {
        Name = "ActivityList",
        Parent = activityFrame,
        Size = UDim2.new(1, -20, 1, -40),
        Position = UDim2.new(0, 10, 0, 40),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = CONFIG.Colors.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    })
    
    -- Add some activity items
    local activities = {
        "Loaded SkyLine Hub",
        "Welcome to the hub!",
        "Scripts are ready to use",
    }
    
    for i, activity in ipairs(activities) do
        local item = Utility:Create("TextLabel", {
            Name = "Item" .. i,
            Parent = activityList,
            Size = UDim2.new(1, 0, 0, 25),
            Position = UDim2.new(0, 0, 0, (i - 1) * 28),
            BackgroundTransparency = 1,
            Text = "• " .. activity,
            TextColor3 = CONFIG.Colors.TextDim,
            TextSize = 13,
            Font = CONFIG.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
    end
end

function SkyLineUI:BuildMainTab()
    local mainTab = self.Tabs["Main"]
    
    -- Create a scrolling frame for content
    local scrollFrame = Utility:Create("ScrollingFrame", {
        Name = "Content",
        Parent = mainTab,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = CONFIG.Colors.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    })
    
    -- Toggle example
    local toggle1 = Toggle.new(scrollFrame, "Example Toggle", false, function(value)
        print("Toggle changed to:", value)
    end)
    toggle1.Instance.Position = UDim2.new(0, 10, 0, 10)
    
    -- Slider example
    local slider1 = Slider.new(scrollFrame, "Example Slider", 0, 100, 50, function(value)
        print("Slider value:", value)
    end)
    slider1.Instance.Position = UDim2.new(0, 10, 0, 60)
    
    -- Dropdown example
    local dropdown1 = Dropdown.new(scrollFrame, "Example Dropdown", {"Option 1", "Option 2", "Option 3", "Option 4"}, 1, function(item, index)
        print("Dropdown selected:", item, index)
    end)
    dropdown1.Instance.Position = UDim2.new(0, 10, 0, 110)
    
    -- Block example
    local block1 = Block.new(scrollFrame, "Example Block", false)
    block1.Instance.Position = UDim2.new(0, 10, 0, 160)
    
    local blockToggle = Toggle.new(block1.Content, "Inside Block Toggle", false, function(value)
        print("Block toggle:", value)
    end)
    
    local blockSlider = Slider.new(block1.Content, "Inside Block Slider", 0, 10, 5, function(value)
        print("Block slider:", value)
    end)
    
    block1:AddElement(blockToggle)
    block1:AddElement(blockSlider)
end

function SkyLineUI:BuildPlayerTab()
    local playerTab = self.Tabs["Player"]
    
    local scrollFrame = Utility:Create("ScrollingFrame", {
        Name = "Content",
        Parent = playerTab,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = CONFIG.Colors.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    })
    
    local yPos = 10
    
    -- Speed Slider + Toggle
    local speedToggle = Toggle.new(scrollFrame, "Enable Speed", false, function(value)
        if value then
            -- Enable speed boost
            print("Speed boost enabled")
        else
            -- Disable speed boost
            print("Speed boost disabled")
        end
    end)
    speedToggle.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    local speedSlider = Slider.new(scrollFrame, "Speed Value", 16, 100, 16, function(value)
        -- Set walk speed
        pcall(function()
            local player = Utility:GetLocalPlayer()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.WalkSpeed = value
            end
        end)
    end)
    speedSlider.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    -- Jump Power Slider + Toggle
    local jumpToggle = Toggle.new(scrollFrame, "Custom Jump", false, function(value)
        print("Custom jump:", value)
    end)
    jumpToggle.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    local jumpSlider = Slider.new(scrollFrame, "Jump Power", 50, 250, 50, function(value)
        pcall(function()
            local player = Utility:GetLocalPlayer()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.JumpPower = value
            end
        end)
    end)
    jumpSlider.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    -- ESP Toggle
    local espToggle = Toggle.new(scrollFrame, "Highlight ESP", false, function(value)
        if value then
            -- Enable ESP
            print("ESP enabled")
        else
            -- Disable ESP
            print("ESP disabled")
        end
    end)
    espToggle.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    -- FPS Boost Toggle
    local fpsToggle = Toggle.new(scrollFrame, "FPS Boost", false, function(value)
        if value then
            -- Enable FPS boost
            print("FPS Boost enabled")
        else
            -- Disable FPS boost
            print("FPS Boost disabled")
        end
    end)
    fpsToggle.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    -- Noclip Toggle
    local noclipToggle = Toggle.new(scrollFrame, "Noclip", false, function(value)
        print("Noclip:", value)
    end)
    noclipToggle.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    -- Infinite Jump Toggle
    local infiniteJumpToggle = Toggle.new(scrollFrame, "Infinite Jump", false, function(value)
        print("Infinite Jump:", value)
    end)
    infiniteJumpToggle.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    -- Anti AFK Toggle
    local antiAfkToggle = Toggle.new(scrollFrame, "Anti AFK", false, function(value)
        print("Anti AFK:", value)
    end)
    antiAfkToggle.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    -- Spin Toggle + Slider
    local spinToggle = Toggle.new(scrollFrame, "Spin", false, function(value)
        print("Spin:", value)
    end)
    spinToggle.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    local spinSlider = Slider.new(scrollFrame, "Spin Speed", 1, 10, 5, function(value)
        print("Spin speed:", value)
    end)
    spinSlider.Instance.Position = UDim2.new(0, 10, 0, yPos)
end

function SkyLineUI:BuildLoadScriptTab()
    local loadTab = self.Tabs["LoadScript"]
    
    local scrollFrame = Utility:Create("ScrollingFrame", {
        Name = "Content",
        Parent = loadTab,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = CONFIG.Colors.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    })
    
    local scripts = {
        { Name = "Universal Script", Callback = function() print("Running Universal Script") end },
        { Name = "ESP Script", Callback = function() print("Running ESP Script") end },
        { Name = "Aimbot Script", Callback = function() print("Running Aimbot Script") end },
        { Name = "Teleport Script", Callback = function() print("Running Teleport Script") end },
        { Name = "Fly Script", Callback = function() print("Running Fly Script") end },
    }
    
    local yPos = 10
    
    for _, script in ipairs(scripts) do
        local button = Button.new(scrollFrame, script.Name, script.Callback)
        button.Instance.Position = UDim2.new(0, 10, 0, yPos)
        yPos = yPos + 44
    end
end

function SkyLineUI:BuildSettingsTab()
    local settingsTab = self.Tabs["Settings"]
    
    local scrollFrame = Utility:Create("ScrollingFrame", {
        Name = "Content",
        Parent = settingsTab,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = CONFIG.Colors.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    })
    
    local yPos = 10
    
    -- Disable Heavy Effects Toggle
    local heavyFxToggle = Toggle.new(scrollFrame, "Disable Heavy Effects", self.Settings.DisableHeavyEffects, function(value)
        self.Settings.DisableHeavyEffects = value
        CONFIG.DisableHeavyEffects = value
    end)
    heavyFxToggle.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    -- Theme Dropdown
    local themeDropdown = Dropdown.new(scrollFrame, "Theme", {"Default", "Purple", "Orange"}, 1, function(theme, index)
        self.Theme = CONFIG.Theme[theme]
        self:ApplyTheme()
    end)
    themeDropdown.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    -- Save Settings Button
    local saveButton = Button.new(scrollFrame, "Save Settings", function()
        local name = "DefaultPreset"
        self.Settings.CurrentPreset = name
        self:SaveSettings(name)
        self:ShowNotification("Settings saved as '" .. name .. "'")
    end)
    saveButton.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    -- Load Settings Dropdown
    local loadDropdown = Dropdown.new(scrollFrame, "Load Settings", {"DefaultPreset"}, 1, function(preset)
        self:LoadSettings(preset)
    end)
    loadDropdown.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    -- Auto Save Toggle
    local autoSaveToggle = Toggle.new(scrollFrame, "Auto Save Settings", self.Settings.AutoSave, function(value)
        self.Settings.AutoSave = value
    end)
    autoSaveToggle.Instance.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 44
    
    -- Destroy GUI Button
    local destroyButton = Button.new(scrollFrame, "Destroy GUI", function()
        self:Destroy()
    end)
    destroyButton.Instance.Position = UDim2.new(0, 10, 0, yPos)
end

function SkyLineUI:ApplyTheme()
    -- Update accent colors throughout UI
    CONFIG.Colors.Accent = self.Theme.Accent
    
    -- Update glow blobs
    for i, blob in ipairs(self.GlowBlobs) do
        pcall(function()
            blob.BackgroundColor3 = i % 2 == 0 and self.Theme.Glow1 or self.Theme.Glow2
        end)
    end
end

function SkyLineUI:ShowNotification(message)
    local notification = Utility:Create("TextLabel", {
        Name = "Notification",
        Parent = self.ScreenGui,
        Size = UDim2.new(0, 200, 0, 40),
        Position = UDim2.new(0.5, -100, 0, 10),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        BorderSizePixel = 0,
        Text = message or "Notification",
        TextColor3 = CONFIG.Colors.White,
        TextSize = 14,
        Font = CONFIG.Font,
        ZIndex = 100,
    })
    Utility:MakeCorner(CONFIG.CornerRadius.Medium)
    Utility:MakeStroke(CONFIG.Colors.Border, 1)
    
    -- Animate notification
    local tween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -100, 0, 50),
    })
    tween:Play()
    
    task.delay(3, function()
        local tween2 = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -100, 0, -40),
            Transparency = 1,
        })
        tween2:Play()
        tween2.Completed:Connect(function()
            Utility:SafeDestroy(notification)
        end)
    end)
end

function SkyLineUI:SaveSettings(name)
    local success, err = pcall(function()
        local settings = {
            Theme = self.Settings.Theme or "Default",
            AutoSave = self.Settings.AutoSave,
            DisableHeavyEffects = self.Settings.DisableHeavyEffects,
            Toggles = {},
            Sliders = {},
        }
        
        -- Save all toggle states
        for tabName, tab in pairs(self.Tabs) do
            local toggles = tab:FindFirstChild("Content") and 
                          tab.Content:FindFirstChild("Toggles") or nil
        end
        
        -- For now just save settings
        if not isfolder("SkyLineHub") then
            makefolder("SkyLineHub")
        end
        
        writefile("SkyLineHub/" .. name .. ".json", game:GetService("HttpService"):JSONEncode(settings))
    end)
    
    if not success then
        warn("Failed to save settings: " .. tostring(err))
    end
end

function SkyLineUI:LoadSettings(name)
    local success, data = pcall(function()
        local content = readfile("SkyLineHub/" .. name .. ".json")
        return game:GetService("HttpService"):JSONDecode(content)
    end)
    
    if success and data then
        self.Settings.Theme = data.Theme or "Default"
        self.Settings.AutoSave = data.AutoSave or true
        self.Settings.DisableHeavyEffects = data.DisableHeavyEffects or false
        self:ApplyTheme()
    end
end

function SkyLineUI:Destroy()
    Utility:SafeDestroy(self.ScreenGui)
    self.ScreenGui = nil
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function SkyLine:Create()
    local ui = SkyLineUI.new()
    ui:Create()
    
    -- Build all tabs
    ui:BuildHomeTab()
    ui:BuildMainTab()
    ui:BuildPlayerTab()
    ui:BuildLoadScriptTab()
    ui:BuildSettingsTab()
    
    return ui
end

function SkyLine:CreateWindow(config)
    config = config or {}
    
    local ui = self:Create()
    
    -- Apply custom config
    if config.Theme then
        ui.Theme = CONFIG.Theme[config.Theme] or CONFIG.Theme.Default
        ui:ApplyTheme()
    end
    
    return ui
end

return SkyLine
