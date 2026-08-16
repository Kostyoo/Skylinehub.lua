--[[
    SkyLine Hub — единый файл библиотеки (single-file build)

    Использование:
        local SkyLineHubFactory = loadstring(<этот скрипт>)()
        local Library = SkyLineHubFactory.new()
        local UI = Library:CreateWindow()
        local Home = UI:CreateTab("Home")
        Home:AddButton({Text = "Click me", Callback = function() print("clicked") end})

    Либо как ModuleScript: вставь содержимое целиком, последняя строка
    'return Main' экспортирует библиотеку через require().

    ВАЖНО: используй LocalScript (или ModuleScript, требуемый из LocalScript) —
    библиотека обращается к Players.LocalPlayer.PlayerGui, которого нет на сервере.
]]

local SkyLineHub = {}

-- ============================================================
-- MODULE: Utils/Theme.lua
-- ============================================================
local Theme = (function()
	local Theme = {}

	Theme.Colors = {
		Background      = Color3.fromHex("223145"),
		Border          = Color3.fromHex("344153"),
		AccentLight     = Color3.fromHex("3A4C66"), -- светлее фона, для активных элементов
		PanelBackground = Color3.fromHex("223145"),
		PanelBorder     = Color3.fromHex("344153"),

		TextPrimary     = Color3.fromRGB(235, 240, 248),
		TextSecondary   = Color3.fromRGB(160, 172, 190),

		Indigo          = Color3.fromRGB(99, 102, 241),
		SkyBlue         = Color3.fromRGB(56, 189, 248),
		VioletBlue      = Color3.fromRGB(129, 140, 248),
	}

	-- Палитра свечения по краям экрана (используется AuroraGlow для случайного перехода оттенков)
	Theme.GlowPalette = {
		Theme.Colors.Indigo,
		Theme.Colors.SkyBlue,
		Theme.Colors.VioletBlue,
	}

	Theme.CornerRadius       = UDim.new(0, 12)
	Theme.CornerRadiusSmall  = UDim.new(0, 8)
	Theme.Padding            = UDim.new(0, 12)

	return Theme
end)()

-- ============================================================
-- MODULE: Utils/Animation.lua
-- ============================================================
local Animation = (function()
	local TweenService = game:GetService("TweenService")

	local Animation = {}

	-- Стандартные пресеты плавности, используемые всей библиотекой.
	-- Quad/Quart дают мягкое ускорение-замедление без резких рывков.
	Animation.Presets = {
		Smooth      = TweenInfo.new(0.28, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
		SmoothSlow  = TweenInfo.new(0.45, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
		Snappy      = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		Entrance    = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		Glow        = TweenInfo.new(3.2,  Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut),
		Wave        = TweenInfo.new(0.5,  Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut),
		Highlight   = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	}

	-- Запускает твин и возвращает объект Tween (не блокирует поток).
	function Animation.Play(instance, tweenInfo, properties)
		local tween = TweenService:Create(instance, tweenInfo, properties)
		tween:Play()
		return tween
	end

	-- Запускает твин и ждёт его завершения (для последовательных цепочек анимаций).
	function Animation.PlayYield(instance, tweenInfo, properties)
		local tween = TweenService:Create(instance, tweenInfo, properties)
		tween:Play()
		tween.Completed:Wait()
		return tween
	end

	-- Цепочка твинов, идущих строго последовательно (используется в интро-анимациях).
	function Animation.Sequence(steps)
		task.spawn(function()
			for _, step in ipairs(steps) do
				if step.delay then
					task.wait(step.delay)
				end
				Animation.PlayYield(step.instance, step.tweenInfo, step.properties)
			end
		end)
	end

	-- Параллельная группа твинов, стартующих одновременно и синхронно (масштаб+альфа+позиция).
	function Animation.Group(entries)
		local tweens = {}
		for _, entry in ipairs(entries) do
			table.insert(tweens, Animation.Play(entry.instance, entry.tweenInfo, entry.properties))
		end
		return tweens
	end

	-- Плавная линейная интерполяция значения через Heartbeat — используется для волны загрузки
	-- и для скользящей подсветки навигации, где нужен полный контроль над кадром.
	function Animation.Loop(callback)
		local connection
		connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
			local shouldContinue = callback(dt)
			if shouldContinue == false then
				connection:Disconnect()
			end
		end)
		return connection
	end

	return Animation
end)()

-- ============================================================
-- MODULE: Utils/Icons.lua
-- ============================================================
local Icons = (function()
	local Icons = {}

	local function newLine(parent, size, position, rotation, color)
		local line = Instance.new("Frame")
		line.Size = size
		line.Position = position
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Rotation = rotation or 0
		line.BackgroundColor3 = color
		line.BorderSizePixel = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = line
		line.Parent = parent
		return line
	end

	local function newRing(parent, diameter, thickness, color)
		local ring = Instance.new("Frame")
		ring.Size = UDim2.fromOffset(diameter, diameter)
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0.5)
		ring.BackgroundTransparency = 1
		ring.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = ring

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = thickness
		stroke.Color = color
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = ring

		return ring
	end

	local function container()
		local holder = Instance.new("Frame")
		holder.Size = UDim2.fromOffset(24, 24)
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.BackgroundTransparency = 1
		return holder
	end

	-- Home: домик из двух линий-скатов + прямоугольник-основание
	function Icons.Home(parent, color)
		local holder = container()
		holder.Parent = parent

		newLine(holder, UDim2.fromOffset(15, 2.5), UDim2.fromScale(0.28, 0.42), 45, color)
		newLine(holder, UDim2.fromOffset(15, 2.5), UDim2.fromScale(0.72, 0.42), -45, color)

		local base = Instance.new("Frame")
		base.Size = UDim2.fromOffset(14, 10)
		base.AnchorPoint = Vector2.new(0.5, 1)
		base.Position = UDim2.fromScale(0.5, 0.92)
		base.BackgroundTransparency = 1
		base.Parent = holder

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = color
		stroke.Parent = base

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 2)
		corner.Parent = base

		return holder
	end

	-- Settings: кольцо (шестерня упрощённо) + внутренняя точка
	function Icons.Settings(parent, color)
		local holder = container()
		holder.Parent = parent

		newRing(holder, 18, 2, color)

		local dot = Instance.new("Frame")
		dot.Size = UDim2.fromOffset(6, 6)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(0.5, 0.5)
		dot.BackgroundColor3 = color
		dot.BorderSizePixel = 0
		dot.Parent = holder
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = dot

		-- зубцы шестерни: 4 коротких штриха вокруг кольца
		for i = 0, 3 do
			local angle = i * 90
			newLine(holder, UDim2.fromOffset(4, 2), UDim2.fromScale(0.5, 0.5), angle, color).Position =
				UDim2.new(0.5, math.cos(math.rad(angle)) * 11, 0.5, math.sin(math.rad(angle)) * 11)
		end

		return holder
	end

	-- Inventory: прямоугольник с ручкой сверху (сумка)
	function Icons.Inventory(parent, color)
		local holder = container()
		holder.Parent = parent

		local body = Instance.new("Frame")
		body.Size = UDim2.fromOffset(16, 12)
		body.AnchorPoint = Vector2.new(0.5, 0.5)
		body.Position = UDim2.fromScale(0.5, 0.6)
		body.BackgroundTransparency = 1
		body.Parent = holder
		local bodyStroke = Instance.new("UIStroke")
		bodyStroke.Thickness = 2
		bodyStroke.Color = color
		bodyStroke.Parent = body
		local bodyCorner = Instance.new("UICorner")
		bodyCorner.CornerRadius = UDim.new(0, 3)
		bodyCorner.Parent = body

		newRing(holder, 8, 2, color).Position = UDim2.fromScale(0.5, 0.3)

		return holder
	end

	-- Stats: три столбика возрастающей высоты
	function Icons.Stats(parent, color)
		local holder = container()
		holder.Parent = parent

		local heights = {8, 13, 17}
		local xs = {0.28, 0.5, 0.72}
		for i = 1, 3 do
			local bar = Instance.new("Frame")
			bar.Size = UDim2.fromOffset(4, heights[i])
			bar.AnchorPoint = Vector2.new(0.5, 1)
			bar.Position = UDim2.new(xs[i], 0, 0.85, 0)
			bar.BackgroundColor3 = color
			bar.BorderSizePixel = 0
			bar.Parent = holder
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 2)
			corner.Parent = bar
		end

		return holder
	end

	-- Chat: скруглённый прямоугольник с "хвостиком"
	function Icons.Chat(parent, color)
		local holder = container()
		holder.Parent = parent

		local bubble = Instance.new("Frame")
		bubble.Size = UDim2.fromOffset(17, 12)
		bubble.AnchorPoint = Vector2.new(0.5, 0.5)
		bubble.Position = UDim2.fromScale(0.5, 0.45)
		bubble.BackgroundTransparency = 1
		bubble.Parent = holder
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = color
		stroke.Parent = bubble
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = bubble

		newLine(holder, UDim2.fromOffset(6, 2), UDim2.fromScale(0.32, 0.78), 45, color)

		return holder
	end

	-- Info: кольцо + вертикальная линия + точка (буква i)
	function Icons.Info(parent, color)
		local holder = container()
		holder.Parent = parent

		newRing(holder, 18, 2, color)

		local dot = Instance.new("Frame")
		dot.Size = UDim2.fromOffset(3, 3)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(0.5, 0.32)
		dot.BackgroundColor3 = color
		dot.BorderSizePixel = 0
		dot.Parent = holder
		local dc = Instance.new("UICorner")
		dc.CornerRadius = UDim.new(1, 0)
		dc.Parent = dot

		newLine(holder, UDim2.fromOffset(2, 8), UDim2.fromScale(0.5, 0.62), 0, color)

		return holder
	end

	return Icons
