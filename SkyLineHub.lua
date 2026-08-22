--[[
    SkyLine Hub UI Library
    Version: 1.0.0
    Author: SkyLine Team
    Description: Production-ready UI library for Roblox exploits
]]

-- ============================================
-- CONFIGURATION
-- ============================================
local SkyLineConfig = {
    Fonts = {
        Main = Enum.Font.Gotham,
        Bold = Enum.Font.GothamBold,
        Medium = Enum.Font.GothamMedium,
        Semibold = Enum.Font.GothamSemibold
    },
    Colors = {
        Background = Color3.fromRGB(34, 49, 69),
        Secondary = Color3.fromRGB(52, 65, 83),
        Border = Color3.fromRGB(67, 85, 109),
        Accent = Color3.fromRGB(91, 196, 203),
        AccentDark = Color3.fromRGB(60, 140, 150),
        White = Color3.fromRGB(255, 255, 255),
        Black = Color3.fromRGB(0, 0, 0),
        Transparent = Color3.fromRGB(0, 0, 0)
    },
    Animations = {
        Duration = 0.3,
        Easing = Enum.EasingStyle.Quad,
        EasingDirection = Enum.EasingDirection.Out
    }
}

-- ============================================
-- UTILITY MODULE
-- ============================================
local Utility = {}
Utility.__index = Utility

function Utility.new()
    local self = setmetatable({}, Utility)
    return self
end

function Utility:Create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    return instance
end

function Utility:CreateUI(className, properties)
    local instance = self:Create(className, properties)
    instance.Parent = self.Main
    return instance
end

function Utility:CreateCorner(parent, radius)
    local corner = self:Create("UICorner", {
        CornerRadius = UDim.new(radius, 0)
    })
    corner.Parent = parent
    return corner
end

function Utility:CreateStroke(parent, color, thickness, transparency)
    local stroke = self:Create("UIStroke", {
        Color = color or SkyLineConfig.Colors.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0
    })
    stroke.Parent = parent
    return stroke
end

function Utility:CreateGradient(parent, color1, color2, rotation)
    local gradient = self:Create("UIGradient", {
        Color = ColorSequence.new(color1, color2),
        Rotation = rotation or 90
    })
    gradient.Parent = parent
    return gradient
end

function Utility:CreateLayout(parent, type, properties)
    local layout = self:Create(type, properties or {})
    layout.Parent = parent
    return layout
end

function Utility:CreatePADDING(parent, padding)
    local pad = self:Create("UIPadding", {
        PaddingTop = UDim.new(0, padding or 0),
        PaddingBottom = UDim.new(0, padding or 0),
        PaddingLeft = UDim.new(0, padding or 0),
        PaddingRight = UDim.new(0, padding or 0)
    })
    pad.Parent = parent
    return pad
end

function Utility:CreateConstraint(parent, type, properties)
    local constraint = self:Create(type, properties or {})
    constraint.Parent = parent
    return constraint
end

function Utility:Tween(object, properties, duration, easing, direction)
    local tweenInfo = TweenInfo.new(
        duration or SkyLineConfig.Animations.Duration,
        easing or SkyLineConfig.Animations.Easing,
        direction or SkyLineConfig.Animations.EasingDirection
    )
    local tween = game:GetService("TweenService"):Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

function Utility:SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[SkyLine Hub] Error:", result)
    end
    return success, result
end

function Utility:CopyToClipboard(text)
    local success = pcall(function()
        setclipboard(tostring(text))
    end)
    return success
end

function Utility:GetMouse()
    return game:GetService("Players").LocalPlayer:GetMouse()
end

function Utility:GetViewportSize()
    return game:GetService("Players").LocalPlayer:PlayerGui:GetBoundingBox()
end

-- ============================================
-- ANIMATION MODULE
-- ============================================
local AnimationManager = {}
AnimationManager.__index = AnimationManager

function AnimationManager.new()
    local self = setmetatable({}, AnimationManager)
    self.ActiveTweens = {}
    return self
end

function AnimationManager:PlaySlideIn(object, properties, delay)
    local tweenInfo = TweenInfo.new(
        properties.Duration or 0.5,
        properties.Easing or Enum.EasingStyle.Quad,
        properties.Direction or Enum.EasingDirection.Out,
        delay or 0
    )
    
    local tween = game:GetService("TweenService"):Create(object, tweenInfo, properties.Target)
    tween:Play()
    
    table.insert(self.ActiveTweens, tween)
    
    tween.Completed:Connect(function()
        for i, t in ipairs(self.ActiveTweens) do
            if t == tween then
                table.remove(self.ActiveTweens, i)
                break
            end
        end
    end)
    
    return tween
end

function AnimationManager:CancelAll()
    for _, tween in ipairs(self.ActiveTweens) do
        pcall(function() tween:Cancel() end)
    end
    self.ActiveTweens = {}
end

-- ============================================
-- NOTIFICATION MODULE
-- ============================================
local NotificationManager = {}
NotificationManager.__index = NotificationManager

function NotificationManager.new(parent)
    local self = setmetatable({}, NotificationManager)
    self.Parent = parent
    self.Notifications = {}
    return self
end