end)()

-- ============================================================
-- MODULE: LoadingScreen.lua
-- ============================================================
local LoadingScreen = (function()
	local TweenService = game:GetService("TweenService")

	local Animation = Animation
	local Theme = Theme

	local LoadingScreen = {}
	LoadingScreen.__index = LoadingScreen

	local DOT_COUNT = 9
	local DOT_SIZE = 8
	local DOT_GAP = 14

	function LoadingScreen.new(parentGui)
		local self = setmetatable({}, LoadingScreen)

		self._connection = nil
		self._destroyed = false

		-- Корневой контейнер экрана загрузки, изначально невидимый (альфа=1, масштаб=0)
		local root = Instance.new("Frame")
		root.Name = "SkyLineLoadingScreen"
		root.Size = UDim2.fromOffset(340, 200)
		root.AnchorPoint = Vector2.new(0.5, 0.5)
		root.Position = UDim2.fromScale(0.5, 0.5)
		root.BackgroundColor3 = Theme.Colors.Background
		root.BackgroundTransparency = 1
		root.BorderSizePixel = 0
		root.Parent = parentGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.CornerRadius
		corner.Parent = root

		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.Colors.Border
		stroke.Thickness = 1
		stroke.Transparency = 1
		stroke.Parent = root

		-- Масштаб от 0 до 100% через UIScale, синхронно с прозрачностью фона
		local scale = Instance.new("UIScale")
		scale.Scale = 0
		scale.Parent = root

		-- Заголовок — главный визуальный элемент экрана
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, -20, 0, 44)
		title.Position = UDim2.fromScale(0.5, 0.42)
		title.AnchorPoint = Vector2.new(0.5, 0.5)
		title.BackgroundTransparency = 1
		title.Text = "SkyLine Hub"
		title.Font = Enum.Font.GothamBlack
		title.TextSize = 30
		title.TextColor3 = Theme.Colors.TextPrimary
		title.TextTransparency = 1
		title.Parent = root

		-- Тонкая декоративная подпись под заголовком
		local subtitle = Instance.new("TextLabel")
		subtitle.Name = "Subtitle"
		subtitle.Size = UDim2.new(1, -20, 0, 20)
		subtitle.Position = UDim2.fromScale(0.5, 0.58)
		subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
		subtitle.BackgroundTransparency = 1
		subtitle.Text = "INITIALIZING INTERFACE"
		subtitle.Font = Enum.Font.Gotham
		subtitle.TextSize = 11
		subtitle.TextColor3 = Theme.Colors.TextSecondary
		subtitle.TextTransparency = 1
		subtitle.Parent = root

		-- Контейнер волнового индикатора внизу окна
		local waveHolder = Instance.new("Frame")
		waveHolder.Name = "Wave"
		waveHolder.Size = UDim2.fromOffset(DOT_COUNT * DOT_GAP, DOT_SIZE)
		waveHolder.AnchorPoint = Vector2.new(0.5, 0.5)
		waveHolder.Position = UDim2.fromScale(0.5, 0.82)
		waveHolder.BackgroundTransparency = 1
		waveHolder.Parent = root

		local dots = {}
		for i = 1, DOT_COUNT do
			local dot = Instance.new("Frame")
			dot.Size = UDim2.fromOffset(DOT_SIZE, DOT_SIZE)
			dot.Position = UDim2.fromOffset((i - 1) * DOT_GAP, 0)
			dot.BackgroundColor3 = Theme.Colors.SkyBlue
			dot.BackgroundTransparency = 1
			dot.BorderSizePixel = 0
			dot.Parent = waveHolder
			local dc = Instance.new("UICorner")
			dc.CornerRadius = UDim.new(1, 0)
			dc.Parent = dot
			dots[i] = dot
		end

		self.Root = root
		self.Scale = scale
		self.Stroke = stroke
		self.Title = title
		self.Subtitle = subtitle
		self.Dots = dots

		return self
	end

	-- Появление экрана: масштаб 0→100% и прозрачность синхронно, без резких скачков
	function LoadingScreen:PlayIntro()
		Animation.Play(self.Scale, Animation.Presets.Entrance, {Scale = 1})
		Animation.Play(self.Root, Animation.Presets.Entrance, {BackgroundTransparency = 0.05})
		Animation.Play(self.Stroke, Animation.Presets.Entrance, {Transparency = 0.4})

		task.delay(0.15, function()
			Animation.Play(self.Title, Animation.Presets.Smooth, {TextTransparency = 0})
		end)
		task.delay(0.28, function()
			Animation.Play(self.Subtitle, Animation.Presets.Smooth, {TextTransparency = 0.15})
		end)
		task.delay(0.35, function()
			for i, dot in ipairs(self.Dots) do
				task.delay((i - 1) * 0.03, function()
					Animation.Play(dot, Animation.Presets.Smooth, {BackgroundTransparency = 0.2})
				end)
			end
			self:_startWave()
		end)
	end

	-- Волна: непрерывная синусоида прозрачности/масштаба, бегущая слева направо и обратно.
	-- Реализовано через Heartbeat, а не серию Tween'ов — даёт истинно непрерывное движение фазы.
	function LoadingScreen:_startWave()
		local phase = 0
		local speed = 2.4 -- скорость движения гребня волны

		self._connection = Animation.Loop(function(dt)
			if self._destroyed then
				return false
			end
			phase = phase + dt * speed

			for i, dot in ipairs(self.Dots) do
				-- Гребень волны как синусоида, зависящая от позиции точки и времени.
				-- math.sin с bounce по направлению даёт эффект "туда-обратно" без разрывов.
				local wavePos = (math.sin(phase) + 1) / 2 -- 0..1, куда сейчас направлен гребень
				local dotPos = (i - 1) / (DOT_COUNT - 1)   -- 0..1, позиция точки в ряду
				local distance = math.abs(dotPos - wavePos)
				local intensity = math.clamp(1 - distance * 2.2, 0, 1)

				dot.BackgroundTransparency = 0.75 - intensity * 0.65
				local s = 0.7 + intensity * 0.5
				dot.Size = UDim2.fromOffset(DOT_SIZE * s, DOT_SIZE * s)
			end
			return true
		end)
	end

	-- Плавное затемнение и скрытие экрана загрузки после завершения инициализации
	function LoadingScreen:PlayOutro(onComplete)
		if self._connection then
			self._connection:Disconnect()
			self._connection = nil
		end

		Animation.Play(self.Title, Animation.Presets.Smooth, {TextTransparency = 1})
		Animation.Play(self.Subtitle, Animation.Presets.Smooth, {TextTransparency = 1})
		for _, dot in ipairs(self.Dots) do
			Animation.Play(dot, Animation.Presets.Smooth, {BackgroundTransparency = 1})
		end

		task.delay(0.2, function()
			Animation.Play(self.Root, Animation.Presets.SmoothSlow, {BackgroundTransparency = 1})
			Animation.Play(self.Stroke, Animation.Presets.SmoothSlow, {Transparency = 1})
			local scaleTween = Animation.Play(self.Scale, Animation.Presets.SmoothSlow, {Scale = 0.92})

			scaleTween.Completed:Connect(function()
				self.Root.Visible = false
				if onComplete then
					onComplete()
				end
			end)
		end)
	end

	function LoadingScreen:Destroy()
		self._destroyed = true
		if self._connection then
			self._connection:Disconnect()
		end
		self.Root:Destroy()
	end

	return LoadingScreen