function NotificationManager:Show(title, message, duration)
    local notification = Utility:Create("Frame", {
        Size = UDim2.new(0, 350, 0, 100),
        Position = UDim2.new(1, -380, 0, 20),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        BorderSizePixel = 0,
        ZIndex = 999
    })
    notification.Parent = self.Parent
    
    Utility:CreateCorner(notification, 0.15)
    Utility:CreateStroke(notification, SkyLineConfig.Colors.Border, 2)
    
    local titleLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Text = title or "Notification",
        Font = SkyLineConfig.Fonts.Bold,
        TextSize = 14,
        TextColor3 = SkyLineConfig.Colors.White
    })
    titleLabel.Parent = notification
    
    local messageLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 50),
        Position = UDim2.new(0, 10, 0, 40),
        BackgroundTransparency = 1,
        Text = message or "",
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 12,
        TextColor3 = SkyLineConfig.Colors.Border,
        TextWrapped = true
    })
    messageLabel.Parent = notification
    
    -- Animate in
    notification.Position = UDim2.new(1, -380, 0, 20)
    Utility:Tween(notification, {
        Position = UDim2.new(1, -380, 0, 20)
    }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    -- Auto destroy
    game:GetService("Debris"):AddItem(notification, duration or 3)
end

-- ============================================
-- LOADING SCREEN
-- ============================================
local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

function LoadingScreen.new(main)
    local self = setmetatable({}, LoadingScreen)
    self.Main = main
    self.LoadingFrame = nil
    self.Balls = {}
    return self
end

function LoadingScreen:Create()
    -- Main loading frame
    self.LoadingFrame = Utility:Create("Frame", {
        Size = UDim2.new(0, 400, 0, 300),
        Position = UDim2.new(0.5, -200, 0.5, -150),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        BorderSizePixel = 0,
        ZIndex = 1000,
        Visible = true
    })
    self.LoadingFrame.Parent = self.Main
    
    Utility:CreateCorner(self.LoadingFrame, 0.15)
    Utility:CreateStroke(self.LoadingFrame, SkyLineConfig.Colors.Border, 2)
    
    -- Title
    local title = Utility:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 80),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundTransparency = 1,
        Text = "SkyLine Hub",
        Font = SkyLineConfig.Fonts.Bold,
        TextSize = 40,
        TextColor3 = SkyLineConfig.Colors.White,
        TextStrokeTransparency = 0.8,
        TextStrokeColor3 = SkyLineConfig.Colors.Accent
    })
    title.Parent = self.LoadingFrame
    
    -- Subtitle
    local subtitle = Utility:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 130),
        BackgroundTransparency = 1,
        Text = "Loading...",
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 14,
        TextColor3 = SkyLineConfig.Colors.Border
    })
    subtitle.Parent = self.LoadingFrame
    
    -- Loading balls wave
    local ballsContainer = Utility:Create("Frame", {
        Size = UDim2.new(0, 200, 0, 30),
        Position = UDim2.new(0.5, -100, 0, 190),
        BackgroundTransparency = 1
    })
    ballsContainer.Parent = self.LoadingFrame
    
    for i = 1, 9 do
        local ball = Utility:Create("Frame", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, i * 20, 0, 0),
            BackgroundColor3 = SkyLineConfig.Colors.Accent,
            BorderSizePixel = 0
        })
        ball.Parent = ballsContainer
        Utility:CreateCorner(ball, 1)
        
        table.insert(self.Balls, ball)
    end
    
    -- Animate loading balls
    for i, ball in ipairs(self.Balls) do
        task.delay(i * 0.05, function()
            Utility:Tween(ball, {
                Position = UDim2.new(0, i * 20, 0, -10),
                Size = UDim2.new(0, 25, 0, 25)
            }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            
            task.delay(0.3, function()
                Utility:Tween(ball, {
                    Position = UDim2.new(0, i * 20, 0, 0),
                    Size = UDim2.new(0, 20, 0, 20)
                }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
            end)
        end)
    end
    
    -- Initial animation: scale from 0.7 to 1
    self.LoadingFrame.Scale = Vector2.new(0.7, 0.7)
    self.LoadingFrame.Transparency = 1
    
    Utility:Tween(self.LoadingFrame, {
        Scale = Vector2.new(1, 1),
        Transparency = 0
    }, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function LoadingScreen:Destroy()
    if self.LoadingFrame then
        Utility:Tween(self.LoadingFrame, {
            Transparency = 1,
            Scale = Vector2.new(0.7, 0.7)
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        
        task.delay(0.3, function()
            self.LoadingFrame:Destroy()
        end)
    end
end

-- ============================================
-- AMBIENT GLOW EFFECT
-- ============================================
local AmbientGlow = {}
AmbientGlow.__index = AmbientGlow

function AmbientGlow.new(main)
    local self = setmetatable({}, AmbientGlow)
    self.Main = main
    self.GlowFrames = {}
    self.Enabled = true
    return self
end

function AmbientGlow:Create()
    -- Create edge glow frames
    local edges = {
        {Size = UDim2.new(1, 0, 0, 100), Position = UDim2.new(0, 0, 0, 0), Color = Color3.fromRGB(75, 0, 130)},
        {Size = UDim2.new(1, 0, 0, 100), Position = UDim2.new(0, 0, 1, -100), Color = Color3.fromRGB(50, 100, 150)},
        {Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(0, 0, 0, 0), Color = Color3.fromRGB(100, 50, 150)},
        {Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(1, -100, 0, 0), Color = Color3.fromRGB(50, 150, 100)},
        {Size = UDim2.new(0, 200, 0, 100), Position = UDim2.new(0, -100, 0, 0), Color = Color3.fromRGB(75, 0, 130)},
        {Size = UDim2.new(0, 200, 0, 100), Position = UDim2.new(1, -100, 0, 0), Color = Color3.fromRGB(50, 100, 150)},
        {Size = UDim2.new(0, 100, 0, 200), Position = UDim2.new(0, 0, 1, -200), Color = Color3.fromRGB(100, 50, 150)},
        {Size = UDim2.new(0, 100, 0, 200), Position = UDim2.new(1, -100, 1, -200), Color = Color3.fromRGB(50, 150, 100)}
    }
    
    for i, edge in ipairs(edges) do
        local glowFrame = Utility:Create("Frame", {
            Size = edge.Size,
            Position = edge.Position,
            BackgroundColor3 = edge.Color,
            BorderSizePixel = 0,
            ZIndex = 0,
            Transparency = 0.8,
            BackgroundTransparency = 0.8
        })
        glowFrame.Parent = self.Main
        
        -- Soften with gradient
        local gradient = Utility:Create("UIGradient", {
            Color = ColorSequence.new(edge.Color, Color3.fromRGB(0, 0, 0)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.9),
                NumberSequenceKeypoint.new(1, 1)
            })
        })
        gradient.Parent = glowFrame
        
        table.insert(self.GlowFrames, glowFrame)
        
        -- Animate glow
        task.delay(i * 0.2, function()
            self:AnimateGlow(glowFrame, edge.Color)
        end)
    end
end

function AmbientGlow:AnimateGlow(frame, baseColor)
    if not self.Enabled then return end
    
    local targetColor = baseColor:Lerp(SkyLineConfig.Colors.Accent, 0.3)
    
    Utility:Tween(frame, {
        Transparency = 0.5,
        BackgroundColor3 = targetColor
    }, 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    
    task.delay(2, function()
        if not frame.Parent then return end
        Utility:Tween(frame, {
            Transparency = 0.8,
            BackgroundColor3 = baseColor
        }, 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        
        task.delay(2, function()
            self:AnimateGlow(frame, baseColor)
        end)
    end)
end

function AmbientGlow:SetEnabled(enabled)
    self.Enabled = enabled
    if not enabled then
        for _, frame in ipairs(self.GlowFrames) do
            frame.Transparency = 1
        end
    else
        for i, frame in ipairs(self.GlowFrames) do
            frame.Transparency = 0.8
            task.delay(i * 0.2, function()
                self:AnimateGlow(frame, frame.BackgroundColor3)
            end)
        end
    end
end

-- ============================================
-- NAVIGATION BAR
-- ============================================
local NavigationBar = {}
NavigationBar.__index = NavigationBar

function NavigationBar.new(main)
    local self = setmetatable({}, NavigationBar)
    self.Main = main
    self.Bar = nil
    self.Buttons = {}
    self.ActiveButton = nil
    self.HighlightFrame = nil
    return self
end

function NavigationBar:Create(buttons)
    -- Main bar frame
    self.Bar = Utility:Create("Frame", {
        Size = UDim2.new(0, 60, 0, 450),
        Position = UDim2.new(0, 20, 0.5, -225),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        BorderSizePixel = 0,
        ZIndex = 10,
        Visible = false
    })
    self.Bar.Parent = self.Main
    
    Utility:CreateCorner(self.Bar, 0.15)
    Utility:CreateStroke(self.Bar, SkyLineConfig.Colors.Border, 2)
    
    -- Highlight frame (moves between buttons)
    self.HighlightFrame = Utility:Create("Frame", {
        Size = UDim2.new(1, -10, 0, 50),
        Position = UDim2.new(0, 5, 0, 10),
        BackgroundColor3 = SkyLineConfig.Colors.Secondary,
        BorderSizePixel = 0,
        Transparency = 0.8
    })
    self.HighlightFrame.Parent = self.Bar
    Utility:CreateCorner(self.HighlightFrame, 0.2)
    
    -- Create buttons
    local yPos = 10
    for i, buttonData in ipairs(buttons) do
        local button = Utility:Create("TextButton", {
            Size = UDim2.new(1, -10, 0, 50),
            Position = UDim2.new(0, 5, 0, yPos),
            BackgroundTransparency = 1,
            Text = "",
            BorderSizePixel = 0,
            ZIndex = 11
        })
        button.Parent = self.Bar
        
        -- Icon
        local icon = Utility:Create("ImageLabel", {
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0.5, -15, 0.5, -15),
            BackgroundTransparency = 1,
            Image = buttonData.ImageId,
            ImageColor3 = SkyLineConfig.Colors.White,
            ZIndex = 12
        })
        icon.Parent = button
        
        -- Store button data
        table.insert(self.Buttons, {
            Button = button,
            Icon = icon,
            Data = buttonData
        })
        
        -- Button click
        button.MouseButton1Click:Connect(function()
            self:SetActiveButton(i)
            if buttonData.Callback then
                Utility:SafeCall(buttonData.Callback)
            end
        end)
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            if self.ActiveButton ~= i then
                -- Highlight moves to hovered button
                self:MoveHighlight(i, 0.2)
            end
        end)
        
        button.MouseLeave:Connect(function()
            if self.ActiveButton then
                self:MoveHighlight(self.ActiveButton, 0.2)
            end
        end)
        
        yPos = yPos + 60
    end
    
    -- Set initial active button (first)
    if #self.Buttons > 0 then
        self:SetActiveButton(1)
    end
end

function NavigationBar:SetActiveButton(index)
    if index < 1 or index > #self.Buttons then return end
    
    self.ActiveButton = index
    
    -- Update button colors
    for i, btnData in ipairs(self.Buttons) do
        if i == index then
            btnData.Icon.ImageColor3 = SkyLineConfig.Colors.Accent
        else
            btnData.Icon.ImageColor3 = SkyLineConfig.Colors.White
        end
    end
    
    -- Move highlight
    self:MoveHighlight(index, 0.3)
end

function NavigationBar:MoveHighlight(index, duration)
    if not self.HighlightFrame then return end
    
    local button = self.Buttons[index]
    if button then
        Utility:Tween(self.HighlightFrame, {
            Position = UDim2.new(0, 5, 0, button.Button.Position.Y.Offset + 5)
        }, duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
end

function NavigationBar:Show()
    if not self.Bar then return end
    
    self.Bar.Visible = true
    self.Bar.Position = UDim2.new(0, -80, 0.5, -225)
    self.Bar.Transparency = 0.8
    self.Bar.Scale = Vector2.new(0.95, 0.95)
    
    Utility:Tween(self.Bar, {
        Position = UDim2.new(0, 20, 0.5, -225),
        Transparency = 0,
        Scale = Vector2.new(1, 1)
    }, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function NavigationBar:Hide()
    if not self.Bar then return end
    
    Utility:Tween(self.Bar, {
        Position = UDim2.new(0, -80, 0.5, -225),
        Transparency = 0.8,
        Scale = Vector2.new(0.95, 0.95)
    }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    
    task.delay(0.3, function()
        self.Bar.Visible = false
    end)
end

-- ============================================
-- TAB MANAGER
-- ============================================
local TabManager = {}
TabManager.__index = TabManager

function TabManager.new(main)
    local self = setmetatable({}, TabManager)
    self.Main = main
    self.Tabs = {}
    self.ActiveTab = nil
    self.TabContainer = nil
    return self
end

function TabManager:CreateTab(id, name, contentFrame)
    local tab = {
        Id = id,
        Name = name,
        ContentFrame = contentFrame,
        Visible = false
    }
    
    self.Tabs[id] = tab
    return tab
end

function TabManager:SwitchTab(id, direction)
    if not self.Tabs[id] then return end
    
    local oldTab = self.ActiveTab
    local newTab = self.Tabs[id]
    
    if oldTab == id then return end
    
    if oldTab and self.Tabs[oldTab] then
        -- Hide old tab
        local oldFrame = self.Tabs[oldTab].ContentFrame
        if direction == "down" then
            Utility:Tween(oldFrame, {
                Position = UDim2.new(0, 0, 0, 20),
                Transparency = 1,
                Scale = Vector2.new(0.95, 0.95)
            }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        else
            Utility:Tween(oldFrame, {
                Position = UDim2.new(0, 0, 0, -20),
                Transparency = 1,
                Scale = Vector2.new(0.95, 0.95)
            }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        end
        
        task.delay(0.3, function()
            oldFrame.Visible = false
        end)
    end
    
    -- Show new tab
    local newFrame = newTab.ContentFrame
    newFrame.Visible = true
    
    if direction == "down" then
        newFrame.Position = UDim2.new(0, 0, 0, -20)
        Utility:Tween(newFrame, {
            Position = UDim2.new(0, 0, 0, 0),
            Transparency = 0,
            Scale = Vector2.new(1, 1)
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    else
        newFrame.Position = UDim2.new(0, 0, 0, 20)
        Utility:Tween(newFrame, {
            Position = UDim2.new(0, 0, 0, 0),
            Transparency = 0,
            Scale = Vector2.new(1, 1)
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
    
    self.ActiveTab = id
end

-- ============================================
-- UI COMPONENTS
-- ============================================

-- Toggle Component
local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent, properties)
    local self = setmetatable({}, Toggle)
    self.Parent = parent
    self.Properties = properties or {}
    self.Value = self.Properties.Default or false
    self.Title = self.Properties.Title or "Toggle"
    self.Callback = self.Properties.Callback or function() end
    
    -- Create main frame
    self.Frame = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = SkyLineConfig.Colors.Secondary,
        BorderSizePixel = 0,
        ZIndex = 5
    })
    self.Frame.Parent = self.Parent
    Utility:CreateCorner(self.Frame, 0.15)
    
    -- Title label
    self.TitleLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 14,
        TextColor3 = SkyLineConfig.Colors.White,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    self.TitleLabel.Parent = self.Frame
    
    -- Switch background
    self.SwitchBg = Utility:Create("Frame", {
        Size = UDim2.new(0, 50, 0, 25),
        Position = UDim2.new(1, -70, 0.5, -12.5),
        BackgroundColor3 = SkyLineConfig.Colors.Secondary,
        BorderSizePixel = 0,
        ZIndex = 6
    })
    self.SwitchBg.Parent = self.Frame
    Utility:CreateCorner(self.SwitchBg, 1)
    Utility:CreateStroke(self.SwitchBg, SkyLineConfig.Colors.Border, 1)
    
    -- Knob
    self.Knob = Utility:Create("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 3, 0.5, -10),
        BackgroundColor3 = SkyLineConfig.Colors.Border,
        BorderSizePixel = 0,
        ZIndex = 7
    })
    self.Knob.Parent = self.SwitchBg
    Utility:CreateCorner(self.Knob, 1)
    
    -- Click detection
    self.SwitchBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Toggle()
        end
    end)
    
    -- Frame click also toggles
    self.Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Toggle()
        end
    end)
    
    -- Initialize state
    self:UpdateVisual()
    
    return self
end

function Toggle:Toggle()
    self.Value = not self.Value
    self:UpdateVisual()
    Utility:SafeCall(self.Callback, self.Value)
end

function Toggle:SetValue(value)
    self.Value = value
    self:UpdateVisual()
end

function Toggle:GetValue()
    return self.Value
end

function Toggle:UpdateVisual()
    if self.Value then
        Utility:Tween(self.SwitchBg, {
            BackgroundColor3 = SkyLineConfig.Colors.Accent
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        Utility:Tween(self.Knob, {
            Position = UDim2.new(1, -23, 0.5, -10),
            BackgroundColor3 = SkyLineConfig.Colors.White
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    else
        Utility:Tween(self.SwitchBg, {
            BackgroundColor3 = SkyLineConfig.Colors.Secondary
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        Utility:Tween(self.Knob, {
            Position = UDim2.new(0, 3, 0.5, -10),
            BackgroundColor3 = SkyLineConfig.Colors.Border
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
end

-- Slider Component
local Slider = {}
Slider.__index = Slider

function Slider.new(parent, properties)
    local self = setmetatable({}, Slider)
    self.Parent = parent
    self.Properties = properties or {}
    self.Title = self.Properties.Title or "Slider"
    self.Min = self.Properties.Min or 0
    self.Max = self.Properties.Max or 100
    self.Value = self.Properties.Default or self.Min
    self.Callback = self.Properties.Callback or function() end
    self.Decimal = self.Properties.Decimal or 0
    
    -- Create main frame
    self.Frame = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = SkyLineConfig.Colors.Secondary,
        BorderSizePixel = 0,
        ZIndex = 5
    })
    self.Frame.Parent = self.Parent
    Utility:CreateCorner(self.Frame, 0.15)
    
    -- Title
    self.TitleLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 0, 25),
        Position = UDim2.new(0, 15, 0, 8),
        BackgroundTransparency = 1,
        Text = self.Title,
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 14,
        TextColor3 = SkyLineConfig.Colors.White,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    self.TitleLabel.Parent = self.Frame
    
    -- Value display
    self.ValueLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(0.2, 0, 0, 25),
        Position = UDim2.new(1, -80, 0, 8),
        BackgroundTransparency = 1,
        Text = tostring(self.Value),
        Font = SkyLineConfig.Fonts.Bold,
        TextSize = 14,
        TextColor3 = SkyLineConfig.Colors.Accent,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    self.ValueLabel.Parent = self.Frame
    
    -- Slider background
    self.SliderBg = Utility:Create("Frame", {
        Size = UDim2.new(1, -30, 0, 8),
        Position = UDim2.new(0, 15, 0, 40),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        BorderSizePixel = 0,
        ZIndex = 6
    })
    self.SliderBg.Parent = self.Frame
    Utility:CreateCorner(self.SliderBg, 1)
    
    -- Fill
    self.SliderFill = Utility:Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = SkyLineConfig.Colors.Accent,
        BorderSizePixel = 0,
        ZIndex = 7
    })
    self.SliderFill.Parent = self.SliderBg
    Utility:CreateCorner(self.SliderFill, 1)
    
    -- Gradient on fill
    local fillGradient = Utility:Create("UIGradient", {
        Color = ColorSequence.new(
            SkyLineConfig.Colors.AccentDark,
            SkyLineConfig.Colors.Accent
        ),
        Rotation = 90
    })
    fillGradient.Parent = self.SliderFill
    
    -- Knob
    self.Knob = Utility:Create("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, -10, 0.5, -10),
        BackgroundColor3 = SkyLineConfig.Colors.White,
        BorderSizePixel = 0,
        ZIndex = 8
    })
    self.Knob.Parent = self.SliderBg
    Utility:CreateCorner(self.Knob, 1)
    Utility:CreateStroke(self.Knob, SkyLineConfig.Colors.Border, 2)
    
    -- Dragging
    local dragging = false
    
    self.SliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            self:UpdateFromMouse()
        end
    end)
    
    self.SliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    game:GetService("RunService").RenderStepped:Connect(function()
        if dragging then
            self:UpdateFromMouse()
        end
    end)
    
    -- Update initial visual
    self:UpdateVisual()
    
    return self
end

function Slider:UpdateFromMouse()
    local mouse = Utility:GetMouse()
    local relativeX = mouse.X - self.SliderBg.AbsolutePosition.X
    local width = self.SliderBg.AbsoluteSize.X
    
    local percentage = math.clamp(relativeX / width, 0, 1)
    local newValue = self.Min + (self.Max - self.Min) * percentage
    
    if self.Decimal > 0 then
        newValue = math.floor(newValue * (10^self.Decimal)) / (10^self.Decimal)
    else
        newValue = math.floor(newValue + 0.5)
    end
    
    self.Value = newValue
    self.ValueLabel.Text = tostring(self.Value)
    
    self:UpdateVisual()
    Utility:SafeCall(self.Callback, self.Value)
end

function Slider:UpdateVisual()
    if not self.SliderFill then return end
    
    local percentage = (self.Value - self.Min) / (self.Max - self.Min)
    local width = self.SliderBg.AbsoluteSize.X * percentage
    
    Utility:Tween(self.SliderFill, {
        Size = UDim2.new(0, width, 1, 0)
    }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    Utility:Tween(self.Knob, {
        Position = UDim2.new(0, width - 10, 0.5, -10)
    }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

-- Dropdown Component
local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(parent, properties)
    local self = setmetatable({}, Dropdown)
    self.Parent = parent
    self.Properties = properties or {}
    self.Title = self.Properties.Title or "Dropdown"
    self.Options = self.Properties.Options or {}
    self.Value = self.Properties.Default or self.Options[1] or ""
    self.Callback = self.Properties.Callback or function() end
    self.Open = false
    self.DropdownFrame = nil
    
    -- Create main frame
    self.Frame = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 55),
        BackgroundColor3 = SkyLineConfig.Colors.Secondary,
        BorderSizePixel = 0,
        ZIndex = 5
    })
    self.Frame.Parent = self.Parent
    Utility:CreateCorner(self.Frame, 0.15)
    
    -- Title
    self.TitleLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 14,
        TextColor3 = SkyLineConfig.Colors.White,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    self.TitleLabel.Parent = self.Frame
    
    -- Dropdown button
    self.DropdownButton = Utility:Create("TextButton", {
        Size = UDim2.new(0, 150, 0, 35),
        Position = UDim2.new(1, -170, 0.5, -17.5),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        Text = "",
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 12,
        TextColor3 = SkyLineConfig.Colors.White,
        BorderSizePixel = 0,
        ZIndex = 6
    })
    self.DropdownButton.Parent = self.Frame
    Utility:CreateCorner(self.DropdownButton, 0.1)
    Utility:CreateStroke(self.DropdownButton, SkyLineConfig.Colors.Border, 1)
    
    -- Current value text
    self.ValueLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Value,
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 12,
        TextColor3 = SkyLineConfig.Colors.White,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 7
    })
    self.ValueLabel.Parent = self.DropdownButton
    
    -- Arrow
    self.Arrow = Utility:Create("TextLabel", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -25, 0.5, -10),
        BackgroundTransparency = 1,
        Text = "▼",
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 10,
        TextColor3 = SkyLineConfig.Colors.Border,
        ZIndex = 7
    })
    self.Arrow.Parent = self.DropdownButton
    
    -- Click handler
    self.DropdownButton.MouseButton1Click:Connect(function()
        self:ToggleDropdown()
    end)
    
    return self
end

function Dropdown:ToggleDropdown()
    if self.Open then
        self:Close()
    else
        self:Open()
    end
end

function Dropdown:Open()
    if self.Open then return end
    self.Open = true
    
    -- Create dropdown list frame
    self.DropdownFrame = Utility:Create("Frame", {
        Size = UDim2.new(0, 150, 0, 0),
        Position = UDim2.new(1, -170, 0, 55),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        BorderSizePixel = 0,
        ZIndex = 100,
        Visible = true,
        ClipsDescendants = true
    })
    self.DropdownFrame.Parent = self.Frame
    Utility:CreateCorner(self.DropdownFrame, 0.1)
    Utility:CreateStroke(self.DropdownFrame, SkyLineConfig.Colors.Accent, 1)
    
    -- Scrolling frame
    local scrollFrame = Utility:Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = SkyLineConfig.Colors.Border,
        ZIndex = 101
    })
    scrollFrame.Parent = self.DropdownFrame
    
    -- Option buttons
    local yPos = 0
    for _, option in ipairs(self.Options) do
        local optionButton = Utility:Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 35),
            Position = UDim2.new(0, 0, 0, yPos),
            BackgroundTransparency = 1,
            Text = option,
            Font = SkyLineConfig.Fonts.Main,
            TextSize = 12,
            TextColor3 = SkyLineConfig.Colors.White,
            BorderSizePixel = 0,
            ZIndex = 102
        })
        optionButton.Parent = scrollFrame
        
        optionButton.MouseEnter:Connect(function()
            Utility:Tween(optionButton, {
                BackgroundColor3 = SkyLineConfig.Colors.Secondary
            }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)
        
        optionButton.MouseLeave:Connect(function()
            Utility:Tween(optionButton, {
                BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)
        
        optionButton.MouseButton1Click:Connect(function()
            self:SelectOption(option)
        end)
        
        yPos = yPos + 35
    end
    
    -- Set scroll frame size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
    
    -- Animate open
    Utility:Tween(self.DropdownFrame, {
        Size = UDim2.new(0, 150, 0, math.min(yPos, 200))
    }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    -- Animate arrow
    Utility:Tween(self.Arrow, {
        Rotation = 180
    }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Dropdown:Close()
    if not self.Open then return end
    self.Open = false
    
    if self.DropdownFrame then
        Utility:Tween(self.DropdownFrame, {
            Size = UDim2.new(0, 150, 0, 0)
        }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        
        task.delay(0.2, function()
            if self.DropdownFrame then
                self.DropdownFrame:Destroy()
                self.DropdownFrame = nil
            end
        end)
    end
    
    -- Animate arrow
    Utility:Tween(self.Arrow, {
        Rotation = 0
    }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Dropdown:SelectOption(option)
    self.Value = option
    self.ValueLabel.Text = option
    self:Close()
    Utility:SafeCall(self.Callback, option)
end

-- Block (Collapsible Section) Component
local Block = {}
Block.__index = Block

function Block.new(parent, properties)
    local self = setmetatable({}, Block)
    self.Parent = parent
    self.Properties = properties or {}
    self.Title = self.Properties.Title or "Block"
    self.Open = self.Properties.DefaultOpen or false
    self.ContentHeight = self.Properties.ContentHeight or 200
    self.Content = nil
    
    -- Create header frame
    self.HeaderFrame = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = SkyLineConfig.Colors.Secondary,
        BorderSizePixel = 0,
        ZIndex = 5
    })
    self.HeaderFrame.Parent = self.Parent
    Utility:CreateCorner(self.HeaderFrame, 0.15)
    
    -- Title
    self.TitleLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 14,
        TextColor3 = SkyLineConfig.Colors.White,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    self.TitleLabel.Parent = self.HeaderFrame
    
    -- Arrow
    self.Arrow = Utility:Create("TextLabel", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -40, 0.5, -10),
        BackgroundTransparency = 1,
        Text = "▼",
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 12,
        TextColor3 = SkyLineConfig.Colors.Border,
        ZIndex = 6
    })
    self.Arrow.Parent = self.HeaderFrame
    
    -- Click handler
    self.HeaderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Toggle()
        end
    end)
    
    -- Content container
    self.ContentContainer = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundColor3 = SkyLineConfig.Colors.Secondary,
        BorderSizePixel = 0,
        ZIndex = 4,
        Visible = false,
        ClipsDescendants = true
    })
    self.ContentContainer.Parent = self.Parent
    Utility:CreateCorner(self.ContentContainer, 0.15)
    Utility:CreateStroke(self.ContentContainer, SkyLineConfig.Colors.Border, 1)
    
    return self
end

function Block:Toggle()
    self.Open = not self.Open
    
    if self.Open then
        self.ContentContainer.Visible = true
        
        Utility:Tween(self.Arrow, {
            Rotation = 180
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        Utility:Tween(self.ContentContainer, {
            Size = UDim2.new(1, 0, 0, self.ContentHeight)
        }, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    else
        Utility:Tween(self.Arrow, {
            Rotation = 0
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        Utility:Tween(self.ContentContainer, {
            Size = UDim2.new(1, 0, 0, 0)
        }, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        
        task.delay(0.4, function()
            self.ContentContainer.Visible = false
        end)
    end
end

function Block:AddContent(element)
    if not self.ContentContainer then return end
    
    element.Parent = self.ContentContainer
    -- Position element below previous content
    local lastChild = self.ContentContainer:GetChildren()
    local yPos = 5
    for _, child in ipairs(lastChild) do
        if child:IsA("Frame") and child ~= self.ContentContainer then
            yPos = yPos + child.Size.Y.Offset + 5
        end
    end
    
    element.Position = UDim2.new(0, 5, 0, yPos)
end

-- Button Component
local Button = {}
Button.__index = Button

function Button.new(parent, properties)
    local self = setmetatable({}, Button)
    self.Parent = parent
    self.Properties = properties or {}
    self.Title = self.Properties.Title or "Button"
    self.Callback = self.Properties.Callback or function() end
    
    -- Create frame
    self.Frame = Utility:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = SkyLineConfig.Colors.Secondary,
        Text = self.Title,
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 14,
        TextColor3 = SkyLineConfig.Colors.White,
        BorderSizePixel = 0,
        ZIndex = 5
    })
    self.Frame.Parent = self.Parent
    Utility:CreateCorner(self.Frame, 0.15)
    Utility:CreateStroke(self.Frame, SkyLineConfig.Colors.Border, 1)
    
    -- Hover effect
    self.Frame.MouseEnter:Connect(function()
        Utility:Tween(self.Frame, {
            BackgroundColor3 = SkyLineConfig.Colors.Background
        }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
    
    self.Frame.MouseLeave:Connect(function()
        Utility:Tween(self.Frame, {
            BackgroundColor3 = SkyLineConfig.Colors.Secondary
        }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
    
    -- Click
    self.Frame.MouseButton1Click:Connect(function()
        Utility:SafeCall(self.Callback)
    end)
    
    return self
end

-- Label Component
local Label = {}
Label.__index = Label

function Label.new(parent, properties)
    local self = setmetatable({}, Label)
    self.Parent = parent
    self.Properties = properties or {}
    self.Text = self.Properties.Text or "Label"
    self.TextSize = self.Properties.TextSize or 14
    
    self.Frame = Utility:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, self.Properties.Height or 30),
        BackgroundTransparency = 1,
        Text = self.Text,
        Font = SkyLineConfig.Fonts.Main,
        TextSize = self.TextSize,
        TextColor3 = self.Properties.Color or SkyLineConfig.Colors.White,
        TextXAlignment = self.Properties.Alignment or Enum.TextXAlignment.Left,
        ZIndex = 5
    })
    self.Frame.Parent = self.Parent
    
    return self
end

-- ============================================
-- MAIN TAB CONTENT BUILDER
-- ============================================
local TabContentBuilder = {}
TabContentBuilder.__index = TabContentBuilder

function TabContentBuilder.new(main, tabFrame)
    local self = setmetatable({}, TabContentBuilder)
    self.Main = main
    self.TabFrame = tabFrame
    self.Elements = {}
    self.CurrentYPos = 10
    return self
end

function TabContentBuilder:AddToggle(properties)
    local toggle = Toggle.new(self.TabFrame, properties)
    toggle.Frame.Position = UDim2.new(0, 10, 0, self.CurrentYPos)
    self.CurrentYPos = self.CurrentYPos + 55
    table.insert(self.Elements, toggle)
    return toggle
end

function TabContentBuilder:AddSlider(properties)
    local slider = Slider.new(self.TabFrame, properties)
    slider.Frame.Position = UDim2.new(0, 10, 0, self.CurrentYPos)
    self.CurrentYPos = self.CurrentYPos + 65
    table.insert(self.Elements, slider)
    return slider
end

function TabContentBuilder:AddDropdown(properties)
    local dropdown = Dropdown.new(self.TabFrame, properties)
    dropdown.Frame.Position = UDim2.new(0, 10, 0, self.CurrentYPos)
    self.CurrentYPos = self.CurrentYPos + 60
    table.insert(self.Elements, dropdown)
    return dropdown
end

function TabContentBuilder:AddBlock(properties)
    local block = Block.new(self.TabFrame, properties)
    block.HeaderFrame.Position = UDim2.new(0, 10, 0, self.CurrentYPos)
    block.ContentContainer.Position = UDim2.new(0, 10, 0, self.CurrentYPos + 50)
    self.CurrentYPos = self.CurrentYPos + 55 + (block.Open and block.ContentHeight or 0)
    table.insert(self.Elements, block)
    return block
end

function TabContentBuilder:AddButton(properties)
    local button = Button.new(self.TabFrame, properties)
    button.Frame.Position = UDim2.new(0, 10, 0, self.CurrentYPos)
    self.CurrentYPos = self.CurrentYPos + 50
    table.insert(self.Elements, button)
    return button
end

function TabContentBuilder:AddLabel(properties)
    local label = Label.new(self.TabFrame, properties)
    label.Frame.Position = UDim2.new(0, 10, 0, self.CurrentYPos)
    self.CurrentYPos = self.CurrentYPos + (properties.Height or 30)
    table.insert(self.Elements, label)
    return label
end

-- ============================================
-- MAIN SKYLINE HUB UI
-- ============================================
local SkyLineHub = {}
SkyLineHub.__index = SkyLineHub

function SkyLineHub.new()
    local self = setmetatable({}, SkyLineHub)
    self.Main = nil
    self.Tabs = {}
    self.NavButtons = {
        {Id = "home", ImageId = "112770735347738"},
        {Id = "main", ImageId = "92091304135140"},
        {Id = "player", ImageId = "6031094667"},
        {Id = "loadscript", ImageId = "83975792443912"},
        {Id = "settings", ImageId = "125743894366007"},
        {Id = "exit", ImageId = "96518596121178"}
    }
    self.CurrentTab = "home"
    self.Settings = {
        DisableEffects = false,
        Theme = "Default",
        AutoSave = true
    }
    self.Open = true
    return self
end

function SkyLineHub:Create()
    -- Create main container
    self.Main = Utility:Create("ScreenGui", {
        Name = "SkyLineHub",
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999
    })
    self.Main.Parent = game:GetService("CoreGui")
    
    -- Create UI elements
    self:CreateAmbientGlow()
    self:CreateTabs()
    self:CreateNavigationBar()
    self:CreateLoadingScreen()
    
    -- Start loading sequence
    self:StartLoadingSequence()
end

function SkyLineHub:CreateAmbientGlow()
    self.AmbientGlow = AmbientGlow.new(self.Main)
    self.AmbientGlow:Create()
end

function SkyLineHub:CreateTabs()
    -- Create tab content frames
    local tabContainer = Utility:Create("Frame", {
        Size = UDim2.new(0, 700, 0, 500),
        Position = UDim2.new(0, 100, 0.5, -250),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Visible = true
    })
    tabContainer.Parent = self.Main
    
    -- Home tab
    local homeTab = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        BorderSizePixel = 0,
        ZIndex = 6,
        Visible = false
    })
    homeTab.Parent = tabContainer
    Utility:CreateCorner(homeTab, 0.15)
    Utility:CreateStroke(homeTab, SkyLineConfig.Colors.Border, 2)
    
    -- Main tab
    local mainTab = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        BorderSizePixel = 0,
        ZIndex = 6,
        Visible = false
    })
    mainTab.Parent = tabContainer
    Utility:CreateCorner(mainTab, 0.15)
    Utility:CreateStroke(mainTab, SkyLineConfig.Colors.Border, 2)
    
    -- Player tab
    local playerTab = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        BorderSizePixel = 0,
        ZIndex = 6,
        Visible = false
    })
    playerTab.Parent = tabContainer
    Utility:CreateCorner(playerTab, 0.15)
    Utility:CreateStroke(playerTab, SkyLineConfig.Colors.Border, 2)
    
    -- LoadScript tab
    local loadScriptTab = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        BorderSizePixel = 0,
        ZIndex = 6,
        Visible = false
    })
    loadScriptTab.Parent = tabContainer
    Utility:CreateCorner(loadScriptTab, 0.15)
    Utility:CreateStroke(loadScriptTab, SkyLineConfig.Colors.Border, 2)
    
    -- Settings tab
    local settingsTab = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        BorderSizePixel = 0,
        ZIndex = 6,
        Visible = false
    })
    settingsTab.Parent = tabContainer
    Utility:CreateCorner(settingsTab, 0.15)
    Utility:CreateStroke(settingsTab, SkyLineConfig.Colors.Border, 2)
    
    -- Store tabs
    self.Tabs["home"] = homeTab
    self.Tabs["main"] = mainTab
    self.Tabs["player"] = playerTab
    self.Tabs["loadscript"] = loadScriptTab
    self.Tabs["settings"] = settingsTab