end)()

-- ============================================================
-- MODULE: AuroraGlow.lua
-- ============================================================
local AuroraGlow = (function()
	local Animation = Animation
	local Theme = Theme

	local AuroraGlow = {}
	AuroraGlow.__index = AuroraGlow

	-- Четыре свечения по краям (верх/низ/лево/право), каждое — крупный размытый
	-- прямоугольник за пределами экрана с радиальным затуханием через UIGradient.
	local EDGES = {
		{name = "Top",    size = UDim2.new(1.4, 0, 0, 260), position = UDim2.new(-0.2, 0, 0, -160), rotation = 0},
		{name = "Bottom", size = UDim2.new(1.4, 0, 0, 260), position = UDim2.new(-0.2, 0, 1, -100), rotation = 0},
		{name = "Left",   size = UDim2.new(0, 260, 1.4, 0), position = UDim2.new(0, -160, -0.2, 0), rotation = 0},
		{name = "Right",  size = UDim2.new(0, 260, 1.4, 0), position = UDim2.new(1, -100, -0.2, 0), rotation = 0},
	}

	function AuroraGlow.new(parentGui)
		local self = setmetatable({}, AuroraGlow)
		self._destroyed = false
		self._glows = {}

		local root = Instance.new("Frame")
		root.Name = "SkyLineAurora"
		root.Size = UDim2.fromScale(1, 1)
		root.BackgroundTransparency = 1
		root.ZIndex = 0
		root.Parent = parentGui
		self.Root = root

		for _, edge in ipairs(EDGES) do
			local glow = Instance.new("Frame")
			glow.Name = edge.name
			glow.Size = edge.size
			glow.Position = edge.position
			glow.BackgroundColor3 = Theme.Colors.Indigo
			glow.BackgroundTransparency = 1 -- скрыто до PlayIntro
			glow.BorderSizePixel = 0
			glow.ZIndex = 0
			glow.Parent = root

			-- Радиальное затухание к центру экрана: свечение сильное у края, исчезает вглубь
			local gradient = Instance.new("UIGradient")
			local isVertical = edge.name == "Left" or edge.name == "Right"
			gradient.Rotation = isVertical and 0 or 90
			local nearEdge = (edge.name == "Top" or edge.name == "Left") and 0 or 1
			local farEdge = 1 - nearEdge

			gradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(nearEdge, 0.35),
				NumberSequenceKeypoint.new((nearEdge + farEdge) / 2, 0.85),
				NumberSequenceKeypoint.new(farEdge, 1),
			})
			gradient.Parent = glow

			self._glows[edge.name] = glow
		end

		return self
	end

	-- Плавное появление свечения после завершения загрузки (сначала экран темнеет — это
	-- делает вызывающий код через фон окна/бэкдропа, здесь только сам эффект свечения)
	function AuroraGlow:PlayIntro()
		for _, glow in pairs(self._glows) do
			Animation.Play(glow, Animation.Presets.SmoothSlow, {BackgroundTransparency = 0.55})
		end
		self:_startColorCycle()
	end

	-- Медленный случайный переход между индиго/голубым/сине-фиолетовым для каждого края
	-- независимо, что создаёт живое, немеханическое ощущение движения цвета.
	function AuroraGlow:_startColorCycle()
		for _, glow in pairs(self._glows) do
			task.spawn(function()
				while not self._destroyed do
					local nextColor = Theme.GlowPalette[math.random(1, #Theme.GlowPalette)]
					Animation.PlayYield(glow, Animation.Presets.Glow, {BackgroundColor3 = nextColor})
					task.wait(math.random(10, 25) / 10) -- пауза 1.0–2.5с перед следующим переходом
				end
			end)
		end
	end

	function AuroraGlow:Destroy()
		self._destroyed = true
		self.Root:Destroy()
	end

	return AuroraGlow
end)()

-- ============================================================
-- MODULE: Window.lua
-- ============================================================
local Window = (function()
	local Animation = Animation
	local Theme = Theme

	local Window = {}
	Window.__index = Window

	local WINDOW_SIZE = UDim2.fromOffset(720, 460)

	function Window.new(parentGui)
		local self = setmetatable({}, Window)
		self.Tabs = {}
		self.ActiveTab = nil

		-- Контейнер, задающий финальную позицию окна (центр экрана)
		local anchor = Instance.new("Frame")
		anchor.Name = "SkyLineWindowAnchor"
		anchor.Size = WINDOW_SIZE
		anchor.AnchorPoint = Vector2.new(0.5, 0.5)
		anchor.Position = UDim2.fromScale(0.5, 0.5)
		anchor.BackgroundTransparency = 1
		anchor.Visible = false
		anchor.Parent = parentGui

		local root = Instance.new("Frame")
		root.Name = "SkyLineWindow"
		root.Size = UDim2.fromScale(1, 1)
		root.BackgroundColor3 = Theme.Colors.Background
		root.BackgroundTransparency = 1
		root.BorderSizePixel = 0
		root.Parent = anchor

		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.CornerRadius
		corner.Parent = root

		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.Colors.Border
		stroke.Thickness = 1
		stroke.Transparency = 1
		stroke.Parent = root

		local scale = Instance.new("UIScale")
		scale.Scale = 0.92 -- лёгкое увеличение при появлении (не с нуля, как экран загрузки)
		scale.Parent = root

		-- Панель навигации крепится слева, контентная область — оставшееся пространство
		local navSlot = Instance.new("Frame")
		navSlot.Name = "NavSlot"
		navSlot.Size = UDim2.new(0, 84, 1, -24)
		navSlot.Position = UDim2.fromOffset(12, 12)
		navSlot.BackgroundTransparency = 1
		navSlot.Parent = root

		local contentSlot = Instance.new("Frame")
		contentSlot.Name = "ContentSlot"
		contentSlot.Size = UDim2.new(1, -84 - 36, 1, -24)
		contentSlot.Position = UDim2.new(0, 84 + 24, 0, 12)
		contentSlot.BackgroundTransparency = 1
		contentSlot.ClipsDescendants = true
		contentSlot.Parent = root

		self.Anchor = anchor
		self.Root = root
		self.Scale = scale
		self.Stroke = stroke
		self.NavSlot = navSlot
		self.ContentSlot = contentSlot
		self.ParentGui = parentGui

		return self
	end

	-- Появление сверху: позиция смещается вниз из-за верхнего края, масштаб растёт,
	-- прозрачность падает — всё тремя параллельными твинами одного TweenInfo.
	function Window:PlayIntro()
		self.Anchor.Visible = true

		local finalPos = self.Anchor.Position
		local startOffsetY = -60

		self.Anchor.Position = UDim2.new(finalPos.X.Scale, finalPos.X.Offset, finalPos.Y.Scale, finalPos.Y.Offset + startOffsetY)

		Animation.Group({
			{instance = self.Anchor, tweenInfo = Animation.Presets.Entrance, properties = {Position = finalPos}},
			{instance = self.Scale,  tweenInfo = Animation.Presets.Entrance, properties = {Scale = 1}},
			{instance = self.Root,   tweenInfo = Animation.Presets.Entrance, properties = {BackgroundTransparency = 0.05}},
			{instance = self.Stroke, tweenInfo = Animation.Presets.Entrance, properties = {Transparency = 0.4}},
		})
	end

	function Window:GetNavSlot()
		return self.NavSlot
	end

	function Window:GetContentSlot()
		return self.ContentSlot
	end

	return Window
end)()

-- ============================================================
-- MODULE: Navigation.lua
-- ============================================================
local Navigation = (function()
	local Animation = Animation
	local Theme = Theme
	local Icons = Icons

	local Navigation = {}
	Navigation.__index = Navigation

	local BUTTON_SIZE = 52
	local BUTTON_GAP = 20 -- расстояние между кнопками "больше среднего"

	-- Порядок вкладок по умолчанию. Home — первая, активна по умолчанию.
	local DEFAULT_ITEMS = {
		{id = "Home",      icon = "Home"},
		{id = "Inventory",  icon = "Inventory"},
		{id = "Stats",      icon = "Stats"},
		{id = "Chat",       icon = "Chat"},
		{id = "Settings",   icon = "Settings"},
		{id = "Info",       icon = "Info"},
	}

	function Navigation.new(parentSlot, onSelect)
		local self = setmetatable({}, Navigation)
		self._onSelect = onSelect
		self._buttons = {}
		self._activeId = nil

		local root = Instance.new("Frame")
		root.Name = "SkyLineNavigation"
		root.Size = UDim2.fromScale(1, 1)
		root.BackgroundColor3 = Theme.Colors.PanelBackground
		root.BackgroundTransparency = 1
		root.BorderSizePixel = 0
		root.Parent = parentSlot

		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.CornerRadius
		corner.Parent = root

		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.Colors.PanelBorder
		stroke.Thickness = 1
		stroke.Transparency = 1
		stroke.Parent = root

		local scale = Instance.new("UIScale")
		scale.Scale = 0.94
		scale.Parent = root

		-- Единая подсветка, перемещаемая между кнопками (не принадлежит ни одной из них)
		local highlight = Instance.new("Frame")
		highlight.Name = "Highlight"
		highlight.Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE)
		highlight.BackgroundColor3 = Theme.Colors.AccentLight
		highlight.BackgroundTransparency = 1
		highlight.BorderSizePixel = 0
		highlight.ZIndex = 1
		highlight.Parent = root

		local hCorner = Instance.new("UICorner")
		hCorner.CornerRadius = Theme.CornerRadiusSmall
		hCorner.Parent = highlight

		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Vertical
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.Padding = UDim.new(0, BUTTON_GAP)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = root

		self.Root = root
		self.Stroke = stroke
		self.Scale = scale
		self.Highlight = highlight

		for order, item in ipairs(DEFAULT_ITEMS) do
			self:_createButton(item, order)
		end

		-- Активная вкладка по умолчанию — Home (первая в списке), без анимации перемещения
		task.defer(function()
			self:_setActiveInstant(DEFAULT_ITEMS[1].id)
		end)

		return self
	end

	function Navigation:_createButton(item, order)
		local button = Instance.new("TextButton")
		button.Name = item.id
		button.Text = ""
		button.AutoButtonColor = false
		button.Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE)
		button.BackgroundTransparency = 1 -- собственной подсветки у кнопки нет
		button.BorderSizePixel = 0
		button.LayoutOrder = order
		button.ZIndex = 2
		button.Parent = self.Root

		local iconBuilder = Icons[item.icon]
		if iconBuilder then
			iconBuilder(button, Theme.Colors.TextSecondary)
		end

		self._buttons[item.id] = {instance = button, icon = button:FindFirstChildWhichIsA("Frame")}

		button.MouseEnter:Connect(function()
			self:_moveHighlightTo(item.id)
		end)

		button.MouseLeave:Connect(function()
			self:_moveHighlightTo(self._activeId)
		end)

		button.MouseButton1Click:Connect(function()
			self:SetActive(item.id)
		end)
	end

	-- Перемещает единую подсветку к указанной кнопке по траектории панели (плавно)
	function Navigation:_moveHighlightTo(id)
		local entry = self._buttons[id]
		if not entry then
			return
		end
		Animation.Play(self.Highlight, Animation.Presets.Highlight, {
			Position = entry.instance.Position,
			BackgroundTransparency = 0.15,
		})
	end

	-- Устанавливает активную кнопку мгновенно (используется только при инициализации)
	function Navigation:_setActiveInstant(id)
		local entry = self._buttons[id]
		if not entry then
			return
		end
		self._activeId = id
		self.Highlight.Position = entry.instance.Position
		self.Highlight.BackgroundTransparency = 0.15
	end

	-- Переключение активной вкладки: подсветка фиксируется на новой кнопке,
	-- предыдущая деактивируется, движение непрерывное (без скачков — тот же твин Highlight)
	function Navigation:SetActive(id)
		if self._activeId == id then
			return
		end
		local entry = self._buttons[id]
		if not entry then
			return
		end

		self._activeId = id
		self:_moveHighlightTo(id)

		if self._onSelect then
			self._onSelect(id)
		end
	end

	-- Появление панели: выезд из-за левого края + увеличение + прозрачность, одновременно
	function Navigation:PlayIntro()
		local finalPos = self.Root.Position
		self.Root.Position = UDim2.new(finalPos.X.Scale, finalPos.X.Offset - 40, finalPos.Y.Scale, finalPos.Y.Offset)

		Animation.Group({
			{instance = self.Root,   tweenInfo = Animation.Presets.Entrance, properties = {Position = finalPos, BackgroundTransparency = 0.05}},
			{instance = self.Scale,  tweenInfo = Animation.Presets.Entrance, properties = {Scale = 1}},
			{instance = self.Stroke, tweenInfo = Animation.Presets.Entrance, properties = {Transparency = 0.4}},
		})
	end

	return Navigation
end)()

-- ============================================================
-- MODULE: Components/Button.lua
-- ============================================================
local CompButton = (function()
	local Animation = Animation
	local Theme = Theme

	local Button = {}
	Button.__index = Button

	function Button.new(parent, order, config)
		config = config or {}
		local self = setmetatable({}, Button)

		local root = Instance.new("TextButton")
		root.Name = "Button"
		root.AutoButtonColor = false
		root.Size = UDim2.new(1, 0, 0, 42)
		root.LayoutOrder = order
		root.BackgroundColor3 = Theme.Colors.AccentLight
		root.BackgroundTransparency = 0.2
		root.BorderSizePixel = 0
		root.Text = config.Text or "Button"
		root.Font = Enum.Font.GothamMedium
		root.TextSize = 14
		root.TextColor3 = Theme.Colors.TextPrimary
		root.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.CornerRadiusSmall
		corner.Parent = root

		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.Colors.Border
		stroke.Thickness = 1
		stroke.Transparency = 0.5
		stroke.Parent = root

		root.MouseEnter:Connect(function()
			Animation.Play(root, Animation.Presets.Snappy, {BackgroundTransparency = 0.05})
		end)
		root.MouseLeave:Connect(function()
			Animation.Play(root, Animation.Presets.Snappy, {BackgroundTransparency = 0.2})
		end)
		root.MouseButton1Down:Connect(function()
			Animation.Play(root, Animation.Presets.Snappy, {BackgroundTransparency = 0})
		end)
		root.MouseButton1Click:Connect(function()
			if config.Callback then
				config.Callback()
			end
		end)

		self.Root = root
		return self
	end

	return Button
end)()