end

function SkyLineHub:CreateNavigationBar()
    self.NavigationBar = NavigationBar.new(self.Main)
    self.NavigationBar:Create(self.NavButtons)
    
    -- Connect navigation callbacks
    for i, btnData in ipairs(self.NavButtons) do
        local oldCallback = btnData.Callback
        btnData.Callback = function()
            self:SwitchTab(btnData.Id, i)
            if oldCallback then oldCallback() end
        end
    end
end

function SkyLineHub:CreateLoadingScreen()
    self.LoadingScreen = LoadingScreen.new(self.Main)
    self.LoadingScreen:Create()
end

function SkyLineHub:StartLoadingSequence()
    -- Simulate loading process
    task.delay(2, function()
        -- Fade out loading screen
        Utility:Tween(self.LoadingScreen.LoadingFrame, {
            Transparency = 1,
            Scale = Vector2.new(0.85, 0.85)
        }, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        
        task.delay(0.5, function()
            if self.LoadingScreen.LoadingFrame then
                self.LoadingScreen.LoadingFrame:Destroy()
            end
            
            -- Show navigation bar
            self.NavigationBar:Show()
            
            -- Show initial tab
            self:SwitchTab("home", 1)
        end)
    end)
end

function SkyLineHub:SwitchTab(tabId, index)
    if not self.Tabs[tabId] then return end
    
    -- Determine direction
    local direction = "down"
    if index and self.LastIndex and index < self.LastIndex then
        direction = "up"
    end
    
    -- Hide current tab
    if self.CurrentTab and self.Tabs[self.CurrentTab] then
        local currentFrame = self.Tabs[self.CurrentTab]
        
        if direction == "down" then
            Utility:Tween(currentFrame, {
                Position = UDim2.new(0, 0, 0, 20),
                Transparency = 1,
                Scale = Vector2.new(0.95, 0.95)
            }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        else
            Utility:Tween(currentFrame, {
                Position = UDim2.new(0, 0, 0, -20),
                Transparency = 1,
                Scale = Vector2.new(0.95, 0.95)
            }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        end
        
        task.delay(0.3, function()
            currentFrame.Visible = false
            currentFrame.Position = UDim2.new(0, 0, 0, 0)
        end)
    end
    
    -- Show new tab
    local newFrame = self.Tabs[tabId]
    newFrame.Visible = true
    
    if direction == "down" then
        newFrame.Position = UDim2.new(0, 0, 0, -20)
        newFrame.Transparency = 1
        newFrame.Scale = Vector2.new(0.95, 0.95)
        
        Utility:Tween(newFrame, {
            Position = UDim2.new(0, 0, 0, 0),
            Transparency = 0,
            Scale = Vector2.new(1, 1)
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    else
        newFrame.Position = UDim2.new(0, 0, 0, 20)
        newFrame.Transparency = 1
        newFrame.Scale = Vector2.new(0.95, 0.95)
        
        Utility:Tween(newFrame, {
            Position = UDim2.new(0, 0, 0, 0),
            Transparency = 0,
            Scale = Vector2.new(1, 1)
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
    
    self.CurrentTab = tabId
    self.LastIndex = index
end

function SkyLineHub:Hide()
    self.Open = false
    self.NavigationBar:Hide()
    
    -- Hide current tab
    if self.Tabs[self.CurrentTab] then
        Utility:Tween(self.Tabs[self.CurrentTab], {
            Transparency = 1,
            Scale = Vector2.new(0.95, 0.95)
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        
        task.delay(0.3, function()
            self.Tabs[self.CurrentTab].Visible = false
        end)
    end
    
    -- Show small arrow to reopen
    if not self.ArrowButton then
        self.ArrowButton = Utility:Create("TextButton", {
            Size = UDim2.new(0, 30, 0, 60),
            Position = UDim2.new(0, 10, 0.5, -30),
            BackgroundColor3 = SkyLineConfig.Colors.Background,
            Text = "»",
            Font = SkyLineConfig.Fonts.Bold,
            TextSize = 20,
            TextColor3 = SkyLineConfig.Colors.Accent,
            BorderSizePixel = 0,
            ZIndex = 50
        })
        self.ArrowButton.Parent = self.Main
        Utility:CreateCorner(self.ArrowButton, 0.15)
        Utility:CreateStroke(self.ArrowButton, SkyLineConfig.Colors.Border, 1)
        
        self.ArrowButton.MouseButton1Click:Connect(function()
            self:Show()
        end)
    end
    
    self.ArrowButton.Visible = true
end

function SkyLineHub:Show()
    self.Open = true
    
    -- Hide arrow
    if self.ArrowButton then
        self.ArrowButton.Visible = false
    end
    
    -- Show navigation bar
    self.NavigationBar:Show()
    
    -- Show current tab
    if self.Tabs[self.CurrentTab] then
        self.Tabs[self.CurrentTab].Visible = true
        Utility:Tween(self.Tabs[self.CurrentTab], {
            Transparency = 0,
            Scale = Vector2.new(1, 1)
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
end

-- ============================================
-- HOME TAB CONTENT
-- ============================================
function SkyLineHub:CreateHomeTab()
    local homeTab = self.Tabs["home"]
    if not homeTab then return end
    
    -- Profile section
    local profileFrame = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 120),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = SkyLineConfig.Colors.Secondary,
        BorderSizePixel = 0,
        ZIndex = 7
    })
    profileFrame.Parent = homeTab
    Utility:CreateCorner(profileFrame, 0.15)
    
    -- Avatar circle
    local avatarFrame = Utility:Create("Frame", {
        Size = UDim2.new(0, 80, 0, 80),
        Position = UDim2.new(0, 20, 0.5, -40),
        BackgroundColor3 = SkyLineConfig.Colors.Border,
        BorderSizePixel = 0,
        ZIndex = 8
    })
    avatarFrame.Parent = profileFrame
    Utility:CreateCorner(avatarFrame, 1)
    
    local avatarImage = Utility:Create("ImageLabel", {
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6031094667",
        ImageColor3 = SkyLineConfig.Colors.Accent,
        ZIndex = 9
    })
    avatarImage.Parent = avatarFrame
    Utility:CreateCorner(avatarImage, 1)
    
    -- Player info
    local infoFrame = Utility:Create("Frame", {
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 110, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 8
    })
    infoFrame.Parent = profileFrame
    
    -- Player ID
    local playerIdButton = Utility:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 35),
        Position = UDim2.new(0, 0, 0, 10),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        Text = "Player ID: 123456789",
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 13,
        TextColor3 = SkyLineConfig.Colors.White,
        BorderSizePixel = 0,
        ZIndex = 9
    })
    playerIdButton.Parent = infoFrame
    Utility:CreateCorner(playerIdButton, 0.1)
    
    playerIdButton.MouseButton1Click:Connect(function()
        local playerId = game.Players.LocalPlayer.UserId
        if Utility:CopyToClipboard(playerId) then
            NotificationManager:Show("Success", "Player ID copied to clipboard!", 2)
        end
    end)
    
    -- Ping display
    local pingLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundTransparency = 1,
        Text = "Ping: 0ms",
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 13,
        TextColor3 = SkyLineConfig.Colors.White,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9
    })
    pingLabel.Parent = infoFrame
    
    -- FPS display
    local fpsLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 0, 30),
        Position = UDim2.new(0.5, 0, 0, 50),
        BackgroundTransparency = 1,
        Text = "FPS: 60",
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 13,
        TextColor3 = SkyLineConfig.Colors.White,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 9
    })
    fpsLabel.Parent = infoFrame
    
    -- Update loop
    task.spawn(function()
        while self.Main.Parent do
            task.wait(1)
            
            local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            pingLabel.Text = "Ping: " .. math.floor(ping) .. "ms"
            
            local fps = 1 / game:GetService("RunService").RenderStepped:Wait()
            fpsLabel.Text = "FPS: " .. math.floor(fps)
        end
    end)