-- ============================================================
-- MODULE: Components/Toggle.lua
-- ============================================================
local CompToggle = (function()
	local Animation = Animation
	local Theme = Theme

	local Toggle = {}
	Toggle.__index = Toggle

	function Toggle.new(parent, order, config)
		config = config or {}
		local self = setmetatable({}, Toggle)
		self.Value = config.Default or false

		local root = Instance.new("Frame")
		root.Name = "Toggle"
		root.Size = UDim2.new(1, 0, 0, 38)
		root.LayoutOrder = order
		root.BackgroundColor3 = Theme.Colors.AccentLight
		root.BackgroundTransparency = 0.35
		root.BorderSizePixel = 0
		root.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.CornerRadiusSmall
		corner.Parent = root

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -60, 1, 0)
		label.Position = UDim2.fromOffset(12, 0)
		label.Text = config.Text or "Toggle"
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextColor3 = Theme.Colors.TextPrimary
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = root

		local track = Instance.new("TextButton")
		track.Text = ""
		track.AutoButtonColor = false
		track.Size = UDim2.fromOffset(38, 20)
		track.AnchorPoint = Vector2.new(1, 0.5)
		track.Position = UDim2.new(1, -12, 0.5, 0)
		track.BackgroundColor3 = self.Value and Theme.Colors.SkyBlue or Theme.Colors.Border
		track.BorderSizePixel = 0
		track.Parent = root

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = UDim.new(1, 0)
		trackCorner.Parent = track

		local knob = Instance.new("Frame")
		knob.Size = UDim2.fromOffset(16, 16)
		knob.AnchorPoint = Vector2.new(0, 0.5)
		knob.Position = self.Value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		knob.BackgroundColor3 = Theme.Colors.TextPrimary
		knob.BorderSizePixel = 0
		knob.Parent = track

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(1, 0)
		knobCorner.Parent = knob

		self.Root = root
		self.Track = track
		self.Knob = knob

		track.MouseButton1Click:Connect(function()
			self:Set(not self.Value)
		end)

		return self
	end

	function Toggle:Set(value)
		self.Value = value
		Animation.Play(self.Track, Animation.Presets.Highlight, {
			BackgroundColor3 = value and Theme.Colors.SkyBlue or Theme.Colors.Border,
		})
		Animation.Play(self.Knob, Animation.Presets.Highlight, {
			Position = value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		})
		if self.Callback then
			self.Callback(value)
		end
	end

	function Toggle:OnChanged(callback)
		self.Callback = callback
	end

	return Toggle
end)()

-- ============================================================
-- MODULE: Components/Slider.lua
-- ============================================================
local CompSlider = (function()
	local UserInputService = game:GetService("UserInputService")

	local Animation = Animation
	local Theme = Theme

	local Slider = {}
	Slider.__index = Slider

	function Slider.new(parent, order, config)
		config = config or {}
		local self = setmetatable({}, Slider)
		self.Min = config.Min or 0
		self.Max = config.Max or 100
		self.Value = math.clamp(config.Default or self.Min, self.Min, self.Max)
		self._dragging = false

		local root = Instance.new("Frame")
		root.Name = "Slider"
		root.Size = UDim2.new(1, 0, 0, 50)
		root.LayoutOrder = order
		root.BackgroundTransparency = 1
		root.Parent = parent

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 18)
		label.Text = config.Text or "Slider"
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextColor3 = Theme.Colors.TextPrimary
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = root

		local valueLabel = Instance.new("TextLabel")
		valueLabel.BackgroundTransparency = 1
		valueLabel.Size = UDim2.new(1, 0, 0, 18)
		valueLabel.Text = tostring(self.Value)
		valueLabel.Font = Enum.Font.GothamMedium
		valueLabel.TextSize = 13
		valueLabel.TextColor3 = Theme.Colors.TextSecondary
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.Parent = root

		local track = Instance.new("Frame")
		track.Size = UDim2.new(1, 0, 0, 6)
		track.Position = UDim2.fromOffset(0, 28)
		track.BackgroundColor3 = Theme.Colors.Border
		track.BorderSizePixel = 0
		track.Parent = root

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = UDim.new(1, 0)
		trackCorner.Parent = track

		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = Theme.Colors.SkyBlue
		fill.BorderSizePixel = 0
		fill.Size = UDim2.fromScale((self.Value - self.Min) / (self.Max - self.Min), 1)
		fill.Parent = track

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = fill

		local knob = Instance.new("TextButton")
		knob.Text = ""
		knob.AutoButtonColor = false
		knob.Size = UDim2.fromOffset(14, 14)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Position = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 0.5, 0)
		knob.BackgroundColor3 = Theme.Colors.TextPrimary
		knob.BorderSizePixel = 0
		knob.ZIndex = 2
		knob.Parent = track

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(1, 0)
		knobCorner.Parent = knob

		self.Root = root
		self.Track = track
		self.Fill = fill
		self.Knob = knob
		self.ValueLabel = valueLabel

		local function updateFromInputX(inputX)
			local relative = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			local newValue = math.floor(self.Min + relative * (self.Max - self.Min) + 0.5)
			self:Set(newValue)
		end

		knob.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				self._dragging = true
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if self._dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromInputX(input.Position.X)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				self._dragging = false
			end
		end)

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				updateFromInputX(input.Position.X)
				self._dragging = true
			end
		end)

		return self
	end

	function Slider:Set(value)
		self.Value = math.clamp(value, self.Min, self.Max)
		local alpha = (self.Value - self.Min) / (self.Max - self.Min)
		Animation.Play(self.Fill, Animation.Presets.Snappy, {Size = UDim2.fromScale(alpha, 1)})
		Animation.Play(self.Knob, Animation.Presets.Snappy, {Position = UDim2.new(alpha, 0, 0.5, 0)})
		self.ValueLabel.Text = tostring(self.Value)
		if self.Callback then
			self.Callback(self.Value)
		end
	end

	function Slider:OnChanged(callback)
		self.Callback = callback
	end

	return Slider