end

-- ============================================
-- MAIN TAB CONTENT
-- ============================================
function SkyLineHub:CreateMainTab()
    local mainTab = self.Tabs["main"]
    if not mainTab then return end
    
    local builder = TabContentBuilder.new(self.Main, mainTab)
    
    -- Example content
    builder:AddToggle({
        Title = "Example Toggle",
        Default = false,
        Callback = function(value)
            print("Toggle changed:", value)
        end
    })
    
    builder:AddSlider({
        Title = "Example Slider",
        Min = 0,
        Max = 100,
        Default = 50,
        Callback = function(value)
            print("Slider changed:", value)
        end
    })
    
    builder:AddDropdown({
        Title = "Example Dropdown",
        Options = {"Option 1", "Option 2", "Option 3"},
        Default = "Option 1",
        Callback = function(option)
            print("Dropdown selected:", option)
        end
    })
    
    -- Block example
    local block = builder:AddBlock({
        Title = "Example Block",
        ContentHeight = 200
    })
    
    -- Add content to block
    local blockToggle = Toggle.new(block.ContentContainer, {
        Title = "Inner Toggle",
        Default = false
    })
    blockToggle.Frame.Position = UDim2.new(0, 5, 0, 5)
    blockToggle.Frame.Size = UDim2.new(1, -10, 0, 50)
    
    local blockSlider = Slider.new(block.ContentContainer, {
        Title = "Inner Slider",
        Min = 0,
        Max = 10,
        Default = 5
    })
    blockSlider.Frame.Position = UDim2.new(0, 5, 0, 60)
    blockSlider.Frame.Size = UDim2.new(1, -10, 0, 60)