end)()

-- ============================================================
-- MODULE: Components/Dropdown.lua
-- ============================================================
local CompDropdown = (function()
	local Animation = Animation
	local Theme = Theme

	local Dropdown = {}
	Dropdown.__index = Dropdown

	function Dropdown.new(parent, order, config)
		config = config or {}
		local self = setmetatable({}, Dropdown)
		self.Options = config.Options or {}
		self.Value = config.Default or self.Options[1]
		self._open = false

		local root = Instance.new("Frame")
		root.Name = "Dropdown"
		root.Size = UDim2.new(1, 0, 0, 42)
		root.LayoutOrder = order
		root.BackgroundColor3 = Theme.Colors.AccentLight
		root.BackgroundTransparency = 0.2
		root.BorderSizePixel = 0
		root.ClipsDescendants = true
		root.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.CornerRadiusSmall
		corner.Parent = root

		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.Colors.Border
		stroke.Thickness = 1
		stroke.Transparency = 0.5
		stroke.Parent = root

		local header = Instance.new("TextButton")
		header.Text = ""
		header.AutoButtonColor = false
		header.Size = UDim2.new(1, 0, 0, 42)
		header.BackgroundTransparency = 1
		header.Parent = root

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -30, 1, 0)
		label.Position = UDim2.fromOffset(12, 0)
		label.Text = tostring(self.Value or config.Text or "Select")
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 13
		label.TextColor3 = Theme.Colors.TextPrimary
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = header

		local arrow = Instance.new("TextLabel")
		arrow.BackgroundTransparency = 1
		arrow.Size = UDim2.fromOffset(20, 20)
		arrow.AnchorPoint = Vector2.new(1, 0.5)
		arrow.Position = UDim2.new(1, -10, 0.5, 0)
		arrow.Text = "v"
		arrow.Font = Enum.Font.GothamBold
		arrow.TextSize = 12
		arrow.TextColor3 = Theme.Colors.TextSecondary
		arrow.Parent = header

		local optionsList = Instance.new("Frame")
		optionsList.Position = UDim2.fromOffset(0, 42)
		optionsList.Size = UDim2.new(1, 0, 0, #self.Options * 32)
		optionsList.BackgroundTransparency = 1
		optionsList.Parent = root

		local optionsLayout = Instance.new("UIListLayout")
		optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		optionsLayout.Parent = optionsList

		self.Root = root
		self.Label = label
		self.Arrow = arrow

		for i, option in ipairs(self.Options) do
			local optionButton = Instance.new("TextButton")
			optionButton.Text = tostring(option)
			optionButton.Font = Enum.Font.Gotham
			optionButton.TextSize = 12
			optionButton.TextColor3 = Theme.Colors.TextSecondary
			optionButton.Size = UDim2.new(1, 0, 0, 32)
			optionButton.BackgroundTransparency = 1
			optionButton.LayoutOrder = i
			optionButton.Parent = optionsList

			optionButton.MouseButton1Click:Connect(function()
				self:Select(option)
				self:Close()
			end)
		end

		header.MouseButton1Click:Connect(function()
			self:Toggle()
		end)

		return self
	end

	function Dropdown:Select(option)
		self.Value = option
		self.Label.Text = tostring(option)
		if self.Callback then
			self.Callback(option)
		end
	end

	function Dropdown:Open()
		self._open = true
		local optionsHeight = #self.Options * 32
		Animation.Play(self.Root, Animation.Presets.Smooth, {Size = UDim2.new(1, 0, 0, 42 + optionsHeight)})
		Animation.Play(self.Arrow, Animation.Presets.Smooth, {Rotation = 180})
	end

	function Dropdown:Close()
		self._open = false
		Animation.Play(self.Root, Animation.Presets.Smooth, {Size = UDim2.new(1, 0, 0, 42)})
		Animation.Play(self.Arrow, Animation.Presets.Smooth, {Rotation = 0})
	end

	function Dropdown:Toggle()
		if self._open then
			self:Close()
		else
			self:Open()
		end
	end

	function Dropdown:OnChanged(callback)
		self.Callback = callback
	end

	return Dropdown
end)()

-- ============================================================
-- MODULE: Components/TextBox.lua
-- ============================================================
local CompTextBox = (function()
	local Animation = Animation
	local Theme = Theme

	local TextBox = {}
	TextBox.__index = TextBox

	function TextBox.new(parent, order, config)
		config = config or {}
		local self = setmetatable({}, TextBox)

		local root = Instance.new("Frame")
		root.Name = "TextBox"
		root.Size = UDim2.new(1, 0, 0, 42)
		root.LayoutOrder = order
		root.BackgroundColor3 = Theme.Colors.AccentLight
		root.BackgroundTransparency = 0.2
		root.BorderSizePixel = 0
		root.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.CornerRadiusSmall
		corner.Parent = root

		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.Colors.Border
		stroke.Thickness = 1
		stroke.Transparency = 0.5
		stroke.Parent = root

		local input = Instance.new("TextBox")
		input.Size = UDim2.new(1, -24, 1, 0)
		input.Position = UDim2.fromOffset(12, 0)
		input.BackgroundTransparency = 1
		input.PlaceholderText = config.Placeholder or "Enter text..."
		input.Text = config.Default or ""
		input.Font = Enum.Font.Gotham
		input.TextSize = 13
		input.TextColor3 = Theme.Colors.TextPrimary
		input.PlaceholderColor3 = Theme.Colors.TextSecondary
		input.TextXAlignment = Enum.TextXAlignment.Left
		input.ClearTextOnFocus = false
		input.Parent = root

		self.Root = root
		self.Input = input

		input.Focused:Connect(function()
			Animation.Play(stroke, Animation.Presets.Snappy, {Color = Theme.Colors.SkyBlue, Transparency = 0.1})
		end)

		input.FocusLost:Connect(function(enterPressed)
			Animation.Play(stroke, Animation.Presets.Snappy, {Color = Theme.Colors.Border, Transparency = 0.5})
			if self.Callback then
				self.Callback(input.Text, enterPressed)
			end
		end)

		return self
	end

	function TextBox:OnChanged(callback)
		self.Callback = callback
	end

	function TextBox:Get()
		return self.Input.Text
	end

	return TextBox
end)()