end

-- ============================================
-- PLAYER TAB CONTENT
-- ============================================
function SkyLineHub:CreatePlayerTab()
    local playerTab = self.Tabs["player"]
    if not playerTab then return end
    
    local builder = TabContentBuilder.new(self.Main, playerTab)
    
    -- Speed slider + toggle
    local speedToggle = builder:AddToggle({
        Title = "Enable Speed",
        Default = false,
        Callback = function(value)
            if value then
                local player = game.Players.LocalPlayer
                player.Character.Humanoid.WalkSpeed = 16
            else
                local player = game.Players.LocalPlayer
                player.Character.Humanoid.WalkSpeed = 16
            end
        end
    })
    
    local speedSlider = builder:AddSlider({
        Title = "Speed",
        Min = 16,
        Max = 100,
        Default = 16,
        Callback = function(value)
            if speedToggle:GetValue() then
                local player = game.Players.LocalPlayer
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.WalkSpeed = value
                end
            end
        end
    })
    
    -- Jump Power
    local jumpToggle = builder:AddToggle({
        Title = "Custom Jump",
        Default = false
    })
    
    local jumpSlider = builder:AddSlider({
        Title = "Jump Power",
        Min = 50,
        Max = 200,
        Default = 50,
        Callback = function(value)
            if jumpToggle:GetValue() then
                local player = game.Players.LocalPlayer
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.JumpPower = value
                end
            end
        end
    })
    
    -- Other toggles
    builder:AddToggle({
        Title = "Highlight ESP",
        Default = false,
        Callback = function(value)
            -- ESP implementation
        end
    })
    
    builder:AddToggle({
        Title = "FPS Boost",
        Default = false
    })
    
    builder:AddToggle({
        Title = "Noclip",
        Default = false
    })
    
    builder:AddToggle({
        Title = "Infinite Jump",
        Default = false
    })
    
    builder:AddToggle({
        Title = "Anti AFK",
        Default = false
    })
    
    -- Spin
    local spinToggle = builder:AddToggle({
        Title = "Spin",
        Default = false
    })
    
    builder:AddSlider({
        Title = "Spin Speed",
        Min = 1,
        Max = 30,
        Default = 10,
        Callback = function(value)
            -- Spin implementation
        end
    })