-- ============================================================
-- MODULE: Components/Panel.lua
-- ============================================================
local CompPanel = (function()
	local Theme = Theme

	local Panel = {}
	Panel.__index = Panel

	function Panel.new(parent, order, config)
		config = config or {}
		local self = setmetatable({}, Panel)

		local root = Instance.new("Frame")
		root.Name = "Panel"
		root.Size = UDim2.new(1, 0, 0, config.Height or 80)
		root.LayoutOrder = order
		root.BackgroundColor3 = Theme.Colors.AccentLight
		root.BackgroundTransparency = 0.3
		root.BorderSizePixel = 0
		root.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.CornerRadiusSmall
		corner.Parent = root

		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.Colors.Border
		stroke.Thickness = 1
		stroke.Transparency = 0.5
		stroke.Parent = root

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 12)
		padding.PaddingRight = UDim.new(0, 12)
		padding.PaddingTop = UDim.new(0, 10)
		padding.PaddingBottom = UDim.new(0, 10)
		padding.Parent = root

		if config.Title then
			local title = Instance.new("TextLabel")
			title.BackgroundTransparency = 1
			title.Size = UDim2.new(1, 0, 0, 18)
			title.Text = config.Title
			title.Font = Enum.Font.GothamMedium
			title.TextSize = 13
			title.TextColor3 = Theme.Colors.TextPrimary
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Parent = root
		end

		local body = Instance.new("TextLabel")
		body.Name = "Body"
		body.BackgroundTransparency = 1
		body.Size = UDim2.new(1, 0, 1, config.Title and -18 or 0)
		body.Position = UDim2.new(0, 0, 0, config.Title and 18 or 0)
		body.Text = config.Text or ""
		body.Font = Enum.Font.Gotham
		body.TextSize = 12
		body.TextColor3 = Theme.Colors.TextSecondary
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.TextWrapped = true
		body.Parent = root

		self.Root = root
		self.Body = body

		return self
	end

	function Panel:SetText(text)
		self.Body.Text = text
	end

	return Panel
end)()

-- ============================================================
-- MODULE: Components/Loader.lua
-- ============================================================
local CompLoader = (function()
	local Animation = Animation
	local Theme = Theme

	local Loader = {}
	Loader.__index = Loader

	local DOT_COUNT = 5
	local DOT_SIZE = 6
	local DOT_GAP = 12

	function Loader.new(parent, order, config)
		config = config or {}
		local self = setmetatable({}, Loader)
		self._destroyed = false

		local root = Instance.new("Frame")
		root.Name = "Loader"
		root.Size = UDim2.new(1, 0, 0, 30)
		root.LayoutOrder = order
		root.BackgroundTransparency = 1
		root.Parent = parent

		local holder = Instance.new("Frame")
		holder.Size = UDim2.fromOffset(DOT_COUNT * DOT_GAP, DOT_SIZE)
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.BackgroundTransparency = 1
		holder.Parent = root

		local dots = {}
		for i = 1, DOT_COUNT do
			local dot = Instance.new("Frame")
			dot.Size = UDim2.fromOffset(DOT_SIZE, DOT_SIZE)
			dot.Position = UDim2.fromOffset((i - 1) * DOT_GAP, 0)
			dot.BackgroundColor3 = Theme.Colors.SkyBlue
			dot.BackgroundTransparency = 0.4
			dot.BorderSizePixel = 0
			dot.Parent = holder
			local dc = Instance.new("UICorner")
			dc.CornerRadius = UDim.new(1, 0)
			dc.Parent = dot
			dots[i] = dot
		end

		self.Root = root
		self.Dots = dots

		self:_start()

		return self
	end

	function Loader:_start()
		local phase = 0
		self._connection = Animation.Loop(function(dt)
			if self._destroyed then
				return false
			end
			phase = phase + dt * 2.4
			for i, dot in ipairs(self.Dots) do
				local wavePos = (math.sin(phase) + 1) / 2
				local dotPos = (i - 1) / (DOT_COUNT - 1)
				local distance = math.abs(dotPos - wavePos)
				local intensity = math.clamp(1 - distance * 2.2, 0, 1)
				dot.BackgroundTransparency = 0.7 - intensity * 0.6
				local s = 0.7 + intensity * 0.4
				dot.Size = UDim2.fromOffset(DOT_SIZE * s, DOT_SIZE * s)
			end
			return true
		end)
	end

	function Loader:Destroy()
		self._destroyed = true
		if self._connection then
			self._connection:Disconnect()
		end
		self.Root:Destroy()
	end

	return Loader
end)()

-- ============================================================
-- MODULE: Components/Tab.lua
-- ============================================================
local CompTab = (function()
	local Animation = Animation
	local Theme = Theme

	local Button = CompButton
	local Toggle = CompToggle
	local Slider = CompSlider
	local Dropdown = CompDropdown
	local TextBox = CompTextBox
	local Panel = CompPanel
	local Loader = CompLoader

	local Tab = {}
	Tab.__index = Tab

	function Tab.new(parentContentSlot, name)
		local self = setmetatable({}, Tab)
		self.Name = name

		local root = Instance.new("ScrollingFrame")
		root.Name = "Tab_" .. name
		root.Size = UDim2.fromScale(1, 1)
		root.BackgroundTransparency = 1
		root.BorderSizePixel = 0
		root.ScrollBarThickness = 3
		root.ScrollBarImageColor3 = Theme.Colors.Border
		root.CanvasSize = UDim2.new(0, 0, 0, 0)
		root.AutomaticCanvasSize = Enum.AutomaticSize.Y
		root.Visible = false
		root.Position = UDim2.fromOffset(0, 8)
		root.Parent = parentContentSlot

		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Vertical
		list.HorizontalAlignment = Enum.HorizontalAlignment.Left
		list.Padding = UDim.new(0, 10)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = root

		local padding = Instance.new("UIPadding")
		padding.PaddingRight = UDim.new(0, 8)
		padding.Parent = root

		self.Root = root
		self._order = 0

		return self
	end

	function Tab:_nextOrder()
		self._order = self._order + 1
		return self._order
	end

	function Tab:Show()
		self.Root.Visible = true
		self.Root.Position = UDim2.fromOffset(0, 8)
		self.Root.GroupTransparency = 0
		Animation.Play(self.Root, Animation.Presets.Smooth, {Position = UDim2.fromOffset(0, 0)})
	end

	function Tab:Hide()
		self.Root.Visible = false
	end

	function Tab:AddButton(config)
		return Button.new(self.Root, self:_nextOrder(), config)
	end

	function Tab:AddToggle(config)
		return Toggle.new(self.Root, self:_nextOrder(), config)
	end

	function Tab:AddSlider(config)
		return Slider.new(self.Root, self:_nextOrder(), config)
	end

	function Tab:AddDropdown(config)
		return Dropdown.new(self.Root, self:_nextOrder(), config)
	end

	function Tab:AddTextBox(config)
		return TextBox.new(self.Root, self:_nextOrder(), config)
	end

	function Tab:AddPanel(config)
		return Panel.new(self.Root, self:_nextOrder(), config)
	end

	function Tab:AddLoader(config)
		return Loader.new(self.Root, self:_nextOrder(), config)
	end

	return Tab
end)()

-- ============================================================
-- MODULE: Components/Notification.lua
-- ============================================================
local CompNotification = (function()
	local Animation = Animation
	local Theme = Theme

	local Notification = {}
	Notification.__index = Notification

	local WIDTH = 280

	function Notification.new(parentGui, config)
		config = config or {}
		local self = setmetatable({}, Notification)

		-- Контейнер уведомлений создаётся один раз и переиспользуется (хранится в parentGui)
		local container = parentGui:FindFirstChild("SkyLineNotifications")
		if not container then
			container = Instance.new("Frame")
			container.Name = "SkyLineNotifications"
			container.Size = UDim2.fromOffset(WIDTH, 400)
			container.AnchorPoint = Vector2.new(1, 1)
			container.Position = UDim2.new(1, -20, 1, -20)
			container.BackgroundTransparency = 1
			container.Parent = parentGui

			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			layout.Padding = UDim.new(0, 8)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = container
		end

		local root = Instance.new("Frame")
		root.Name = "Notification"
		root.Size = UDim2.new(1, 0, 0, 0)
		root.AutomaticSize = Enum.AutomaticSize.Y
		root.BackgroundColor3 = Theme.Colors.Background
		root.BackgroundTransparency = 1
		root.BorderSizePixel = 0
		root.Parent = container

		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.CornerRadiusSmall
		corner.Parent = root

		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.Colors.Border
		stroke.Thickness = 1
		stroke.Transparency = 1
		stroke.Parent = root

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 14)
		padding.PaddingRight = UDim.new(0, 14)
		padding.PaddingTop = UDim.new(0, 10)
		padding.PaddingBottom = UDim.new(0, 10)
		padding.Parent = root

		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(1, 0, 0, 18)
		title.Text = config.Title or "Notification"
		title.Font = Enum.Font.GothamMedium
		title.TextSize = 13
		title.TextColor3 = Theme.Colors.TextPrimary
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextTransparency = 1
		title.Parent = root

		local body = Instance.new("TextLabel")
		body.Size = UDim2.new(1, 0, 0, 0)
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.Position = UDim2.fromOffset(0, 18)
		body.BackgroundTransparency = 1
		body.Text = config.Text or ""
		body.Font = Enum.Font.Gotham
		body.TextSize = 12
		body.TextColor3 = Theme.Colors.TextSecondary
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextWrapped = true
		body.TextTransparency = 1
		body.Parent = root

		self.Root = root
		self.Stroke = stroke
		self.Title = title
		self.Body = body

		self:_playIntro()
		task.delay(config.Duration or 4, function()
			self:_playOutro()
		end)

		return self
	end

	function Notification:_playIntro()
		Animation.Play(self.Root, Animation.Presets.Smooth, {BackgroundTransparency = 0.05})
		Animation.Play(self.Stroke, Animation.Presets.Smooth, {Transparency = 0.4})
		Animation.Play(self.Title, Animation.Presets.Smooth, {TextTransparency = 0})
		Animation.Play(self.Body, Animation.Presets.Smooth, {TextTransparency = 0.15})
	end

	function Notification:_playOutro()
		Animation.Play(self.Root, Animation.Presets.Smooth, {BackgroundTransparency = 1})
		Animation.Play(self.Stroke, Animation.Presets.Smooth, {Transparency = 1})
		Animation.Play(self.Title, Animation.Presets.Smooth, {TextTransparency = 1})
		local tween = Animation.Play(self.Body, Animation.Presets.Smooth, {TextTransparency = 1})
		tween.Completed:Connect(function()
			self.Root:Destroy()
		end)
	end

	return Notification
end)()

-- ============================================================
-- MODULE: init.lua
-- ============================================================
local Main = (function()
	local Players = game:GetService("Players")

	local LoadingScreen = LoadingScreen
	local AuroraGlow = AuroraGlow
	local Window = Window
	local Navigation = Navigation
	local Tab = CompTab
	local Notification = CompNotification

	local SkyLineHub = {}
	SkyLineHub.__index = SkyLineHub

	function SkyLineHub.new()
		local self = setmetatable({}, SkyLineHub)

		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "SkyLineHub"
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.DisplayOrder = 100
		screenGui.Parent = playerGui

		self.ScreenGui = screenGui
		self._windowCreated = false

		return self
	end

	-- Внутренний класс WindowHandle: то, что возвращается из CreateWindow.
	-- Держит ссылку на вкладки и панель навигации, чтобы CreateTab и переключение
	-- вкладок работали через одну и ту же таблицу состояния.
	local WindowHandle = {}
	WindowHandle.__index = WindowHandle

	function WindowHandle.new(screenGui, window)
		local self = setmetatable({}, WindowHandle)
		self._screenGui = screenGui
		self._window = window
		self._tabs = {}       -- id -> Tab
		self._navigation = nil
		self._defaultShown = false
		return self
	end

	-- Создаёт вкладку и сразу регистрирует её в общей таблице, которую использует
	-- как переключатель Navigation, так и логика "показать Home по умолчанию".
	function WindowHandle:CreateTab(name)
		name = name or "Tab"
		local tab = Tab.new(self._window:GetContentSlot(), name)
		self._tabs[name] = tab

		if name == "Home" and not self._defaultShown then
			self._defaultShown = true
			tab:Show()
		end

		return tab
	end

	-- Привязывает уже созданную панель навигации к этому окну (вызывается из CreateWindow
	-- после того, как панель асинхронно появится по завершении интро-анимаций).
	function WindowHandle:_attachNavigation(navigation)
		self._navigation = navigation
	end

	function WindowHandle:_showTab(id)
		for tabId, tab in pairs(self._tabs) do
			if tabId == id then
				tab:Show()
			else
				tab:Hide()
			end
		end
	end

	function WindowHandle:Notify(config)
		return Notification.new(self._screenGui, config)
	end

	-- Создаёт главное окно интерфейса. Запускает полную последовательность:
	-- экран загрузки -> затемнение -> свечение по краям -> появление панели/окна -> вкладка Home.
	function SkyLineHub:CreateWindow()
		if self._windowCreated then
			warn("SkyLine Hub: CreateWindow вызван повторно — возвращается уже существующее окно.")
			return self._windowHandle
		end
		self._windowCreated = true

		local loadingScreen = LoadingScreen.new(self.ScreenGui)
		local window = Window.new(self.ScreenGui)
		local handle = WindowHandle.new(self.ScreenGui, window)
		self._windowHandle = handle

		loadingScreen:PlayIntro()

		-- Имитация инициализации библиотеки (в реальном использовании здесь могла бы быть
		-- реальная асинхронная загрузка данных). Затем — плавный переход к основному интерфейсу.
		task.delay(1.8, function()
			loadingScreen:PlayOutro(function()
				loadingScreen:Destroy()

				local aurora = AuroraGlow.new(self.ScreenGui)
				aurora:PlayIntro()
				handle._aurora = aurora

				task.delay(0.25, function()
					window:PlayIntro()

					local navigation = Navigation.new(window:GetNavSlot(), function(id)
						handle:_showTab(id)
					end)
					navigation:PlayIntro()
					handle:_attachNavigation(navigation)
				end)
			end)
		end)

		return handle
	end

	-- Показывает уведомление, не привязанное к конкретному окну (доступно ещё до CreateWindow).
	function SkyLineHub:Notify(config)
		return Notification.new(self.ScreenGui, config)
	end

	function SkyLineHub:Destroy()
		self.ScreenGui:Destroy()
	end

	return SkyLineHub
end)()

-- ============================================================
-- EXPORT
-- ============================================================
return Main