end

-- ============================================
-- LOADSCRIPT TAB CONTENT
-- ============================================
function SkyLineHub:CreateLoadScriptTab()
    local loadScriptTab = self.Tabs["loadscript"]
    if not loadScriptTab then return end
    
    local builder = TabContentBuilder.new(self.Main, loadScriptTab)
    
    -- Script buttons
    local scripts = {
        {Title = "Infinite Yield", Script = "loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()"},
        {Title = "ESP Script", Script = "print('ESP script loaded')"},
        {Title = "Admin Script", Script = "print('Admin script loaded')"},
        {Title: "Universal Script", Script = "print('Universal script loaded')"}
    }
    
    for _, scriptData in ipairs(scripts) do
        builder:AddButton({
            Title = "▶ " .. scriptData.Title,
            Callback = function()
                Utility:SafeCall(function()
                    loadstring(scriptData.Script)()
                    NotificationManager:Show("Success", scriptData.Title .. " loaded!", 2)
                end)
            end
        })
    end
end

-- ============================================
-- SETTINGS TAB CONTENT
-- ============================================
function SkyLineHub:CreateSettingsTab()
    local settingsTab = self.Tabs["settings"]
    if not settingsTab then return end
    
    local builder = TabContentBuilder.new(self.Main, settingsTab)
    
    -- Heavy effects toggle
    builder:AddToggle({
        Title = "Disable Heavy Effects",
        Default = false,
        Callback = function(value)
            self.Settings.DisableEffects = value
            self.AmbientGlow:SetEnabled(not value)
        end
    })
    
    -- Theme selector
    builder:AddDropdown({
        Title = "Theme",
        Options = {"Default", "Ocean", "Sunset", "Forest"},
        Default = "Default",
        Callback = function(option)
            self.Settings.Theme = option
            -- Theme implementation
        end
    })
    
    -- Save settings
    builder:AddButton({
        Title = "Save Settings",
        Callback = function()
            local presetName = self:PromptInput("Enter preset name:")
            if presetName then
                self:SavePreset(presetName)
                NotificationManager:Show("Success", "Settings saved as '" .. presetName .. "'", 2)
            end
        end
    })
    
    -- Load settings
    builder:AddDropdown({
        Title = "Load Settings",
        Options = self:GetPresets(),
        Callback = function(option)
            self:LoadPreset(option)
        end
    })
    
    -- Auto save
    builder:AddToggle({
        Title = "Auto Save Settings",
        Default = true,
        Callback = function(value)
            self.Settings.AutoSave = value
        end
    })
    
    -- Destroy GUI
    builder:AddButton({
        Title = "Destroy GUI",
        Callback = function()
            self:Destroy()
        end
    })
end

function SkyLineHub:PromptInput(title)
    -- Simple input implementation
    local inputFrame = Utility:Create("Frame", {
        Size = UDim2.new(0, 300, 0, 150),
        Position = UDim2.new(0.5, -150, 0.5, -75),
        BackgroundColor3 = SkyLineConfig.Colors.Background,
        BorderSizePixel = 0,
        ZIndex = 200,
        Visible = true
    })
    inputFrame.Parent = self.Main
    Utility:CreateCorner(inputFrame, 0.15)
    Utility:CreateStroke(inputFrame, SkyLineConfig.Colors.Accent, 2)
    
    local titleLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Text = title or "Input",
        Font = SkyLineConfig.Fonts.Bold,
        TextSize = 16,
        TextColor3 = SkyLineConfig.Colors.White
    })
    titleLabel.Parent = inputFrame
    
    local inputBox = Utility:Create("TextBox", {
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 50),
        BackgroundColor3 = SkyLineConfig.Colors.Secondary,
        Text = "",
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 14,
        TextColor3 = SkyLineConfig.Colors.White,
        PlaceholderText = "Enter value...",
        BorderSizePixel = 0,
        ClearTextOnFocus = false
    })
    inputBox.Parent = inputFrame
    Utility:CreateCorner(inputBox, 0.1)
    Utility:CreateStroke(inputBox, SkyLineConfig.Colors.Border, 1)
    
    local result = nil
    
    local confirmButton = Utility:Create("TextButton", {
        Size = UDim2.new(0, 100, 0, 35),
        Position = UDim2.new(0.5, -105, 0, 100),
        BackgroundColor3 = SkyLineConfig.Colors.Accent,
        Text = "OK",
        Font = SkyLineConfig.Fonts.Bold,
        TextSize = 14,
        TextColor3 = SkyLineConfig.Colors.White,
        BorderSizePixel = 0
    })
    confirmButton.Parent = inputFrame
    Utility:CreateCorner(confirmButton, 0.1)
    
    local cancelButton = Utility:Create("TextButton", {
        Size = UDim2.new(0, 100, 0, 35),
        Position = UDim2.new(0.5, 5, 0, 100),
        BackgroundColor3 = SkyLineConfig.Colors.Secondary,
        Text = "Cancel",
        Font = SkyLineConfig.Fonts.Main,
        TextSize = 14,
        TextColor3 = SkyLineConfig.Colors.White,
        BorderSizePixel = 0
    })
    cancelButton.Parent = inputFrame
    Utility:CreateCorner(cancelButton, 0.1)
    
    confirmButton.MouseButton1Click:Connect(function()
        result = inputBox.Text
        inputFrame:Destroy()
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        result = nil
        inputFrame:Destroy()
    end)
    
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            result = inputBox.Text
            inputFrame:Destroy()
        end
    end)
    
    -- Wait for result (max 10 seconds)
    local startTime = tick()
    while not result and tick() - startTime < 10 do
        task.wait(0.1)
    end
    
    return result
end

function SkyLineHub:SavePreset(name)
    -- Save settings to memory
    self.Presets = self.Presets or {}
    self.Presets[name] = {
        Settings = self.Settings,
        ToggleStates = {}
    }
    
    -- Save all toggle states
    for _, tab in pairs(self.Tabs) do
        for _, child in ipairs(tab:GetChildren()) do
            if child:IsA("Frame") and child:FindFirstChild("Toggle") then
                -- Save toggle state
            end
        end
    end
end

function SkyLineHub:LoadPreset(name)
    -- Load settings from memory
    if self.Presets and self.Presets[name] then
        self.Settings = self.Presets[name].Settings
        NotificationManager:Show("Success", "Preset '" .. name .. "' loaded!", 2)
    end
end

function SkyLineHub:GetPresets()
    if not self.Presets then return {} end
    local presets = {}
    for name in pairs(self.Presets) do
        table.insert(presets, name)
    end
    return presets
end

function SkyLineHub:Destroy()
    Utility:SafeCall(function()
        if self.Main then
            self.Main:Destroy()
        end
    end)
end

-- ============================================
-- INITIALIZATION & EXAMPLE USAGE
-- ============================================
function SkyLineHub:Init()
    -- Create all tab content
    self:CreateHomeTab()
    self:CreateMainTab()
    self:CreatePlayerTab()
    self:CreateLoadScriptTab()
    self:CreateSettingsTab()
    
    -- Final setup
    self:Finalize()
end

function SkyLineHub:Finalize()
    -- Any final initialization
end

-- ============================================
-- EXAMPLE USAGE
-- ============================================
local function ExampleUsage()
    -- Create SkyLine Hub
    local ui = SkyLineHub.new()
    ui:Create()
    
    -- Wait for loading to complete
    task.delay(3, function()
        ui:Init()
        
        print("SkyLine Hub loaded successfully!")
    end)
    
    return ui
end

-- Uncomment to run example
-- local hub = ExampleUsage()

return SkyLineHub
