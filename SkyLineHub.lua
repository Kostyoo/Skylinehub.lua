--[[
	═════════════════════════════════════════════════════════
	  SKYLINE HUB • UI Library v1.0 • Pure Lua • No deps
	  KRNL / Synapse / Fluxus / Wave / Delta compatible
	═════════════════════════════════════════════════════════
]]

-- [0] GUARD -----------------------------------------------------------
do
	local g = _G
	pcall(function() if getgenv then g = getgenv() end end)
	if g.SkyLineHubInstance and type(g.SkyLineHubInstance.Destroy) == "function" then
		pcall(function() g.SkyLineHubInstance:Destroy() end)
	end
end

-- [1] SERVICES --------------------------------------------------------
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local Stats            = game:GetService("Stats")
local Lighting         = game:GetService("Lighting")
local TextService      = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local tries = 0
while not LocalPlayer and tries < 100 do
	task.wait(0.1)
	tries = tries + 1
	LocalPlayer = Players.LocalPlayer
end
if not LocalPlayer then
	warn("[SkyLine Hub] LocalPlayer not found")
	return {}
end

-- [2] SHORTCUTS -------------------------------------------------------
local C      = Color3.fromRGB
local floor  = math.floor
local Insert = table.insert

local function clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end
local function round(v, inc) inc = inc or 1 return floor(v / inc + 0.5) * inc end

-- [3] COLORS / FONTS / THEMES -----------------------------------------
local COLORS = {
	Background  = C(34, 49, 69),
	Secondary   = C(52, 65, 83),
	Stroke      = C(67, 85, 109),
	Accent      = C(91, 196, 203),
	Text        = C(240, 244, 248),
	SubText     = C(168, 180, 196),
	Hover       = C(45, 61, 85),
	HoverStrong = C(58, 78, 106),
	Danger      = C(196, 74, 84),
	DangerHover = C(160, 55, 64),
}

local FONT      = Enum.Font.Gotham
local FONT_MED  = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_ICON = Enum.Font.SourceSansBold

local THEMES = {
	["Ocean"]        = { Accent = C(91, 196, 203),  GlowA = C(96, 88, 235),  GlowB = C(91, 196, 203),  Start = C(72, 110, 150) },
	["Indigo Night"] = { Accent = C(139, 122, 255), GlowA = C(88, 70, 230),  GlowB = C(160, 120, 255), Start = C(90, 95, 170) },
	["Emerald"]      = { Accent = C(80, 220, 150),  GlowA = C(40, 180, 130), GlowB = C(130, 255, 200), Start = C(60, 140, 110) },
	["Crimson"]      = { Accent = C(255, 105, 120), GlowA = C(210, 60, 100), GlowB = C(255, 140, 160), Start = C(170, 85, 100) },
}
local Theme = THEMES.Ocean

-- [4] SCALE SYSTEM ----------------------------------------------------
local Camera    = workspace.CurrentCamera
local SCALE     = 1
local ResizeCbs = {}

local function ComputeScale()
	local vp = Vector2.new(1920, 1080)
	pcall(function()
		if Camera then vp = Camera.ViewportSize end
	end)
	SCALE = clamp(math.min(vp.X / 1280, vp.Y / 720), 0.55, 2)
end
ComputeScale()

local function S(v) return v * SCALE end
local function OnResize(fn) Insert(ResizeCbs, fn) end


-- [5] INSTANCE HELPERS ------------------------------------------------
local function New(class, props, children)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then inst[k] = v end
		end
	end
	if children then
		for _, ch in ipairs(children) do ch.Parent = inst end
	end
	if props and props.Parent then inst.Parent = props.Parent end
	return inst
end

local function Corner(parent, px)
	return New("UICorner", { CornerRadius = UDim.new(0, px or 8), Parent = parent })
end

local function Pad(parent, l, t, r, b)
	return New("UIPadding", {
		PaddingLeft   = UDim.new(0, l or 0),
		PaddingTop    = UDim.new(0, t or 0),
		PaddingRight  = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
		Parent        = parent,
	})
end

local function StrokeOf(parent, color, thickness, transparency)
	return New("UIStroke", {
		Color           = color or COLORS.Stroke,
		Thickness       = thickness or 1,
		Transparency    = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent          = parent,
	})
end

local OrderCounter = 0
local function NextOrder()
	OrderCounter = OrderCounter + 1
	return OrderCounter
end

local function ListLayout(parent, gap)
	return New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding       = UDim.new(0, gap or 0),
		SortOrder     = Enum.SortOrder.LayoutOrder,
		Parent        = parent,
	})
end

local function Measure(text, size, font)
	local ok, res = pcall(function()
		return TextService:GetTextSize(tostring(text), size, font or FONT_MED, Vector2.new(10000, 10000))
	end)
	if ok and res then return res.X end
	return #tostring(text) * size * 0.58
end

-- [6] CONNECTION HUB / THREADS / TWEEN --------------------------------
local Conns = {}
local function Bind(signal, fn)
	local ok, conn = pcall(function() return signal:Connect(fn) end)
	if ok and conn then Insert(Conns, conn) return conn end
	return nil
end

local Threads = {}
local function Spawn(fn)
	local co = task.spawn(fn)
	Insert(Threads, co)
	return co
end

local HeavyOff = false

local function SafeCall(fn, ...)
	if type(fn) ~= "function" then return nil end
	local args = { ... }
	local ok, err = pcall(fn, unpack(args))
	if not ok then warn("[SkyLine Hub] callback error:", err) end
	return ok
end

local function Tween(obj, dur, props, style, dir)
	if not obj then return nil end
	dur = dur or 0.25
	if HeavyOff then dur = math.min(dur, 0.12) style = Enum.EasingStyle.Linear dir = nil end
	local ok, tw = pcall(function()
		return TweenService:Create(obj,
			TweenInfo.new(dur, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
			props)
	end)
	if not ok or not tw then
		pcall(function()
			for k, v in pairs(props) do obj[k] = v end
		end)
		return nil
	end
	pcall(function() tw:Play() end)
	return tw
end

Bind(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
	Camera = workspace.CurrentCamera
	ComputeScale()
	for _, cb in ipairs(ResizeCbs) do pcall(cb) end
end)
if Camera then
	Bind(Camera:GetPropertyChangedSignal("ViewportSize"), function()
		ComputeScale()
		for _, cb in ipairs(ResizeCbs) do pcall(cb) end
	end)
end


-- [7] THEME REGISTRY --------------------------------------------------
local ActiveESP   = nil
local StaticGlow  = nil

local ThemeBinds = {}
local function BindTheme(obj, prop, kind)
	Insert(ThemeBinds, { obj = obj, prop = prop, kind = kind })
end

local GradientBinds   = {} -- UIGradient (заливка слайдеров)
local ToggleRenderers = {} -- fn() перерисовка тумблеров при смене темы

local function ApplyTheme(name)
	local th = THEMES[name]
	if not th then return false end
	Theme = th
	for _, bind in ipairs(ThemeBinds) do
		pcall(function()
			if bind.obj and bind.obj.Parent then bind.obj[bind.prop] = th[bind.kind] end
		end)
	end
	for _, grad in ipairs(GradientBinds) do
		pcall(function() grad.Color = ColorSequence.new(th.Start, th.Accent) end)
	end
	for _, fn in ipairs(ToggleRenderers) do pcall(fn) end
	pcall(function() if ActiveESP then ActiveESP.FillColor = th.Accent end end)
	pcall(function() if StaticGlow then StaticGlow() end end)
	return true
end

-- [8] SCREENGUI / LAYERS / AMBIENT GLOW -------------------------------
local function Protect(gui)
	pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui) end
	end)
	local parented = false
	pcall(function()
		if gethui then gui.Parent = gethui() parented = true end
	end)
	if not parented then
		local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
		if not ok or not gui.Parent then
			gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
		end
	end
end

local ScreenGui = New("ScreenGui", {
	Name           = "SkyLineHub",
	ResetOnSpawn   = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder   = 9999,
})
Protect(ScreenGui)

local AmbientDim = New("Frame", {
	Name                   = "AmbientDim",
	BackgroundColor3       = C(0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.fromScale(1, 1),
	Parent                 = ScreenGui,
})

local GlowLayer = New("Frame", {
	Name                   = "GlowLayer",
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.fromScale(1, 1),
	Parent                 = ScreenGui,
})

local GlowEdges = {}
do
	local defs = {
		{ Size = UDim2.new(1, 0, 0, S(260)), Pos = UDim2.new(0, 0, 0, 0),        Rot = 90, Seq = { { 0, 0.05 }, { 1, 1 } } },
		{ Size = UDim2.new(1, 0, 0, S(260)), Pos = UDim2.new(0, 0, 1, -S(260)), Rot = 90, Seq = { { 0, 1 }, { 1, 0.05 } } },
		{ Size = UDim2.new(0, S(260), 1, 0), Pos = UDim2.new(0, 0, 0, 0),        Rot = 0,  Seq = { { 0, 0.05 }, { 1, 1 } } },
		{ Size = UDim2.new(0, S(260), 1, 0), Pos = UDim2.new(1, -S(260), 0, 0), Rot = 0,  Seq = { { 0, 1 }, { 1, 0.05 } } },
	}
	for i, d in ipairs(defs) do
		local kps = {}
		for _, p in ipairs(d.Seq) do
			kps[#kps + 1] = NumberSequenceKeypoint.new(p[1], p[2])
		end
		local f = New("Frame", {
			BackgroundColor3       = Theme.GlowA:Lerp(Theme.GlowB, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Size                   = d.Size,
			Position               = d.Pos,
			ZIndex                 = i,
			Parent                 = GlowLayer,
		})
		New("UIGradient", { Rotation = d.Rot, Transparency = NumberSequence.new(kps), Parent = f })
		GlowEdges[i] = {
			Frame = f, Base = 0.10,
			s1 = 0.10 + i * 0.037, s2 = 0.06 + i * 0.053,
			p1 = (i - 1) * 1.73,   p2 = (i - 1) * 2.31,
		}
	end
end

StaticGlow = function()
	local mix = Theme.GlowA:Lerp(Theme.GlowB, 0.5)
	for _, e in ipairs(GlowEdges) do
		e.Frame.BackgroundColor3 = mix
	end
end

local GlowT = 0
Bind(RunService.Heartbeat, function(dt)
	GlowT = GlowT + dt
	if HeavyOff then return end
	for _, e in ipairs(GlowEdges) do
		local m = 0.5 + 0.5 * math.sin(GlowT * e.s1 + e.p1) * math.cos(GlowT * e.s2 + e.p2)
		e.Frame.BackgroundColor3 = Theme.GlowA:Lerp(Theme.GlowB, m)
	end
end)

-- свечение проявляется сразу и живёт вечно (независимо от загрузки)
task.delay(0.8, function()
	for i, e in ipairs(GlowEdges) do
		task.delay(i * 0.08, function()
			Tween(e.Frame, 1.2, { BackgroundTransparency = e.Base })
		end)
	end
end)

local WindowLayer = New("CanvasGroup", {
	Name                   = "WindowLayer",
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	GroupTransparency      = 0,
	Size                   = UDim2.fromScale(1, 1),
	Parent                 = ScreenGui,
})

local PopupLayer = New("Frame", {
	Name                   = "PopupLayer",
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.fromScale(1, 1),
	Parent                 = ScreenGui,
})

local ToastLayer = New("Frame", {
	Name                   = "ToastLayer",
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.fromScale(1, 1),
	Parent                 = ScreenGui,
})


-- [9] NOTIFICATIONS ---------------------------------------------------
local ToastList = {}

local function RelayoutToasts()
	local y = S(14)
	for _, card in ipairs(ToastList) do
		Tween(card, 0.28, { Position = UDim2.new(1, -S(14), 0, y) }, Enum.EasingStyle.Quart)
		y = y + (card:GetAttribute("H") or S(52)) + S(8)
	end
end

local function RemoveToast(card)
	for i = #ToastList, 1, -1 do
		if ToastList[i] == card then
			table.remove(ToastList, i)
			break
		end
	end
	Tween(card, 0.25, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.26, function() pcall(function() card:Destroy() end) end)
	RelayoutToasts()
end

local function Notify(title, msg, dur)
	title = tostring(title or "")
	msg = msg and tostring(msg) or ""
	dur = dur or 2.6
	while #ToastList >= 4 do
		local old = table.remove(ToastList, 1)
		if old then pcall(function() old:Destroy() end) end
	end
	local w = clamp(math.max(Measure(title, S(13), FONT_BOLD), Measure(msg, S(12), FONT)) + S(44), S(190), S(330))
	local h = msg ~= "" and S(54) or S(40)
	local card = New("CanvasGroup", {
		Name              = "Toast",
		BackgroundColor3  = COLORS.Secondary,
		BorderSizePixel   = 0,
		AnchorPoint       = Vector2.new(1, 0),
		Position          = UDim2.new(1, S(w) + S(30), 0, S(14)),
		Size              = UDim2.fromOffset(S(w), S(h)),
		GroupTransparency = 1,
		ZIndex            = 90,
		Parent            = ToastLayer,
	})
	card:SetAttribute("H", h)
	Corner(card, S(10))
	StrokeOf(card)
	New("Frame", {
		BackgroundColor3       = Theme.Accent,
		BackgroundTransparency = 0.1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(0, S(4), 1, 0),
		Parent                 = card,
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(16), msg ~= "" and S(8) or 0),
		Size                   = UDim2.new(1, -S(28), 0, S(16)),
		Font                   = FONT_BOLD,
		Text                   = title,
		TextColor3             = COLORS.Text,
		TextSize               = S(13),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = card,
	})
	if msg ~= "" then
		New("TextLabel", {
			BackgroundTransparency = 1,
			Position               = UDim2.fromOffset(S(16), S(27)),
			Size                   = UDim2.new(1, -S(28), 0, S(20)),
			Font                   = FONT,
			Text                   = msg,
			TextColor3             = COLORS.SubText,
			TextSize               = S(12),
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextTruncate           = Enum.TextTruncate.AtEnd,
			Parent                 = card,
		})
	end
	Insert(ToastList, card)
	Tween(card, 0.2, { GroupTransparency = 0 })
	RelayoutToasts()
	task.delay(dur, function() RemoveToast(card) end)
	return card
end

-- [10] CLIPBOARD / FILESYSTEM -----------------------------------------
local function Copy(text)
	local done = false
	if type(setclipboard) == "function" then done = pcall(setclipboard, text) end
	if not done and type(toclipboard) == "function" then done = pcall(toclipboard, text) end
	return done
end

local FOLDER = "SkyLineHub"
local FS = {}
function FS.Write(path, data)
	if type(writefile) ~= "function" then return false end
	return pcall(writefile, path, data)
end
function FS.Read(path)
	if type(readfile) ~= "function" then return nil end
	local ok, r = pcall(readfile, path)
	if ok then return r end
	return nil
end
function FS.Exists(path)
	if type(isfile) ~= "function" then return false end
	local ok, r = pcall(isfile, path)
	if ok then return r end
	return false
end
function FS.List(folder)
	if type(listfiles) ~= "function" then return {} end
	local ok, r = pcall(listfiles, folder)
	if ok and type(r) == "table" then return r end
	return {}
end
local function EnsureFolder()
	if type(makefolder) == "function" then pcall(makefolder, FOLDER) end
end


-- [11] FLAGS / PERSISTENCE --------------------------------------------
local Flags = {}
local AutoSaveOn = true
local LoadingFlags = false
local ASToken = 0

local SavePreset  -- forward
local LoadPreset  -- forward

local function RegFlag(name, ctrl)
	if type(name) == "string" and #name > 0 and type(ctrl) == "table" then
		Flags[name] = ctrl
	end
end
local RegisterFlag = RegFlag -- алиас (фабрики используют это имя)

local function ScheduleAutoSave()
	if not AutoSaveOn or LoadingFlags then return end
	ASToken = ASToken + 1
	local myToken = ASToken
	task.delay(1.2, function()
		if AutoSaveOn and ASToken == myToken then
			pcall(SavePreset, "_autosave", true)
		end
	end)
end

local function ListPresets()
	local names = {}
	for _, path in ipairs(FS.List(FOLDER)) do
		local base = string.match(path, "[\\/]?([^\\/]*)$") or path
		if string.sub(base, -8) == ".skyline" then
			Insert(names, string.sub(base, 1, -9))
		end
	end
	table.sort(names)
	return names
end

SavePreset = function(name, quiet)
	if type(name) ~= "string" then return false end
	name = string.gsub(name, "[^%w%-_ ]", "")
	if #name == 0 then return false end
	EnsureFolder()
	local data = { version = "1.0", flags = {} }
	for flagName, ctrl in pairs(Flags) do
		local ok, v = pcall(function() return ctrl.Get() end)
		if ok and v ~= nil then data.flags[flagName] = v end
	end
	local okEnc, json = pcall(function() return HttpService:JSONEncode(data) end)
	if not okEnc or type(json) ~= "string" then
		if not quiet then Notify("SkyLine Hub", "Ошибка кодирования пресета") end
		return false
	end
	local okWrite = FS.Write(FOLDER .. "/" .. name .. ".skyline", json)
	if not okWrite and not quiet then
		Notify("SkyLine Hub", "writefile недоступен в этом экзекуторе")
	end
	return okWrite
end

LoadPreset = function(name, quiet)
	if type(name) ~= "string" then return false end
	local raw = FS.Read(FOLDER .. "/" .. name .. ".skyline")
	if not raw then
		if not quiet then Notify("SkyLine Hub", "Пресет не найден: " .. name) end
		return false
	end
	local okDec, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not okDec or type(data) ~= "table" or type(data.flags) ~= "table" then
		if not quiet then Notify("SkyLine Hub", "Пресет повреждён: " .. name) end
		return false
	end
	LoadingFlags = true
	for flagName, value in pairs(data.flags) do
		local ctrl = Flags[flagName]
		if ctrl and type(ctrl.Set) == "function" then
			pcall(ctrl.Set, ctrl, value)
		end
	end
	LoadingFlags = false
	if not quiet then Notify("SkyLine Hub", "Пресет загружен: " .. name) end
	return true
end

-- ═══════════════════ [12] INPUT MODAL ═══════════════════
local function RequestInput(titleText, placeholderText, onSubmit, onCancel)
	local closed = false
	local function cleanup()
		if closed then return end
		closed = true
	end
	local scrim = New("TextButton", {
		Name                   = "InputScrim",
		Text                   = "",
		AutoButtonColor        = false,
		BackgroundColor3       = C(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.fromScale(1, 1),
		ZIndex                 = 100,
		Parent                 = PopupLayer,
	})
	Tween(scrim, 0.2, { BackgroundTransparency = 0.45 })
	local card = New("CanvasGroup", {
		Name                   = "InputCard",
		BackgroundColor3       = COLORS.Background,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.fromScale(0.5, 0.46),
		Size                   = UDim2.fromOffset(S(320), S(158)),
		GroupTransparency      = 1,
		ZIndex                 = 101,
		Parent                 = PopupLayer,
	})
	Corner(card, S(14))
	StrokeOf(card)
	Tween(card, 0.22, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(18), S(14)),
		Size                   = UDim2.new(1, -S(36), 0, S(18)),
		Font                   = FONT_BOLD,
		Text                   = tostring(titleText or ""),
		TextColor3             = COLORS.Text,
		TextSize               = S(14),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = card,
	})
	local boxHolder = New("Frame", {
		BackgroundColor3       = COLORS.Secondary,
		BackgroundTransparency = 0,
		BorderSizePixel        = 0,
		Position               = UDim2.fromOffset(S(16), S(44)),
		Size                   = UDim2.new(1, -S(32), 0, S(36)),
		ZIndex                 = 102,
		Parent                 = card,
	})
	Corner(boxHolder, S(8))
	StrokeOf(boxHolder)
	local box = New("TextBox", {
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(12), 0),
		Size                   = UDim2.new(1, -S(24), 1, 0),
		Font                   = FONT_MED,
		Text                   = "",
		PlaceholderText        = tostring(placeholderText or ""),
		PlaceholderColor3      = COLORS.SubText,
		TextColor3             = COLORS.Text,
		TextSize               = S(13),
		TextXAlignment         = Enum.TextXAlignment.Left,
		ClearTextOnFocus       = false,
		ZIndex                 = 103,
		Parent                 = boxHolder,
	})
	local function closeAll()
		cleanup()
		Tween(scrim, 0.2, { BackgroundTransparency = 1 })
		task.delay(0.21, function() pcall(function() scrim:Destroy() end) end)
		Tween(card, 0.18, { GroupTransparency = 1 })
		task.delay(0.19, function() pcall(function() card:Destroy() end) end)
	end
	local function confirm()
		local txt = tostring(box.Text or "")
		txt = string.gsub(txt, "^%s+", "")
		txt = string.gsub(txt, "%s+$", "")
		if #txt == 0 then return end
		closeAll()
		SafeCall(onSubmit, txt)
	end
	New("TextButton", {
		Name = "CancelBtn", Text = "Cancel", AutoButtonColor = false,
		BackgroundColor3 = COLORS.Secondary, BorderSizePixel = 0,
		Font = FONT_MED, TextSize = S(12), TextColor3 = COLORS.SubText,
		Position = UDim2.new(0, S(16), 1, -S(46)), Size = UDim2.fromOffset(S(120), S(32)),
		ZIndex = 102, Parent = card,
	})
	local cancelBtn = card.CancelBtn
	Corner(cancelBtn, S(8))
	cancelBtn.Activated:Connect(function()
		closeAll()
		SafeCall(onCancel)
	end)
	New("TextButton", {
		Name = "OkBtn", Text = "Confirm", AutoButtonColor = false,
		BackgroundColor3 = COLORS.Accent, BorderSizePixel = 0,
		Font = FONT_BOLD, TextSize = S(12), TextColor3 = C(20, 30, 40),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -S(16), 1, -S(46)), Size = UDim2.fromOffset(S(120), S(32)),
		ZIndex = 102, Parent = card,
	})
	local okBtn = card.OkBtn
	Corner(okBtn, S(8))
	okBtn.Activated:Connect(confirm)
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then confirm() end
	end)
	scrim.Activated:Connect(closeAll)
	return closeAll
end


-- [13] PLAYER FEATURES ------------------------------------------------
local Features = {
	Speed   = { On = false, Value = 16 },
	Jump    = { On = false, Value = 50 },
	ESP     = false,
	Boost   = false,
	Noclip  = false,
	InfJump = false,
	AntiAFK = false,
	Spin    = { On = false, Speed = 20 },
}

local function GetChar()
	return LocalPlayer.Character
end

local function GetHumanoid()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

local function ApplySpeed()
	pcall(function()
		local hum = GetHumanoid()
		if hum then
			hum.WalkSpeed = Features.Speed.On and Features.Speed.Value or 16
		end
	end)
end

local function ApplyJump()
	pcall(function()
		local hum = GetHumanoid()
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = Features.Jump.On and Features.Jump.Value or 50
		end
	end)
end

local function SetESP(on)
	pcall(function()
		local char = GetChar()
		if on then
			if char and not char:FindFirstChild("SkyLineESP") then
				ActiveESP = New("Highlight", {
					Name              = "SkyLineESP",
					FillColor         = Theme.Accent,
					OutlineColor      = COLORS.Text,
					FillTransparency  = 0.65,
					OutlineTransparency = 0,
					DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop,
					Parent            = char,
				})
			end
		else
			if ActiveESP then
				pcall(function() ActiveESP:Destroy() end)
				ActiveESP = nil
			end
			if char then
				local old = char:FindFirstChild("SkyLineESP")
				if old then pcall(function() old:Destroy() end) end
			end
		end
	end)
end

local BoostSnap = nil
local function SetBoost(on)
	pcall(function()
		if on then
			BoostSnap = {
				Shadows    = Lighting.GlobalShadows,
				FogEnd     = Lighting.FogEnd,
				Brightness = Lighting.Brightness,
				Effects    = {},
			}
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 100000
			for _, d in ipairs(Lighting:GetDescendants()) do
				if d:IsA("PostEffect") and d.Enabled then
					d.Enabled = false
					Insert(BoostSnap.Effects, d)
				end
			end
		else
			if BoostSnap then
				pcall(function()
					Lighting.GlobalShadows = BoostSnap.Shadows
					Lighting.FogEnd = BoostSnap.FogEnd
					Lighting.Brightness = BoostSnap.Brightness
					for _, d in ipairs(BoostSnap.Effects) do d.Enabled = true end
				end)
				BoostSnap = nil
			end
		end
	end)
end

local CurrentFPS = 60
local PingValue = 0
local FPSFrames = 0
local FPSTime = 0
local PingTimer = 0

Bind(RunService.RenderStepped, function(dt)
	FPSFrames = FPSFrames + 1
	FPSTime = FPSTime + dt
	PingTimer = PingTimer + dt
	if FPSTime >= 0.5 then
		CurrentFPS = floor(FPSFrames / FPSTime + 0.5)
		FPSFrames = 0
		FPSTime = 0
	end
	if PingTimer >= 1 then
		PingTimer = 0
		local ok = pcall(function()
			local item = Stats.Network.ServerStatsItem["Data Ping"]
			if item then PingValue = math.floor(item:GetValue() + 0.5) end
		end)
		if not ok then
			pcall(function() PingValue = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
		end
	end
	if Features.Noclip then
		local ok = pcall(function()
			local char = GetChar()
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end
			end
		end)
		if not ok then Features.Noclip = false end
	end
	if Features.Spin.On then
		pcall(function()
			local char = GetChar()
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Features.Spin.Speed * 3) * dt, 0)
			end
		end)
	end
end)

Bind(UserInputService.JumpRequest, function()
	if not Features.InfJump then return end
	pcall(function()
		local hum = GetHumanoid()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)
end)

Bind(LocalPlayer.Idled, function()
	if not Features.AntiAFK then return end
	pcall(function()
		local VirtualUser = game:GetService("VirtualUser")
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end)

Bind(LocalPlayer.CharacterAdded, function(char)
	task.wait(0.4)
	if Features.Speed.On then ApplySpeed() end
	if Features.Jump.On then ApplyJump() end
	if Features.ESP then SetESP(true) end
end)

-- ═══════════════════ [14] FORWARD DECLARATIONS ═══════════════════
local Library
local SelectTab
local ShowInterface
local HideInterface
local EnsurePanel

local CloseAllDD = function() end
local Hidden = true
local BootedOnce = false
local BusyUI = false


-- [15] NAV BAR (боковая панель) ---------------------------------------
-- Иконки рисуются примитивами (Frame), внешние ассеты не требуются.
local NAV_DEFS = {
	{ Name = "Home" },
	{ Name = "Main" },
	{ Name = "Player" },
	{ Name = "LoadScript" },
	{ Name = "Settings" },
}

-- Рисует векторную иконку из Frame-примитивов внутри holder (26x26 design px).
-- Возвращает canvas и список окрашиваемых частей.
local function BuildIcon(kind, holder)
	local s = S(26)
	local canvas = New("Frame", {
		Name                   = "IconCanvas",
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.fromScale(0.5, 0.5),
		Size                   = UDim2.fromOffset(s, s),
		ZIndex                 = 3,
		Parent                 = holder,
	})
	local parts = {}
	local function P(x, y, w, h, capsule, rot)
		w = math.max(S(w), 2)
		h = math.max(S(h), 2)
		local f = New("Frame", {
			BackgroundColor3       = COLORS.SubText,
			BackgroundTransparency = 0,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 0.5),
			Position               = UDim2.fromOffset(s / 2 + x, s / 2 + y),
			Size                   = UDim2.fromOffset(w, h),
			Rotation               = rot or 0,
			ZIndex                 = 3,
			Parent                 = canvas,
		})
		if capsule then
			Corner(f, math.floor(math.min(w, h) / 2))
		else
			Corner(f, math.max(2, math.floor(S(2))))
		end
		parts[#parts + 1] = f
		return f
	end

	if kind == "Home" then
		P(0, 3, 15, 10)                    -- корпус
		P(-5, -4, 11, 2.5, true, 45)       -- крыша левая
		P(5, -4, 11, 2.5, true, -45)       -- крыша правая
		-- дверной вырез (цвет фона панели, не перекрашивается)
		local door = New("Frame", {
			Name                   = "Door",
			BackgroundColor3       = COLORS.Background,
			BackgroundTransparency = 0,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0.5, 1),
			Position               = UDim2.new(0.5, 0, 1, -S(1)),
			Size                   = UDim2.fromOffset(S(4), S(6)),
			ZIndex                 = 4,
			Parent                 = canvas,
		})
		Corner(door, math.max(2, math.floor(S(2))))
	elseif kind == "Main" then
		P(-6, -6, 9, 9)
		P(6, -6, 9, 9)
		P(-6, 6, 9, 9)
		P(6, 6, 9, 9)
	elseif kind == "Player" then
		P(0, -5, 9, 9, true)               -- голова
		P(0, 7, 15, 7, true)               -- плечи
	elseif kind == "LoadScript" then
		P(-3, -3, 11, 2.5, true, 45)       -- шеврон ">" верх
		P(-3, 3, 11, 2.5, true, -45)       -- шеврон ">" низ
		P(4, 8, 9, 2.5, true, 0)           -- курсор
	elseif kind == "Settings" then
		for i, yy in ipairs({ -7, 0, 7 }) do
			P(0, yy, 17, 2.5, true, 0)
			local knobX = (i == 1 and 5) or (i == 2 and -5) or 4
			P(knobX, yy, 6, 6, true, 0)
		end
	elseif kind == "Exit" then
		P(0, 0, 15, 2.5, true, 45)
		P(0, 0, 15, 2.5, true, -45)
	end

	return canvas, parts
end

local function TintIcon(parts, color)
	for _, f in ipairs(parts) do
		Tween(f, 0.2, { BackgroundColor3 = color })
	end
end

local navW    = S(64)
local navBtnH = S(46)
local navGap  = S(6)
local navPad  = S(12)
local navCount = #NAV_DEFS + 1
local navH = navPad * 2 + navCount * navBtnH + (navCount - 1) * navGap

local NavCanvas = New("CanvasGroup", {
	Name                   = "NavCanvas",
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.fromScale(1, 1),
	Parent                 = WindowLayer,
})
local NavScale = New("UIScale", { Scale = 1, Parent = NavCanvas })

local Nav = New("Frame", {
	Name             = "NavBar",
	BackgroundColor3 = COLORS.Background,
	BorderSizePixel  = 0,
	AnchorPoint      = Vector2.new(0, 0.5),
	Position         = UDim2.new(0, S(18), 0.5, 0),
	Size             = UDim2.fromOffset(navW, navH),
	Parent           = NavCanvas,
})
Corner(Nav, S(16))
StrokeOf(Nav)

local function BtnY(i)
	return navPad + (i - 1) * (navBtnH + navGap)
end

local navHL = New("Frame", {
	Name                   = "Highlight",
	BackgroundColor3       = COLORS.Hover,
	BackgroundTransparency = 0,
	BorderSizePixel        = 0,
	Position               = UDim2.new(0, S(8), 0, BtnY(1)),
	Size                   = UDim2.new(1, -S(16), 0, navBtnH),
	ZIndex                 = 1,
	Parent                 = Nav,
})
Corner(navHL, S(12))

local navButtons = {}
local navIconParts = {}
local activeNav = 1

local function SetIconColor(i, color)
	local plist = navIconParts[i]
	if plist then
		for _, f in ipairs(plist) do
			Tween(f, 0.2, { BackgroundColor3 = color })
		end
	end
end

local function MoveNavHL(i, fast)
	Tween(navHL, fast and 0.14 or 0.26,
		{ Position = UDim2.new(0, S(8), 0, BtnY(i)) }, Enum.EasingStyle.Quart)
end

local function CommitNav(i)
	activeNav = i
	MoveNavHL(i, true)
	for idx in ipairs(navButtons) do
		SetIconColor(idx, idx == i and COLORS.Text or COLORS.SubText)
	end
end

for i, def in ipairs(NAV_DEFS) do
	local b = New("TextButton", {
		Name                   = def.Name .. "Btn",
		BackgroundTransparency = 1,
		Text                   = "",
		Position               = UDim2.new(0, 0, 0, BtnY(i)),
		Size                   = UDim2.new(1, 0, 0, navBtnH),
		ZIndex                 = 2,
		Parent                 = Nav,
	})
	navIconParts[i] = select(2, BuildIcon(def.Name, b))
	local tip = New("TextLabel", {
		Name                   = "Tip",
		BackgroundColor3       = COLORS.Background,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Position               = UDim2.new(0, navW + S(10), 0, BtnY(i) + math.floor((navBtnH - S(26)) / 2)),
		Size                   = UDim2.fromOffset(Measure(def.Name, S(12), FONT_MED) + S(26), S(26)),
		Font                   = FONT_MED,
		Text                   = def.Name,
		TextColor3             = COLORS.Text,
		TextSize               = S(12),
		TextXAlignment         = Enum.TextXAlignment.Center,
		Visible                = false,
		ZIndex                 = 10,
		Parent                 = Nav,
	})
	Corner(tip, S(7))
	StrokeOf(tip)
	Bind(b.MouseEnter, function()
		if Hidden or BusyUI then return end
		tip.Visible = true
		Tween(tip, 0.15, { BackgroundTransparency = 0 })
	end)
	Bind(b.MouseLeave, function()
		Tween(tip, 0.15, { BackgroundTransparency = 1 })
		task.delay(0.16, function() pcall(function() tip.Visible = false end) end)
	end)
	Bind(b.MouseEnter, function()
		if Hidden or BusyUI then return end
		Tween(navHL, 0.22,
			{ Position = UDim2.new(0, S(8), 0, BtnY(i)), BackgroundColor3 = COLORS.HoverStrong },
			Enum.EasingStyle.Quart)
	end)
	Bind(b.Activated, function()
		if BusyUI then return end
		local okNav, errNav = pcall(function()
			CommitNav(i)
			SelectTab(i)
		end)
		if not okNav then
			warn("[SkyLine Hub] nav error:", errNav)
		end
	end)
	navButtons[i] = b
end

do
	local exitIdx = #NAV_DEFS + 1
	local b = New("TextButton", {
		Name                   = "ExitBtn",
		BackgroundTransparency = 1,
		Text                   = "",
		Position               = UDim2.new(0, 0, 0, BtnY(exitIdx)),
		Size                   = UDim2.new(1, 0, 0, navBtnH),
		ZIndex                 = 2,
		Parent                 = Nav,
	})
	local exitParts = select(2, BuildIcon("Exit", b))
	Bind(b.MouseEnter, function()
		if Hidden or BusyUI then return end
		TintIcon(exitParts, COLORS.Danger)
		Tween(navHL, 0.22,
			{ Position = UDim2.new(0, S(8), 0, BtnY(exitIdx)), BackgroundColor3 = COLORS.HoverStrong },
			Enum.EasingStyle.Quart)
	end)
	Bind(b.MouseLeave, function()
		if Hidden or BusyUI then return end
		TintIcon(exitParts, COLORS.SubText)
	end)
	Bind(b.Activated, function()
		if BusyUI then return end
		pcall(function() HideInterface() end)
	end)
	navButtons[exitIdx] = b
end

Bind(Nav.MouseLeave, function()
	if Hidden or BusyUI then return end
	Tween(navHL, 0.25,
		{ Position = UDim2.new(0, S(8), 0, BtnY(activeNav)), BackgroundColor3 = COLORS.Hover },
		Enum.EasingStyle.Quart)
end)

CommitNav(1)


-- [16] CONTENT WINDOW -------------------------------------------------
local vp = Vector2.new(1920, 1080)
pcall(function()
	if Camera then vp = Camera.ViewportSize end
end)

-- окно центрируется по экрану; навигационная панель остаётся слева
local navRight = S(18) + navW + S(12)
local contentW = math.max(S(360),
	math.min(S(640), math.min(vp.X - S(48), vp.X - navRight * 2 - S(28))))
local contentH = math.max(S(320), math.min(S(460), vp.Y - S(56)))

local ContentCanvas = New("CanvasGroup", {
	Name                   = "ContentCanvas",
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.fromScale(1, 1),
	Parent                 = WindowLayer,
})
local ContentScale = New("UIScale", { Scale = 1, Parent = ContentCanvas })

local Shadow = New("Frame", {
	Name             = "Shadow",
	BackgroundColor3 = C(10, 16, 26),
	BackgroundTransparency = 0.55,
	BorderSizePixel  = 0,
	AnchorPoint      = Vector2.new(0.5, 0.5),
	Position         = UDim2.fromScale(0.5, 0.5),
	Size             = UDim2.new(1, S(26), 1, S(26)),
	ZIndex           = 1,
	Parent           = ContentCanvas,
})
Corner(Shadow, S(20))
local Content = New("Frame", {
	Name             = "Window",
	BackgroundColor3 = COLORS.Background,
	BorderSizePixel  = 0,
	AnchorPoint      = Vector2.new(0.5, 0.5),
	Position         = UDim2.fromScale(0.5, 0.5),
	Size             = UDim2.fromOffset(contentW, contentH),
	ZIndex           = 2,
	Parent           = ContentCanvas,
})
Corner(Content, S(14))
StrokeOf(Content)

local TitleIconHolder = New("Frame", {
	Name                   = "TitleIcon",
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	AnchorPoint            = Vector2.new(0, 0.5),
	Position               = UDim2.fromOffset(S(18), S(27)),
	Size                   = UDim2.fromOffset(S(22), S(22)),
	Parent                 = Content,
})

local function SetTitleIcon(kind)
	for _, ch in ipairs(TitleIconHolder:GetChildren()) do
		pcall(function() ch:Destroy() end)
	end
	pcall(function()
		local _, plist = BuildIcon(kind or "Home", TitleIconHolder)
		for _, f in ipairs(plist) do
			f.BackgroundColor3 = COLORS.Accent
		end
	end)
end
SetTitleIcon("Home")

local TitleName = New("TextLabel", {
	Name                   = "TitleName",
	BackgroundTransparency = 1,
	Position               = UDim2.fromOffset(S(50), 0),
	Size                   = UDim2.new(1, -S(150), 0, S(54)),
	Font                   = FONT_BOLD,
	Text                   = "Home",
	TextColor3             = COLORS.Text,
	TextSize               = S(15),
	TextXAlignment         = Enum.TextXAlignment.Left,
	Parent                 = Content,
})
New("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint            = Vector2.new(1, 0.5),
	Position               = UDim2.new(1, -S(16), 0, S(27)),
	Size                   = UDim2.fromOffset(S(110), S(14)),
	Font                   = FONT_MED,
	Text                   = "SKYLINE HUB",
	TextColor3             = COLORS.SubText,
	TextTransparency       = 0.35,
	TextSize               = S(10),
	TextXAlignment         = Enum.TextXAlignment.Right,
	Parent                 = Content,
})
New("Frame", {
	BackgroundColor3       = COLORS.Stroke,
	BackgroundTransparency = 0.55,
	BorderSizePixel        = 0,
	Position               = UDim2.new(0, S(14), 0, S(53)),
	Size                   = UDim2.new(1, -S(28), 0, S(1)),
	Parent                 = Content,
})

local TabHost = New("Frame", {
	Name                   = "TabHost",
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Position               = UDim2.new(0, 0, 0, S(54)),
	Size                   = UDim2.new(1, 0, 1, -S(54)),
	ClipsDescendants       = true,
	Parent                 = Content,
})

-- [17] EXIT TOGGLE ARROW ----------------------------------------------
local ARROW_HIDDEN_X = S(6)
local ARROW_SHOWN_X  = S(18) + navW + S(12)

local ArrowBtn = New("TextButton", {
	Name             = "SkyLineToggle",
	BackgroundColor3 = COLORS.Background,
	BorderSizePixel  = 0,
	AnchorPoint      = Vector2.new(0, 0.5),
	Position         = UDim2.new(0, ARROW_HIDDEN_X, 0.5, 0),
	Size             = UDim2.fromOffset(S(30), S(58)),
	Text             = "",
	AutoButtonColor  = false,
	Visible          = false,
	ZIndex           = 60,
	Parent           = ScreenGui,
})
Corner(ArrowBtn, S(10))
local ArrowStroke = StrokeOf(ArrowBtn)
Bind(ArrowBtn.MouseEnter, function() Tween(ArrowStroke, 0.2, { Color = COLORS.Accent }) end)
Bind(ArrowBtn.MouseLeave, function() Tween(ArrowStroke, 0.25, { Color = COLORS.Stroke }) end)

local ArrowLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Size                   = UDim2.fromScale(1, 1),
	Font                   = FONT_BOLD,
	Text                   = utf8.char(187),
	TextColor3             = COLORS.Text,
	TextSize               = S(20),
	Rotation               = 0,
	ZIndex                 = 61,
	Parent                 = ArrowBtn,
})

Bind(ArrowBtn.Activated, function()
	if BusyUI or not BootedOnce then return end
	if type(ShowInterface) ~= "function" or type(HideInterface) ~= "function" then
		warn("[SkyLine Hub] интерфейс ещё не инициализирован")
		return
	end
	if Hidden then
		ShowInterface()
	else
		HideInterface()
	end
end)


-- [18] TAB PAGES ------------------------------------------------------
local Tabs = {}
local TabByName = {}

local function CreatePage(def, index)
	local page = New("CanvasGroup", {
		Name              = def.Name .. "Page",
		BackgroundTransparency = 1,
		BorderSizePixel   = 0,
		Size              = UDim2.fromScale(1, 1),
		Visible           = false,
		ClipsDescendants  = true,
		Parent            = TabHost,
	})
	local pageScale = New("UIScale", { Scale = 1, Parent = page })
	local host
	if def.Custom then
		host = New("Frame", {
			Name                   = "Host",
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Size                   = UDim2.fromScale(1, 1),
			Parent                 = page,
		})
	else
		host = New("ScrollingFrame", {
			Name                   = "Scroll",
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Size                   = UDim2.fromScale(1, 1),
			CanvasSize             = UDim2.new(),
			AutomaticCanvasSize    = Enum.AutomaticSize.Y,
			ScrollBarThickness     = S(4),
			ScrollBarImageColor3   = COLORS.Accent,
			ScrollBarImageTransparency = 0.35,
			Parent                 = page,
		})
		local layout = ListLayout(host, S(8))
		Pad(host, S(14), S(12), S(14), S(14))
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			host.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + S(26))
		end)
		host.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + S(26))
	end
	local tab = {
		Name = def.Name, Order = index,
		Page = page, PageScale = pageScale, Host = host,
		Blocks = {}, Elements = {}, Panel = nil, LastBlock = nil,
	}
	Tabs[index] = tab
	TabByName[def.Name] = tab
	return tab
end

local PAGE_DEFS = {
	{ Name = "Home",       Custom = true },
	{ Name = "Main" },
	{ Name = "Player" },
	{ Name = "LoadScript" },
	{ Name = "Settings" },
}
for i, def in ipairs(PAGE_DEFS) do
	CreatePage(def, i)
end

local ActiveIdx = 1
local Switching = false

local function UpdateTitle(name)
	Tween(TitleName, 0.12, { TextTransparency = 1 })
	task.delay(0.13, function()
		pcall(function()
			TitleName.Text = name
			SetTitleIcon(name)
		end)
		Tween(TitleName, 0.2, { TextTransparency = 0 })
	end)
end

-- ═══════════════════ [19] SWITCH TAB (directional) ═══════════════════
SelectTab = function(idx)
	if BusyUI or Hidden or Switching then return end
	if not Tabs[idx] or idx == ActiveIdx then return end
	local oldT = Tabs[ActiveIdx]
	local newT = Tabs[idx]
	ActiveIdx = idx
	pcall(CloseAllDD)
	UpdateTitle(newT.Name)
	CommitNav(idx)
	-- новая вкладка выше в панели → старая уходит ВНИЗ, новая появляется СВЕРХУ
	local down = idx < oldT.Order
	local off = S(46)
	local outD = 0.26   -- старая уходит первой
	local inD = 0.34    -- новая въезжает следом

	-- фаза 1: старая вкладка плавно уезжает вверх/вниз и тает
	oldT.Page.Visible = true
	Tween(oldT.PageScale, outD, { Scale = 0.93 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Tween(oldT.Page, outD,
		{ Position = UDim2.fromOffset(0, down and off or -off) },
		Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	Tween(oldT.Page, outD, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if oldT.Panel then pcall(oldT.Panel.Hide) end

	-- фаза 2: новая появляется с противоположной стороны
	task.delay(outD * 0.62, function()
		if ActiveIdx ~= idx then return end
		newT.Page.Visible = true
		newT.Page.Position = UDim2.fromOffset(0, down and -off or off)
		newT.Page.GroupTransparency = 1
		newT.PageScale.Scale = 0.95
		Tween(newT.Page, inD, { Position = UDim2.fromOffset(0, 0) })
		Tween(newT.Page, inD, { GroupTransparency = 0 })
		Tween(newT.PageScale, inD, { Scale = 1 }, Enum.EasingStyle.Quint)
	end)

	if newT.Panel then
		task.delay(outD * 0.9, function()
			if ActiveIdx == idx and newT.Panel then pcall(newT.Panel.Show) end
		end)
	end

	task.delay(0.62, function()
		Switching = false
		if ActiveIdx ~= idx then return end
		oldT.Page.Visible = false
		oldT.Page.Position = UDim2.fromOffset(0, 0)
		oldT.Page.GroupTransparency = 0
		oldT.PageScale.Scale = 1
	end)
end


-- [20] ELEMENT FACTORIES ----------------------------------------------
local ROWH = S(42)

local function HoverFX(row, base, hovered)
	base = base or COLORS.Secondary
	hovered = hovered or COLORS.Hover
	Bind(row.MouseEnter, function()
		Tween(row, 0.15, { BackgroundColor3 = hovered })
	end)
	Bind(row.MouseLeave, function()
		Tween(row, 0.2, { BackgroundColor3 = base })
	end)
end

local function RowLabel(row, text)
	return New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(12), 0),
		Size                   = UDim2.new(1, -S(96), 1, 0),
		Font                   = FONT_MED,
		Text                   = tostring(text or ""),
		TextColor3             = COLORS.Text,
		TextSize               = S(13),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		Parent                 = row,
	})
end

local function AddLabel(host, cfg)
	cfg = cfg or {}
	local row = New("Frame", {
		Name                   = "Label",
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, cfg.Height or S(24)),
		LayoutOrder            = NextOrder(),
		Parent                 = host,
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		Font                   = cfg.Bold and FONT_BOLD or FONT_MED,
		Text                   = tostring(cfg.Text or cfg.Title or ""),
		TextColor3             = cfg.Color or COLORS.SubText,
		TextSize               = cfg.Size and S(cfg.Size) or S(12),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextWrapped            = true,
		RichText               = false,
		Parent                 = row,
	})
	return row
end

local function AddToggle(host, cfg)
	cfg = cfg or {}
	local st = { State = cfg.Default == true }
	local rowH = cfg.Height or ROWH
	local row = New("TextButton", {
		Name             = "Toggle",
		BackgroundColor3 = COLORS.Secondary,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, rowH),
		Text             = "",
		AutoButtonColor  = false,
		LayoutOrder      = NextOrder(),
		Parent           = host,
	})
	Corner(row, S(9))
	HoverFX(row)
	RowLabel(row, cfg.Title or "Toggle")
	local trackW, knobD = S(46), S(18)
	local track = New("Frame", {
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, -S(12), 0.5, 0),
		Size             = UDim2.fromOffset(trackW, S(24)),
		Parent           = row,
	})
	Corner(track, S(12))
	local trkStroke = StrokeOf(track)
	local knob = New("Frame", {
		BackgroundColor3 = COLORS.Text,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0, 0.5),
		Size             = UDim2.fromOffset(knobD, knobD),
		Position         = UDim2.new(0, S(4), 0.5, 0),
		ZIndex           = 2,
		Parent           = track,
	})
	Corner(knob, S(9))
	local ctrl = { Type = "Toggle", Row = row }

	local function Render(instant)
		local targetX = st.State and (trackW - knobD - S(4)) or S(4)
		if instant then
			knob.Position = UDim2.new(0, targetX, 0.5, 0)
			track.BackgroundColor3 = st.State and Theme.Accent or COLORS.Background
			trkStroke.Color = st.State and Theme.Accent or COLORS.Stroke
		else
			Tween(knob, 0.28, { Position = UDim2.new(0, targetX, 0.5, 0) }, Enum.EasingStyle.Back)
			Tween(track, 0.28, { BackgroundColor3 = st.State and Theme.Accent or COLORS.Background })
			Tween(trkStroke, 0.28, { Color = st.State and Theme.Accent or COLORS.Stroke })
		end
	end
	Insert(ToggleRenderers, function() pcall(Render, true) end)

	function ctrl.Get() return st.State end
	function ctrl.Set(v, fire)
		v = v == true
		st.State = v
		Render(false)
		if fire ~= false then
			SafeCall(cfg.Callback, v)
			ScheduleAutoSave()
		end
	end
	ctrl.Destroy = function()
		pcall(function() row:Destroy() end)
	end

	Bind(row.Activated, function()
		ctrl.Set(not st.State)
	end)
	RegisterFlag(cfg.Flag, ctrl)
	Render(true)
	return ctrl
end


local function AddButton(host, cfg)
	cfg = cfg or {}
	local danger = cfg.Danger == true
	local row = New("TextButton", {
		Name             = "Button",
		BackgroundColor3 = danger and COLORS.Danger or COLORS.Secondary,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, cfg.Height or ROWH),
		Text             = "",
		AutoButtonColor  = false,
		LayoutOrder      = NextOrder(),
		Parent           = host,
	})
	Corner(row, S(9))
	HoverFX(row, danger and COLORS.Danger or COLORS.Secondary, danger and COLORS.DangerHover or COLORS.Hover)
	local label = New("TextLabel", {
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		Font                   = FONT_BOLD,
		Text                   = tostring(cfg.Title or cfg.Text or "Button"),
		TextColor3             = cfg.Color or (danger and COLORS.Text or COLORS.Accent),
		TextSize               = S(13),
		Parent                 = row,
	})
	local busy = false
	Bind(row.Activated, function()
		if busy then return end
		busy = true
		Tween(label, 0.12, { TextTransparency = 0.4 })
		task.delay(0.14, function()
			Tween(label, 0.2, { TextTransparency = 0 })
			busy = false
		end)
		SafeCall(cfg.Callback)
	end)
	return { Type = "Button", Row = row }
end



-- [21] SLIDER CORE ----------------------------------------------------
-- Возвращает компоненты полосы слайдера внутри контейнера cont.
local function BuildSliderBar(cont, barY)
	local barW = S(170)
	local barH = S(10)

	local label = New("TextLabel", {
		Name                   = "SliderTitle",
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(12), S(8)),
		Size                   = UDim2.new(1, -barW - S(44), 0, S(16)),
		Font                   = FONT_MED,
		Text                   = "",
		TextColor3             = COLORS.Text,
		TextSize               = S(13),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		Parent                 = cont,
	})

	local bar = New("Frame", {
		Name             = "Bar",
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, -S(14), 0, barY),
		Size             = UDim2.fromOffset(barW, barH),
		Parent           = cont,
	})
	Corner(bar, S(5))
	StrokeOf(bar)

	local fill = New("Frame", {
		Name             = "Fill",
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel  = 0,
		Size             = UDim2.new(0, 0, 1, 0),
		ZIndex           = 2,
		Parent           = bar,
	})
	Corner(fill, S(5))
	local grad = New("UIGradient", { Color = ColorSequence.new(Theme.Start, Theme.Accent), Parent = fill })
	Insert(GradientBinds, grad)

	local chip = New("TextButton", {
		Name             = "Thumb",
		BackgroundColor3 = COLORS.Secondary,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.fromScale(0, 0.5),
		Size             = UDim2.fromOffset(S(46), S(20)),
		Text             = "",
		AutoButtonColor  = false,
		ZIndex           = 4,
		Parent           = bar,
	})
	Corner(chip, S(10))
	StrokeOf(chip, COLORS.Accent, 1, 0.35)
	local chipLbl = New("TextLabel", {
		BackgroundTransparency = 1,
		Size                   = UDim2.fromScale(1, 1),
		Font                   = FONT_BOLD,
		Text                   = "",
		TextColor3             = COLORS.Text,
		TextSize               = S(11),
		ZIndex                 = 5,
		Parent                 = chip,
	})

	return { Label = label, Bar = bar, Fill = fill, Grad = grad, Chip = chip, ChipLbl = chipLbl }
end

-- Логика перетаскивания и значения слайдера.
local function AttachSliderLogic(parts, st, onValue)
	local fill, bar, chip, chipLbl =
		parts.Fill, parts.Bar, parts.Chip, parts.ChipLbl

	local dragging = false

	local function SetValue(v, fire)
		v = tonumber(v)
		if not v then return end
		if st.Inc > 0 then v = st.Min + round((v - st.Min) / st.Inc) * st.Inc end
		v = clamp(v, st.Min, st.Max)
		st.Value = v
		local range = st.Max - st.Min
		local frac = range > 0 and (v - st.Min) / range or 0
		fill.Size = UDim2.new(frac, 0, 1, 0)
		chip.Position = UDim2.new(frac, 0, 0.5, 0)
		local shownTxt = v
		if math.abs(v - floor(v)) > 1e-6 then
			shownTxt = tonumber(string.format("%.2f", v))
		end
		chipLbl.Text = tostring(shownTxt) .. (st.Suffix ~= "" and (" " .. st.Suffix) or "")
		if fire then SafeCall(onValue, v) end
	end

	local function UpdateFromX(xAbs)
		local bw = bar.AbsoluteSize.X
		if bw <= 0 then return end
		local frac = clamp((xAbs - bar.AbsolutePosition.X) / bw, 0, 1)
		SetValue(st.Min + frac * (st.Max - st.Min), true)
	end

	local function BeginDrag()
		dragging = true
		UpdateFromX(UserInputService:GetMouseLocation().X)
	end

	Bind(bar.InputBegan, function(io)
		local t = io.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			BeginDrag()
		end
	end)
	Bind(chip.InputBegan, function(io)
		local t = io.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			BeginDrag()
		end
	end)
	Bind(UserInputService.InputChanged, function(io)
		if not dragging then return end
		local t = io.UserInputType
		if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
			UpdateFromX(UserInputService:GetMouseLocation().X)
		end
	end)
	Bind(UserInputService.InputEnded, function(io)
		local t = io.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return SetValue
end


-- [22] SLIDER FACTORY -------------------------------------------------
local function AddSliderPlain(host, cfg)
	cfg = cfg or {}
	local st = {
		Min    = tonumber(cfg.Min) or 0,
		Max    = tonumber(cfg.Max) or 100,
		Value  = tonumber(cfg.Default) or tonumber(cfg.Min) or 0,
		Suffix = cfg.Suffix and tostring(cfg.Suffix) or "",
		Title  = tostring(cfg.Title or "Slider"),
	}
	st.Inc = tonumber(cfg.Increment)
	if not st.Inc or st.Inc <= 0 then st.Inc = 1 end
	if st.Value < st.Min then st.Value = st.Min end
	if st.Value > st.Max then st.Value = st.Max end

	local cont = New("Frame", {
		Name             = "Slider",
		BackgroundColor3 = COLORS.Secondary,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, S(56)),
		LayoutOrder      = NextOrder(),
		Parent           = host,
	})
	Corner(cont, S(9))
	local parts = BuildSliderBar(cont, math.floor(S(56) / 2))
	parts.Label.Text = st.Title
	parts.Label.Position = UDim2.fromOffset(S(12), 0)
	parts.Label.Size = UDim2.new(1, -(S(170) + S(44)), 1, 0)

	local SetValue = AttachSliderLogic(parts, st, cfg.Callback)
	SetValue(st.Value, false)

	local ctrl = { Type = "Slider", Row = cont }
	function ctrl.Get() return st.Value end
	function ctrl.Set(v, fire) SetValue(v, fire ~= false) end
	ctrl.Destroy = function() pcall(function() cont:Destroy() end) end
	RegisterFlag(cfg.Flag, ctrl)
	return ctrl
end

local function AddMiniToggle(cont, cfg)
	local state = cfg.Default == true
	local row = New("TextButton", {
		Name                   = "MiniToggle",
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Size                   = UDim2.new(1, 0, 0, S(34)),
		Position               = UDim2.new(0, 0, 0, S(58)),
		Parent                 = cont,
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(12), 0),
		Size                   = UDim2.new(1, -S(90), 1, 0),
		Font                   = FONT_MED,
		Text                   = tostring(cfg.Title or "Enable"),
		TextColor3             = COLORS.SubText,
		TextSize               = S(12),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = row,
	})
	local trackW, knobD = S(40), S(14)
	local track = New("Frame", {
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, -S(12), 0.5, 0),
		Size             = UDim2.fromOffset(trackW, S(20)),
		Parent           = row,
	})
	Corner(track, S(10))
	local trkStroke = StrokeOf(track)
	local knob = New("Frame", {
		BackgroundColor3 = COLORS.Text,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0, 0.5),
		Size             = UDim2.fromOffset(knobD, knobD),
		Position         = UDim2.new(0, S(3), 0.5, 0),
		ZIndex           = 2,
		Parent           = track,
	})
	Corner(knob, S(7))
	local ctrl = { Type = "Toggle", Row = row }
	local function Render(instant)
		local tx = state and (trackW - knobD - S(3)) or S(3)
		if instant then
			knob.Position = UDim2.new(0, tx, 0.5, 0)
			track.BackgroundColor3 = state and Theme.Accent or COLORS.Background
			trkStroke.Color = state and Theme.Accent or COLORS.Stroke
		else
			Tween(knob, 0.26, { Position = UDim2.new(0, tx, 0.5, 0) }, Enum.EasingStyle.Back)
			Tween(track, 0.26, { BackgroundColor3 = state and Theme.Accent or COLORS.Background })
			Tween(trkStroke, 0.26, { Color = state and Theme.Accent or COLORS.Stroke })
		end
	end
	Insert(ToggleRenderers, function() pcall(Render, true) end)
	function ctrl.Get() return state end
	function ctrl.Set(v, fire)
		v = v == true
		state = v
		Render(false)
		if fire ~= false then
			SafeCall(cfg.Callback, v)
			ScheduleAutoSave()
		end
	end
	Bind(row.Activated, function() ctrl.Set(not state) end)
	Render(true)
	return ctrl
end

local function AddSliderIntegrated(host, cfg)
	local st = {
		Min    = tonumber(cfg.Min) or 0,
		Max    = tonumber(cfg.Max) or 100,
		Value  = tonumber(cfg.Default) or tonumber(cfg.Min) or 0,
		Suffix = cfg.Suffix and tostring(cfg.Suffix) or "",
		Title  = tostring(cfg.Title or "Slider"),
	}
	st.Inc = tonumber(cfg.Increment)
	if not st.Inc or st.Inc <= 0 then st.Inc = 1 end
	st.Value = clamp(st.Value, st.Min, st.Max)

	local cont = New("Frame", {
		Name             = "SliderCombo",
		BackgroundColor3 = COLORS.Secondary,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, S(98)),
		LayoutOrder      = NextOrder(),
		Parent           = host,
	})
	Corner(cont, S(9))
	local parts = BuildSliderBar(cont, S(32))
	parts.Label.Text = st.Title
	New("Frame", {
		BackgroundColor3       = COLORS.Stroke,
		BackgroundTransparency = 0.55,
		BorderSizePixel        = 0,
		Position               = UDim2.new(0, S(12), 0, S(52)),
		Size                   = UDim2.new(1, -S(24), 0, S(1)),
		Parent                 = cont,
	})
	local mini = AddMiniToggle(cont, {
		Title    = cfg.ToggleTitle or "Enable",
		Default  = cfg.ToggleDefault == true,
		Callback = cfg.OnToggle,
	})
	local SetValue = AttachSliderLogic(parts, st, cfg.Callback)
	SetValue(st.Value, false)

	local ctrl = { Type = "Slider", Row = cont }
	function ctrl.Get() return st.Value end
	function ctrl.Set(v, fire) SetValue(v, fire ~= false) end
	function ctrl.GetEnabled() return mini.Get() end
	function ctrl.SetEnabled(v, fire) mini.Set(v, fire) end
	ctrl.Destroy = function() pcall(function() cont:Destroy() end) end
	RegisterFlag(cfg.Flag, ctrl)
	RegisterFlag(cfg.ToggleFlag or (cfg.Flag and cfg.Flag .. "_Enabled"), mini)
	return ctrl
end

local function AddSlider(host, cfg)
	cfg = cfg or {}
	if cfg.WithToggle then
		return AddSliderIntegrated(host, cfg)
	end
	return AddSliderPlain(host, cfg)
end


-- [23] DROPDOWN (single + multi select) -------------------------------
local OpenDDRef = nil

local function CloseOpenDropdown()
	if OpenDDRef and OpenDDRef.Close then
		pcall(OpenDDRef.Close)
	end
end

Bind(UserInputService.InputBegan, function(input)
	if not OpenDDRef then return end
	local t = input.UserInputType
	if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
	local dd = OpenDDRef
	local m = UserInputService:GetMouseLocation()
	local box = dd.Box
	local bp = box.AbsolutePosition
	local bs = box.AbsoluteSize
	local inBox = m.X >= bp.X and m.X <= bp.X + bs.X and m.Y >= bp.Y - S(40) and m.Y <= bp.Y + bs.Y + S(6)
	local inPop = false
	if dd.Handle then
		local pp = dd.Handle.Popup.AbsolutePosition
		local ps = dd.Handle.Popup.AbsoluteSize
		inPop = m.X >= pp.X and m.X <= pp.X + ps.X and m.Y >= pp.Y and m.Y <= pp.Y + ps.Y
	end
	if inBox then
		if dd.open then dd.Close() else dd.Open() end
		return
	end
	if inPop then return end
	CloseOpenDropdown()
end)

Bind(UserInputService.InputBegan, function(input)
	if input.KeyCode == Enum.KeyCode.Escape then
		CloseOpenDropdown()
	end
end)

-- state: { Multi, IsSel(opt), OnItem(opt), OnAll(), OnClear() }
local function BuildDropdownPopup(box, opts, state)
	opts = opts or {}
	local absPos = box.AbsolutePosition
	local rowsH = #opts * S(30) + S(12)
	local footH = state.Multi and S(34) or 0
	local listH = math.max(S(42), math.min(rowsH + footH, S(210)))
	local popup = New("CanvasGroup", {
		Name                   = "DropdownPopup",
		BackgroundColor3       = COLORS.Secondary,
		BorderSizePixel        = 0,
		Position               = UDim2.new(0, 0, 1, S(6)),
		Size                   = UDim2.fromOffset(math.max(box.AbsoluteSize.X, S(120)), listH),
		GroupTransparency      = 1,
		ZIndex                 = 120,
		Parent                 = box,
	})
	Corner(popup, S(10))
	StrokeOf(popup)
	local popScale = New("UIScale", { Scale = 0.95, Parent = popup })
	Tween(popup, 0.18, { GroupTransparency = 0 })
	Tween(popScale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)

	local listHInner = listH - footH - S(8)
	local scroll = New("ScrollingFrame", {
		Name                       = "List",
		BackgroundTransparency     = 1,
		BorderSizePixel            = 0,
		Position                   = UDim2.fromOffset(S(4), S(4)),
		Size                       = UDim2.new(1, -S(8), 0, listHInner),
		CanvasSize                 = UDim2.new(),
		AutomaticCanvasSize        = Enum.AutomaticSize.Y,
		ScrollBarThickness         = S(3),
		ScrollBarImageColor3       = COLORS.Accent,
		ScrollBarImageTransparency = 0.3,
		Parent                     = popup,
	})
	ListLayout(scroll, S(4))

	local items = {}
	for i, opt in ipairs(opts) do
		local it = New("TextButton", {
			Name                   = "Option",
			BackgroundColor3       = COLORS.Hover,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, S(28)),
			Text                   = "",
			AutoButtonColor        = false,
			LayoutOrder            = i,
			ZIndex                 = 122,
			Parent                 = scroll,
		})
		Corner(it, S(7))

		local lblX = S(10)
		local check = nil
		if state.Multi then
			lblX = S(32)
			check = New("Frame", {
				Name                   = "Check",
				BackgroundColor3       = Theme.Accent,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				AnchorPoint            = Vector2.new(0, 0.5),
				Position               = UDim2.new(0, S(10), 0.5, 0),
				Size                   = UDim2.fromOffset(S(15), S(15)),
				ZIndex                 = 123,
				Parent                 = it,
			})
			Corner(check, S(4))
			StrokeOf(check, COLORS.Stroke, 1, 0.15)
		end

		local lbl = New("TextLabel", {
			BackgroundTransparency = 1,
			Position               = UDim2.fromOffset(lblX, 0),
			Size                   = UDim2.new(1, -(lblX + S(10)), 1, 0),
			Font                   = FONT_MED,
			Text                   = tostring(opt),
			TextColor3             = state.IsSel(opt) and Theme.Accent or COLORS.Text,
			TextSize               = S(12),
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextTruncate           = Enum.TextTruncate.AtEnd,
			ZIndex                 = 123,
			Parent                 = it,
		})

		Bind(it.MouseEnter, function()
			Tween(it, 0.12, { BackgroundTransparency = 0 })
		end)
		Bind(it.MouseLeave, function()
			Tween(it, 0.16, { BackgroundTransparency = 1 })
		end)
		Bind(it.Activated, function()
			SafeCall(state.OnItem, opt)
		end)

		items[i] = { Btn = it, Lbl = lbl, Check = check }
	end

	if state.Multi then
		local foot = New("Frame", {
			Name                   = "Footer",
			BackgroundColor3       = COLORS.Stroke,
			BackgroundTransparency = 0.75,
			BorderSizePixel        = 0,
			Position               = UDim2.new(0, S(6), 1, -footH - S(4)),
			Size                   = UDim2.new(1, -S(12), 0, footH - S(6)),
			ZIndex                 = 124,
			Parent                 = popup,
		})
		Corner(foot, S(7))
		local mkBtn = function(txt, xAnchor, xOff, cb)
			local b = New("TextButton", {
				Name                   = txt,
				BackgroundColor3       = COLORS.Hover,
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				Text                   = txt,
				Font                   = FONT_MED,
				TextColor3             = COLORS.SubText,
				TextSize               = S(11),
				AutoButtonColor        = false,
				AnchorPoint            = Vector2.new(xAnchor, 0.5),
				Position               = UDim2.new(xAnchor, xOff, 0.5, 0),
				Size                   = UDim2.new(0.5, -S(8), 1, -S(4)),
				ZIndex                 = 125,
				Parent                 = foot,
			})
			Corner(b, S(5))
			Bind(b.MouseEnter, function()
				Tween(b, 0.12, { BackgroundTransparency = 0, TextColor3 = COLORS.Text })
			end)
			Bind(b.MouseLeave, function()
				Tween(b, 0.16, { BackgroundTransparency = 1, TextColor3 = COLORS.SubText })
			end)
			Bind(b.Activated, function()
				SafeCall(cb)
			end)
			return b
		end
		mkBtn("Select All", 0, S(4), state.OnAll)
		mkBtn("Clear", 1, -S(4), state.OnClear)
	end

	return { Popup = popup, Items = items, Scroll = scroll }
end

local function RestyleItems(handle, isSelFn)
	if not handle then return end
	for _, item in ipairs(handle.Items) do
		local isSel = isSelFn(tostring(item.Lbl.Text))
		item.Lbl.TextColor3 = isSel and Theme.Accent or COLORS.Text
		if item.Check then
			Tween(item.Check, 0.15, {
				BackgroundTransparency = isSel and 0 or 1,
			})
		end
	end
end

local DDRegistry = {}

local function AddDropdown(host, cfg)
	cfg = cfg or {}
	local isMulti = cfg.Multi == true

	local opts = {}
	if type(cfg.Options) == "table" then
		for _, o in ipairs(cfg.Options) do
			opts[#opts + 1] = tostring(o)
		end
	end

	local sel = nil          -- single: строка
	local selSet = {}        -- multi: [value]=true
	local selCount = 0

	if isMulti then
		local init = cfg.Default
		if type(init) ~= "table" then init = {} end
		for _, o in ipairs(init) do
			local v = tostring(o)
			for _, existing in ipairs(opts) do
				if existing == v and not selSet[v] then
					selSet[v] = true
					selCount = selCount + 1
					break
				end
			end
		end
	else
		sel = cfg.Default and tostring(cfg.Default) or nil
		local okDef = false
		for _, o in ipairs(opts) do
			if o == sel then okDef = true break end
		end
		if not okDef then sel = opts[1] end
	end

	local row = New("TextButton", {
		Name             = "Dropdown",
		BackgroundColor3 = COLORS.Secondary,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, ROWH),
		Text             = "",
		AutoButtonColor  = false,
		LayoutOrder      = NextOrder(),
		Parent           = host,
	})
	Corner(row, S(9))
	HoverFX(row)
	RowLabel(row, cfg.Title or "Dropdown")

	local function MeasureMaxW()
		local w = S(96)
		for _, o in ipairs(opts) do
			w = math.max(w, Measure(o, S(12), FONT_MED) + (isMulti and S(56) or S(36)))
		end
		return w
	end

	local boxW = clamp(MeasureMaxW(), S(100), S(260))

	local box = New("Frame", {
		Name             = "Box",
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, -S(12), 0.5, 0),
		Size             = UDim2.fromOffset(boxW, S(30)),
		Parent           = row,
	})
	Corner(box, S(8))
	local ddStroke = StrokeOf(box)

	local selLbl = New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(10), 0),
		Size                   = UDim2.new(1, -S(42), 1, 0),
		Font                   = FONT_MED,
		Text                   = "...",
		TextColor3             = COLORS.Text,
		TextSize               = S(12),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		Parent                 = box,
	})
	local chev = New("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -S(10), 0.5, 0),
		Size                   = UDim2.fromOffset(S(14), S(14)),
		Font                   = FONT_ICON,
		Text                   = utf8.char(9660),
		TextColor3             = COLORS.SubText,
		TextSize               = S(8),
		Rotation               = 0,
		Parent                 = box,
	})

	local dd = { Box = box, Handle = nil, ScrollConn = nil, open = false }

	local function UpdateLabel()
		if isMulti then
			if selCount == 0 then
				selLbl.Text = "None"
				selLbl.TextColor3 = COLORS.SubText
			else
				local names = {}
				for _, o in ipairs(opts) do
					if selSet[o] then names[#names + 1] = o end
				end
				local first = names[1] or ""
				if #names > 2 then
					selLbl.Text = first .. ", " .. names[2] .. " +" .. (#names - 2)
				elseif #names == 2 then
					selLbl.Text = names[1] .. ", " .. names[2]
				else
					selLbl.Text = first
				end
				selLbl.TextColor3 = COLORS.Text
			end
		else
			selLbl.Text = sel or "..."
			selLbl.TextColor3 = sel and COLORS.Text or COLORS.SubText
		end
	end

	function dd.Close()
		if not dd.open then return end
		dd.open = false
		if OpenDDRef == dd then OpenDDRef = nil end
		if dd.ScrollConn then
			pcall(function() dd.ScrollConn:Disconnect() end)
			dd.ScrollConn = nil
		end
		box.ZIndex = 1
		Tween(chev, 0.25, { Rotation = 0 }, Enum.EasingStyle.Quart)
		Tween(ddStroke, 0.25, { Color = COLORS.Stroke })
		if dd.Handle then
			local h = dd.Handle
			dd.Handle = nil
			Tween(h.Popup, 0.15, { GroupTransparency = 1 })
			task.delay(0.16, function() pcall(function() h.Popup:Destroy() end) end)
		end
	end

	local function FireChange()
		if isMulti then
			local out = {}
			for _, o in ipairs(opts) do
				if selSet[o] then out[#out + 1] = o end
			end
			SafeCall(cfg.Callback, out)
		else
			SafeCall(cfg.Callback, sel)
		end
		ScheduleAutoSave()
	end

	function dd.Open()
		if dd.open then return end
		CloseOpenDropdown()

		if cfg.RefreshOptions then
			local okR, newList = pcall(cfg.RefreshOptions)
			if okR and type(newList) == "table" then
				opts = {}
				for _, x in ipairs(newList) do opts[#opts + 1] = tostring(x) end
				if isMulti then
					for v in pairs(selSet) do
						local alive = false
						for _, o in ipairs(opts) do if o == v then alive = true break end end
						if not alive then selSet[v] = nil selCount = selCount - 1 end
					end
				else
					local hasSel = false
					for _, o in ipairs(opts) do if o == sel then hasSel = true break end end
					if not hasSel then sel = opts[1] end
				end
			end
		end
		if #opts == 0 then return end

		dd.open = true
		OpenDDRef = dd

		dd.Handle = BuildDropdownPopup(box, opts, {
			Multi = isMulti,
			IsSel = function(o)
				if isMulti then return selSet[o] == true end
				return o == sel
			end,
			OnItem = function(o)
				o = tostring(o)
				if isMulti then
					if selSet[o] then
						selSet[o] = nil
						selCount = selCount - 1
					else
						selSet[o] = true
						selCount = selCount + 1
					end
					UpdateLabel()
					RestyleItems(dd.Handle, function(v) return selSet[v] == true end)
					FireChange()
				else
					sel = o
					UpdateLabel()
					RestyleItems(dd.Handle, function(v) return v == sel end)
					pcall(dd.Close)
					FireChange()
				end
			end,
			OnAll = function()
				selSet = {}
				selCount = 0
				for _, o in ipairs(opts) do
					selSet[o] = true
					selCount = selCount + 1
				end
				UpdateLabel()
				RestyleItems(dd.Handle, function(v) return selSet[v] == true end)
				FireChange()
			end,
			OnClear = function()
				selSet = {}
				selCount = 0
				UpdateLabel()
				RestyleItems(dd.Handle, function() return false end)
				FireChange()
			end,
		})

		RestyleItems(dd.Handle, function(o)
		dd.ScrollConn = Bind(RunService.Heartbeat, function()
			if dd.open and dd.Handle and dd.Handle.Popup.Parent then
				local abs = box.AbsolutePosition
				local cAbs = Content.AbsolutePosition
				local cSize = Content.AbsoluteSize
				if abs.Y < cAbs.Y - box.AbsoluteSize.Y or abs.Y > cAbs.Y + cSize.Y then
					pcall(dd.Close)
					return
				end
				local pop = dd.Handle.Popup
				local popW, popH = pop.AbsoluteSize.X, pop.AbsoluteSize.Y
				local x = math.min(abs.X, cAbs.X + cSize.X - popW - S(10))
				local y = abs.Y + box.AbsoluteSize.Y + S(6)
				if y + popH > cAbs.Y + cSize.Y - S(10) then
					local above = abs.Y - popH - S(6)
					y = (above > cAbs.Y + S(10)) and above or math.max(cAbs.Y + S(10), math.min(y, cAbs.Y + cSize.Y - popH - S(10)))
				end
				-- follow отключён: попап живёт внутри строки и двигается сам
			end
		end)
			if isMulti then return selSet[o] == true end
			return o == sel
		end)

		pcall(function()
			local ps = row:FindFirstAncestorOfClass("ScrollingFrame")
			if ps then
				local relY = box.AbsolutePosition.Y - ps.AbsolutePosition.Y
				local spaceBelow = ps.AbsoluteWindowSize.Y - relY - box.AbsoluteSize.Y
				if dd.Handle.Popup.AbsoluteSize.Y > spaceBelow - S(10) then
					dd.Handle.Popup.Position = UDim2.new(0, 0, 0, -dd.Handle.Popup.AbsoluteSize.Y / SCALE - S(6))
				end
			end
		end)
		box.ZIndex = 80
		Tween(chev, 0.25, { Rotation = 180 }, Enum.EasingStyle.Quart)
		Tween(ddStroke, 0.25, { Color = Theme.Accent })
		UpdateLabel()
	end

	Bind(row.Activated, function()
		if not dd.open then dd.Open() end
	end)

	local regEntry = { Close = dd.Close }
	Insert(DDRegistry, regEntry)
	CloseAllDD = function()
		for _, e in ipairs(DDRegistry) do pcall(e.Close) end
	end

	local ctrl = { Type = "Dropdown", Multi = isMulti, Row = row }
	ctrl.Get = function()
		if isMulti then
			local out = {}
			for _, o in ipairs(opts) do
				if selSet[o] then out[#out + 1] = o end
			end
			return out
		end
		return sel
	end
	ctrl.Set = function(v, fire)
		if isMulti then
			selSet = {}
			selCount = 0
			if type(v) == "table" then
				for _, item in ipairs(v) do
					local target = tostring(item)
					for _, o in ipairs(opts) do
						if o == target then
							selSet[target] = true
							selCount = selCount + 1
							break
						end
					end
				end
			end
			UpdateLabel()
			RestyleItems(dd.Handle, function(x) return selSet[x] == true end)
			if fire ~= false then FireChange() end
		else
			local target = tostring(v)
			for _, o in ipairs(opts) do
				if o == target then
					sel = target
					UpdateLabel()
					RestyleItems(dd.Handle, function(x) return x == sel end)
					if fire ~= false then FireChange() end
					return
				end
			end
		end
	end
	ctrl.Refresh = function(list)
		if type(list) ~= "table" then return end
		opts = {}
		for _, x in ipairs(list) do opts[#opts + 1] = tostring(x) end
	end
	ctrl.Destroy = function()
		pcall(dd.Close)
		for i = #DDRegistry, 1, -1 do
			if DDRegistry[i] == regEntry then table.remove(DDRegistry, i) break end
		end
		pcall(function() row:Destroy() end)
	end
	RegisterFlag(cfg.Flag, ctrl)
	UpdateLabel()
	return ctrl
end
-- [24] SCRIPT BUTTON (стрелка вправо, не раскрывается) ----------------
local function AddScriptRow(host, cfg)
	cfg = cfg or {}
	local row = New("TextButton", {
		Name             = "ScriptBtn",
		BackgroundColor3 = COLORS.Secondary,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, cfg.Height or ROWH),
		Text             = "",
		AutoButtonColor  = false,
		LayoutOrder      = NextOrder(),
		Parent           = host,
	})
	Corner(row, S(9))
	HoverFX(row)
	RowLabel(row, cfg.Title or cfg.Name or "Script")
	local chev = New("TextLabel", {
		Name                   = "Chevron",
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -S(14), 0.5, 0),
		Size                   = UDim2.fromOffset(S(14), S(14)),
		Font                   = FONT_ICON,
		Text                   = utf8.char(8250),
		TextColor3             = COLORS.Accent,
		TextSize               = S(15),
		Rotation               = 90,
		Parent                 = row,
	})
	local busy = false
	Bind(row.Activated, function()
		if busy then return end
		busy = true
		Tween(chev, 0.14, { Position = UDim2.new(1, -S(9), 0.5, 0) })
		task.delay(0.18, function()
			Tween(chev, 0.2, { Position = UDim2.new(1, -S(14), 0.5, 0) })
			busy = false
		end)
		Notify("Loader", "Запуск: " .. tostring(cfg.Title or cfg.Name or "script"))
		Spawn(function()
			SafeCall(cfg.Callback)
		end)
	end)
	return { Type = "Script", Row = row }
end

-- [25] BLOCK (сворачиваемая секция) -----------------------------------
local function CreateBlock(tab, name)
	name = tostring(name or "Block")
	local headerH = ROWH

	local root = New("Frame", {
		Name                   = "Block",
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, headerH),
		LayoutOrder            = NextOrder(),
		Parent                 = tab.Host,
	})
	local header = New("TextButton", {
		Name             = "Header",
		BackgroundColor3 = COLORS.Secondary,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, headerH),
		Text             = "",
		AutoButtonColor  = false,
		ZIndex           = 2,
		Parent           = root,
	})
	Corner(header, S(9))
	HoverFX(header)
	RowLabel(header, name)
	local chev = New("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -S(12), 0.5, 0),
		Size                   = UDim2.fromOffset(S(14), S(14)),
		Font                   = FONT_ICON,
		Text                   = utf8.char(9660),
		TextColor3             = COLORS.SubText,
		TextSize               = S(8),
		Rotation               = 0,
		ZIndex                 = 3,
		Parent                 = header,
	})
	local body = New("CanvasGroup", {
		Name             = "Body",
		GroupTransparency      = 0,
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel  = 0,
		Position         = UDim2.new(0, 0, 0, headerH + S(6)),
		Size             = UDim2.new(1, 0, 0, 0),
		Visible          = false,
		ClipsDescendants = true,
		Parent           = root,
	})
	Corner(body, S(9))
	ListLayout(body, S(8))
	Pad(body, S(10), S(10), S(10), S(12))

	local block = { Name = name, Open = false, Heights = {}, Frame = root }

	local function ContentH()
		local sum = S(22)
		for i, h in ipairs(block.Heights) do
			sum = sum + h + (i > 1 and S(8) or 0)
		end
		return sum
	end

	function block.Apply(open)
		open = open == true
		block.Open = open
		Tween(chev, 0.3, { Rotation = open and 180 or 0 }, Enum.EasingStyle.Quart)
		if open then
			body.Visible = true
			body.GroupTransparency = 1
			Tween(root, 0.32, { Size = UDim2.new(1, 0, 0, headerH + S(6) + ContentH()) })
			Tween(body, 0.28, { GroupTransparency = 0 })
		else
			Tween(root, 0.26, { Size = UDim2.new(1, 0, 0, headerH) },
				Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			Tween(body, 0.22, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.24, function()
				if not block.Open then body.Visible = false end
			end)
		end
		if tab.Panel then pcall(tab.Panel.Sync) end
	end

	function block.Toggle(o)
		block.Apply(o == nil and (not block.Open) or o)
	end

	local function Wrap(factory, heightOf)
		return function(cfg)
			cfg = cfg or {}
			local ctrl = factory(body, cfg)
			Insert(block.Heights, heightOf(cfg))
			if block.Open then
				pcall(function()
					root.Size = UDim2.new(1, 0, 0, headerH + S(6) + ContentH())
				end)
			end
			return ctrl
		end
	end

	block.AddToggle   = Wrap(AddToggle,   function(c) return c.Height or ROWH end)
	block.AddButton   = Wrap(AddButton,   function(c) return c.Height or ROWH end)
	block.AddDropdown = Wrap(AddDropdown, function(c) return ROWH end)
	block.AddSlider   = Wrap(AddSlider,   function(c) return c.WithToggle and S(98) or S(56) end)
	block.AddLabel    = Wrap(AddLabel,    function(c) return c.Height or S(24) end)
	block.Set = block.Apply
	block.Get = function() return block.Open end

	Bind(header.Activated, function()
		block.Toggle()
	end)

	Insert(tab.Blocks, block)
	if EnsurePanel then EnsurePanel(tab) end
	return block
end


-- [26] RIGHT BLOCK NAV PANEL ------------------------------------------
EnsurePanel = function(tab)
	if not tab then return end
	if #tab.Blocks < 2 then return end
	if tab.Panel and tab.Panel.Canvas and tab.Panel.Canvas.Parent then
		return
	end

	local blocks = tab.Blocks
	local n = #blocks

	local itemW = S(130)
	for _, b in ipairs(blocks) do
		itemW = math.max(itemW, Measure(b.Name, S(12), FONT_MED) + S(44))
	end
	itemW = clamp(itemW, S(130), S(230))

	local itemH = S(38)
	local gap   = S(5)
	local padV  = S(10)
	local panelH = n * itemH + (n - 1) * gap + padV * 2

	local vph = Vector2.new(1920, 1080)
	pcall(function()
		if Camera then vph = Camera.ViewportSize end
	end)
	local winTopY = math.floor((vph.Y - contentH) / 2)
	local panelX = math.floor(vph.X / 2 + contentW / 2 + S(12))

	local canvas = New("CanvasGroup", {
		Name                   = "BlockNav",
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.fromScale(1, 1),
		GroupTransparency      = 1,
		ZIndex                 = 40,
		Parent                 = WindowLayer,
	})

	local panel = New("Frame", {
		Name             = "BlockPanel",
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel  = 0,
		Position         = UDim2.fromOffset(panelX, winTopY),
		Size             = UDim2.fromOffset(itemW, panelH),
		Parent           = canvas,
	})
	Corner(panel, S(14))
	StrokeOf(panel)

	local hl = New("Frame", {
		Name                   = "HL",
		BackgroundColor3       = COLORS.Secondary,
		BackgroundTransparency = 0,
		BorderSizePixel        = 0,
		Position               = UDim2.fromOffset(S(8), padV),
		Size                   = UDim2.new(1, -S(16), 0, itemH),
		ZIndex                 = 1,
		Parent                 = panel,
	})
	Corner(hl, S(10))

	local committed = 1
	local function MoveHL(i, fast)
		Tween(hl, fast and 0.14 or 0.24,
			{ Position = UDim2.fromOffset(S(8), padV + (i - 1) * (itemH + gap)) },
			Enum.EasingStyle.Quart)
	end

	local items = {}
	for i, b in ipairs(blocks) do
		local it = New("TextButton", {
			Name                   = "NavItem",
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Position               = UDim2.fromOffset(S(8), padV + (i - 1) * (itemH + gap)),
			Size                   = UDim2.new(1, -S(16), 0, itemH),
			ZIndex                 = 2,
			Parent                 = panel,
		})
		local dot = New("Frame", {
			Name                   = "Dot",
			BackgroundColor3       = Theme.Accent,
			BackgroundTransparency = 0,
			BorderSizePixel        = 0,
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.new(0, S(9), 0.5, 0),
			Size                   = UDim2.fromOffset(S(6), S(6)),
			Visible                = false,
			ZIndex                 = 3,
			Parent                 = it,
		})
		Corner(dot, S(3))
		local lbl = New("TextLabel", {
			BackgroundTransparency = 1,
			Position               = UDim2.fromOffset(S(22), 0),
			Size                   = UDim2.new(1, -S(30), 1, 0),
			Font                   = FONT_MED,
			Text                   = b.Name,
			TextColor3             = COLORS.SubText,
			TextSize               = S(12),
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextTruncate           = Enum.TextTruncate.AtEnd,
			ZIndex                 = 3,
			Parent                 = it,
		})
		Bind(it.MouseEnter, function()
			if Hidden or BusyUI then return end
			Tween(hl, 0.2,
				{ Position = UDim2.fromOffset(S(8), padV + (i - 1) * (itemH + gap)), BackgroundColor3 = COLORS.HoverStrong },
				Enum.EasingStyle.Quart)
		end)
		Bind(it.Activated, function()
			if Hidden or BusyUI then return end
			local wasOpen = b.Open
			b.Set(not wasOpen)
			committed = i
			MoveHL(i, true)
			if not wasOpen then
			pcall(function()
				local scroll = tab.Scroll
				local target = b.Frame.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y - S(16)
				Tween(scroll, 0.35, { CanvasPosition = Vector2.new(0, math.max(target, 0)) }, Enum.EasingStyle.Quint)
			end)
			end
		end)
		items[i] = { Btn = it, Dot = dot, Lbl = lbl }
	end

	Bind(panel.MouseLeave, function()
		if Hidden or BusyUI then return end
		MoveHL(committed, false)
		Tween(hl, 0.25, { BackgroundColor3 = COLORS.Secondary })
	end)

	local function Sync()
		local lastOpen = nil
		for i, b in ipairs(blocks) do
			local isOpen = b.Open == true
		items[i].Dot.Visible = isOpen
		items[i].Lbl.TextColor3 = isOpen and COLORS.Text or COLORS.SubText
			if isOpen then lastOpen = i end
		end
		if lastOpen then
			tab.LastBlock = lastOpen
			committed = lastOpen
		elseif not tab.LastBlock or not blocks[tab.LastBlock] then
			committed = 1
		else
			committed = tab.LastBlock
		end
		MoveHL(committed, true)
		Tween(hl, 0.25, { BackgroundColor3 = COLORS.Secondary })
	end

	tab.Panel = {
		Canvas = canvas,
		Sync   = Sync,
		Show   = function() Tween(canvas, 0.3, { GroupTransparency = 0 }) end,
		Hide   = function() Tween(canvas, 0.25, { GroupTransparency = 1 }) end,
	}
	Sync()

	if ActiveIdx == tab.Order and not Hidden then
		task.delay(0.35, function() pcall(function() tab.Panel.Show() end) end)
	end
end


-- [27] TAB API --------------------------------------------------------
local TabAPI = {}
TabAPI.__index = TabAPI

function TabAPI:AddToggle(cfg)   return AddToggle(self.Host, cfg) end
function TabAPI:AddButton(cfg)   return AddButton(self.Host, cfg) end
function TabAPI:AddLabel(cfg)    return AddLabel(self.Host, cfg) end
function TabAPI:AddSlider(cfg)   return AddSlider(self.Host, cfg) end
function TabAPI:AddDropdown(cfg) return AddDropdown(self.Host, cfg) end
function TabAPI:AddBlock(name)   return CreateBlock(self, name) end
function TabAPI:AddScriptRow(cfg) return AddScriptRow(self.Host, cfg) end

for _, t in ipairs(Tabs) do
	setmetatable(t, TabAPI)
end

-- [28] HOME TAB -------------------------------------------------------
do
	local okSecH, errSecH = pcall(function()

	local home = Tabs[1]
	local host = home.Host

	local uid = tostring(LocalPlayer.UserId)

	New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(20), S(12)),
		Size                   = UDim2.new(1, -S(40), 0, S(20)),
		Font                   = FONT_BOLD,
		Text                   = "Welcome back",
		TextColor3             = COLORS.Text,
		TextSize               = S(16),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = host,
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(20), S(34)),
		Size                   = UDim2.new(1, -S(40), 0, S(14)),
		Font                   = FONT,
		Text                   = "@" .. LocalPlayer.Name .. "  •  SkyLine Hub v1.0",
		TextColor3             = COLORS.SubText,
		TextSize               = S(11),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = host,
	})

	local card = New("Frame", {
		Name             = "ProfileCard",
		BackgroundColor3 = COLORS.Secondary,
		BorderSizePixel  = 0,
		Position         = UDim2.fromOffset(S(20), S(60)),
		Size             = UDim2.new(1, -S(40), 0, S(122)),
		Parent           = host,
	})
	Corner(card, S(14))
	StrokeOf(card)

	local avatarHolder = New("Frame", {
		Name             = "AvatarHolder",
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = UDim2.new(0, S(16), 0.5, 0),
		Size             = UDim2.fromOffset(S(78), S(78)),
		Parent           = card,
	})
	Corner(avatarHolder, S(39))
	StrokeOf(avatarHolder, COLORS.Accent, S(1.5), 0.4)

	local initials = New("TextLabel", {
		BackgroundTransparency = 1,
		Size                   = UDim2.fromScale(1, 1),
		Font                   = FONT_BOLD,
		Text                   = string.sub(LocalPlayer.Name, 1, 2),
		TextColor3             = COLORS.SubText,
		TextSize               = S(18),
		Parent                 = avatarHolder,
	})

	local AvatarImg = New("ImageLabel", {
		Name                   = "Avatar",
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.fromScale(0.5, 0.5),
		Size                   = UDim2.fromOffset(S(70), S(70)),
		Image                  = "",
		Parent                 = avatarHolder,
	})
	Corner(AvatarImg, S(35))
	AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
	Spawn(function()
		pcall(function()
			local content = Players:GetUserThumbnailAsync(
				LocalPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size420x420)
			if content and AvatarImg.Parent then
				AvatarImg.Image = content
			end
		end)
	end)

	New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(108), S(10)),
		Size                   = UDim2.new(1, -S(124), 0, S(16)),
		Font                   = FONT_BOLD,
		Text                   = LocalPlayer.DisplayName,
		TextColor3             = COLORS.Text,
		TextSize               = S(14),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		Parent                 = card,
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(108), S(27)),
		Size                   = UDim2.new(1, -S(124), 0, S(13)),
		Font                   = FONT,
		Text                   = "@" .. LocalPlayer.Name,
		TextColor3             = COLORS.SubText,
		TextSize               = S(11),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		Parent                 = card,
	})

	local function InfoRow(y, labelText)
		local r = New("TextButton", {
			Name                   = "Info_" .. labelText,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			Position               = UDim2.fromOffset(S(108), y),
			Size                   = UDim2.new(1, -S(126), 0, S(19)),
			Parent                 = card,
		})
		return r
	end

	local idRow = InfoRow(S(46), "ID")
	New("TextLabel", {
		BackgroundTransparency = 1,
		Size                   = UDim2.fromScale(0.5, 1),
		Font                   = FONT_MED,
		Text                   = "Player ID",
		TextColor3             = COLORS.SubText,
		TextSize               = S(11),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = idRow,
	})
	local idVal = New("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -S(6), 0.5, 0),
		Size                   = UDim2.fromScale(0.5, 1),
		Font                   = FONT_BOLD,
		Text                   = uid .. "  [copy]",
		TextColor3             = COLORS.Accent,
		TextSize               = S(11),
		TextXAlignment         = Enum.TextXAlignment.Right,
		Parent                 = idRow,
	})
	Bind(idRow.Activated, function()
		if Copy(uid) then
			Notify("Success", "Successfully copied")
		else
			Notify("Clipboard", "setclipboard недоступен")
		end
	end)


	local pingRow = InfoRow(S(67), "Ping")
	New("Frame", {
		Name             = "Dot",
		BackgroundColor3 = C(120, 220, 140),
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = UDim2.new(0, S(2), 0.5, 0),
		Size             = UDim2.fromOffset(S(6), S(6)),
		Parent           = pingRow,
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(14), 0),
		Size                   = UDim2.fromScale(0.6, 1),
		Font                   = FONT_MED,
		Text                   = "Ping",
		TextColor3             = COLORS.SubText,
		TextSize               = S(11),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = pingRow,
	})
	local pingVal = New("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -S(6), 0.5, 0),
		Size                   = UDim2.fromScale(0.4, 1),
		Font                   = FONT_BOLD,
		Text                   = "-- ms",
		TextColor3             = COLORS.Text,
		TextSize               = S(11),
		TextXAlignment         = Enum.TextXAlignment.Right,
		Parent                 = pingRow,
	})

	local fpsRow = InfoRow(S(88), "FPS")
	New("Frame", {
		Name             = "Dot",
		BackgroundColor3 = COLORS.Accent,
		BorderSizePixel  = 0,
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = UDim2.new(0, S(2), 0.5, 0),
		Size             = UDim2.fromOffset(S(6), S(6)),
		Parent           = fpsRow,
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(S(14), 0),
		Size                   = UDim2.fromScale(0.6, 1),
		Font                   = FONT_MED,
		Text                   = "FPS",
		TextColor3             = COLORS.SubText,
		TextSize               = S(11),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = fpsRow,
	})
	local fpsVal = New("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -S(6), 0.5, 0),
		Size                   = UDim2.fromScale(0.4, 1),
		Font                   = FONT_BOLD,
		Text                   = "--",
		TextColor3             = COLORS.Text,
		TextSize               = S(11),
		TextXAlignment         = Enum.TextXAlignment.Right,
		Parent                 = fpsRow,
	})

	local updT = 0
	Bind(RunService.Heartbeat, function(dt)
		updT = updT + dt
		if updT < 0.25 then return end
		updT = 0
		pcall(function()
			if pingVal.Parent then
				pingVal.Text = tostring(PingValue) .. " ms"
			end
			if fpsVal.Parent then
				fpsVal.Text = tostring(CurrentFPS)
				fpsVal.TextColor3 = CurrentFPS < 30 and COLORS.Danger or COLORS.Text
			end
		end)
	end)
	end)
	if not okSecH then warn("[SkyLine Hub] Home tab error:", errSecH) end
end


-- [29] MAIN TAB -------------------------------------------------------
do
	local okSecM, errSecM = pcall(function()
	local main = Tabs[2]
	main:AddLabel({ Text = "Основная панель функций SkyLine Hub.", Height = S(20) })

	main:AddToggle({
		Title    = "Example Toggle",
		Default  = false,
		Flag     = "ExToggle",
		Callback = function(v)
			Notify("Main", "Toggle: " .. tostring(v))
		end,
	})

	main:AddSlider({
		Title     = "Example Slider",
		Min       = 0,
		Max       = 100,
		Default   = 50,
		Suffix    = "%",
		Increment = 1,
		Flag      = "ExSlider",
		Callback  = function(v)
			print("[SkyLine Hub] slider:", v)
		end,
	})

	main:AddSlider({
		Title        = "Combined Slider + Toggle",
		Min          = 16,
		Max          = 500,
		Default      = 16,
		WithToggle   = true,
		ToggleTitle  = "Enable",
		Flag         = "ExCombo",
		OnToggle     = function(on)
			Notify("Main", "Enable: " .. tostring(on))
		end,
		Callback     = function(v)
			print("[SkyLine Hub] combo:", v)
		end,
	})

	main:AddDropdown({
		Title    = "Example Dropdown",
		Options  = { "Option A", "Option B", "Option C" },
		Default  = "Option A",
		Flag     = "ExDropdown",
		Callback = function(sel)
			Notify("Main", "Выбрано: " .. tostring(sel))
		end,
	})

		main:AddDropdown({
		Title    = "Multi Select",
		Options  = { "Apple", "Banana", "Cherry", "Dragon Fruit" },
		Default  = { "Apple" },
		Multi    = true,
		Flag     = "ExMulti",
		Callback = function(list)
			Notify("Multi Select", "Выбрано: " .. tostring(#list))
		end,
	})

main:AddButton({
		Title    = "Test Notification",
		Callback = function()
			Notify("SkyLine Hub", "Hello from the Main tab!")
		end,
	})

	local visuals = main:AddBlock("Visuals")
	visuals:AddLabel({ Text = "Пример блока — содержимое сворачивается." })
	visuals:AddToggle({
		Title    = "Custom Crosshair",
		Flag     = "Crosshair",
		Callback = function(v)
			print("[SkyLine Hub] crosshair:", v)
		end,
	})
	visuals:AddSlider({
		Title     = "Crosshair Size",
		Min       = 4,
		Max       = 24,
		Default   = 10,
		Flag      = "CrosshairSize",
		Callback  = function() end,
	})
	visuals:AddDropdown({
		Title    = "Style",
		Options  = { "Dot", "Cross", "Circle" },
		Flag     = "CrosshairStyle",
		Callback = function() end,
	})

	local utility = main:AddBlock("Utility")
	utility:AddButton({
		Title    = "Ping Check",
		Callback = function()
			Notify("Utility", "Ping: " .. tostring(PingValue) .. " ms")
		end,
	})
	utility:AddToggle({
		Title    = "Anti Lag (demo)",
		Flag     = "AntiLagDemo",
		Callback = function() end,
	})
	utility:AddSlider({
		Title     = "Render Distance",
		Min       = 10,
		Max       = 500,
		Default   = 100,
		Suffix    = "m",
		Flag      = "RenderDistance",
		Callback  = function() end,
	})
	end)
	if not okSecM then warn("[SkyLine Hub] Main tab error:", errSecM) end
end


-- [30] PLAYER TAB -----------------------------------------------------
do
	local okSecP, errSecP = pcall(function()
	local player = Tabs[3]

	player:AddSlider({
		Title        = "Walk Speed",
		Min          = 16,
		Max          = 500,
		Default      = 16,
		Suffix       = "",
		WithToggle   = true,
		ToggleTitle  = "Enable Speed",
		Flag         = "Speed",
		OnToggle     = function(on)
			Features.Speed.On = on
			ApplySpeed()
		end,
		Callback     = function(v)
			Features.Speed.Value = v
			if Features.Speed.On then ApplySpeed() end
		end,
	})

	player:AddSlider({
		Title        = "Jump Power",
		Min          = 50,
		Max          = 350,
		Default      = 50,
		WithToggle   = true,
		ToggleTitle  = "Custom Jump",
		Flag         = "JumpPower",
		OnToggle     = function(on)
			Features.Jump.On = on
			ApplyJump()
		end,
		Callback     = function(v)
			Features.Jump.Value = v
			if Features.Jump.On then ApplyJump() end
		end,
	})

	player:AddToggle({
		Title    = "Highlight ESP",
		Flag     = "HighlightESP",
		Callback = function(on)
			Features.ESP = on
			SetESP(on)
		end,
	})

	player:AddToggle({
		Title    = "FPS Boost",
		Flag     = "FPSBoost",
		Callback = function(on)
			Features.Boost = on
			SetBoost(on)
			if on then Notify("Player", "FPS Boost включён") end
		end,
	})

	player:AddToggle({
		Title    = "Noclip",
		Flag     = "Noclip",
		Callback = function(on)
			Features.Noclip = on
			pcall(function()
				local char = GetChar()
				if char and not on then
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") then part.CanCollide = true end
					end
				end
			end)
		end,
	})

	player:AddToggle({
		Title    = "Infinite Jump",
		Flag     = "InfiniteJump",
		Callback = function(on)
			Features.InfJump = on
		end,
	})

	player:AddToggle({
		Title    = "Anti AFK",
		Flag     = "AntiAFK",
		Callback = function(on)
			Features.AntiAFK = on
			if on then Notify("Player", "Anti AFK активен") end
		end,
	})

	player:AddSlider({
		Title        = "Spin Speed",
		Min          = 1,
		Max          = 100,
		Default      = 20,
		WithToggle   = true,
		ToggleTitle  = "Enable Spin",
		Flag         = "Spin",
		OnToggle     = function(on)
			Features.Spin.On = on
		end,
		Callback     = function(v)
			Features.Spin.Speed = v
		end,
	})
	end)
	if not okSecP then warn("[SkyLine Hub] Player tab error:", errSecP) end
end


-- [31] LOADSCRIPT TAB -------------------------------------------------
do
	local okSecL, errSecL = pcall(function()
	local loadTab = Tabs[4]

	loadTab:AddLabel({ Text = "Нажмите на скрипт для запуска.", Height = S(20) })

	loadTab:AddScriptRow({
		Title = "Infinite Yield",
		Callback = function()
			pcall(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
			end)
		end,
	})

	loadTab:AddScriptRow({
		Title = "Dark Dex Explorer",
		Callback = function()
			pcall(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/Rblx_Scripts/master/Testing/new_dex.lua"))()
			end)
		end,
	})

	loadTab:AddScriptRow({
		Title = "SkyLine Test Script",
		Callback = function()
			print("[SkyLine Hub] Test script executed!")
			Notify("LoadScript", "Test script выполнен — смотрите консоль")
		end,
	})
	end)
	if not okSecL then warn("[SkyLine Hub] LoadScript tab error:", errSecL) end
end


-- [32] SETTINGS TAB ---------------------------------------------------
do
	local okSecS, errSecS = pcall(function()
	local settings = Tabs[5]

	settings:AddToggle({
		Title    = "Disable Heavy Effects",
		Flag     = "HeavyEffects",
		Callback = function(on)
			HeavyOff = on
			if on and StaticGlow then StaticGlow() end
			if on then Notify("Settings", "Тяжёлые эффекты отключены") end
		end,
	})

	local themeNames = {}
	for themeName in pairs(THEMES) do
		themeNames[#themeNames + 1] = themeName
	end
	table.sort(themeNames)

	settings:AddDropdown({
		Title          = "Theme",
		Options        = themeNames,
		Default        = "Ocean",
		Flag           = "SelectedTheme",
		RefreshOptions = function() return themeNames end,
		Callback       = function(sel)
			if ApplyTheme(sel) then
				Notify("Settings", "Тема: " .. tostring(sel))
				pcall(SavePreset, "_autosave", true)
			end
		end,
	})

	settings:AddButton({
		Title = "Save Settings",
		Callback = function()
			RequestInput("Save Preset", "Введите название пресета", function(name)
				if SavePreset(name) then
					Notify("Settings", "Пресет сохранён: " .. name)
				end
			end)
		end,
	})

	settings:AddDropdown({
		Title          = "Load Settings",
		Options        = { "- no presets -" },
		Flag           = nil,
		RefreshOptions = function()
			local list = ListPresets()
			if #list == 0 then return { "- no presets -" } end
			return list
		end,
		Callback = function(sel)
			if sel == "- no presets -" then return end
			pcall(function() LoadPreset(sel) end)
		end,
	})

	settings:AddToggle({
		Title    = "Auto Save Settings",
		Default  = true,
		Flag     = "AutoSave",
		Callback = function(on)
			AutoSaveOn = on
		end,
	})

	settings:AddButton({
		Title    = "Destroy GUI",
		Danger   = true,
		Callback = function()
			task.delay(0.15, function()
				pcall(function() Library:Destroy() end)
			end)
		end,
	})
	end)
	if not okSecS then warn("[SkyLine Hub] Settings tab error:", errSecS) end
end


-- [33] SHOW / HIDE CHOREOGRAPHY ---------------------------------------
local NAV_HIDDEN_X = -(navW + S(46))

ShowInterface = function()
	if not Hidden or BusyUI then return end
	BusyUI = true
	Hidden = false
	BootedOnce = true
	task.delay(0.85, function() BusyUI = false end)
	local okShow, errShow = pcall(function()

	pcall(CloseAllDD)

	WindowLayer.Visible = true
	ArrowBtn.Visible = true

	NavCanvas.GroupTransparency = 1
	Nav.Position = UDim2.new(0, NAV_HIDDEN_X, 0.5, 0)
	NavScale.Scale = 0.94

	ContentCanvas.GroupTransparency = 1
	Content.Position = UDim2.new(0.5, 0, 0.5, S(22))
	ContentScale.Scale = 0.95

	-- плавно проявляем амбиент (затемнение + северное сияние)
	Tween(AmbientDim, 0.7, { BackgroundTransparency = 0.38 })
	for _, e in ipairs(GlowEdges) do
		Tween(e.Frame, 0.9, { BackgroundTransparency = e.Base })
	end

	Tween(ArrowLbl, 0.3, { Rotation = 180 }, Enum.EasingStyle.Quad)
	Tween(ArrowBtn, 0.4, { Position = UDim2.new(0, ARROW_SHOWN_X, 0.5, 0) })

	task.delay(0.05, function()
		Tween(NavCanvas, 0.5, { GroupTransparency = 0 })
		Tween(NavScale, 0.55, { Scale = 1 }, Enum.EasingStyle.Back)
		Tween(Nav, 0.55, { Position = UDim2.new(0, S(18), 0.5, 0) }, Enum.EasingStyle.Cubic)
	end)
	task.delay(0.18, function()
		Tween(ContentCanvas, 0.45, { GroupTransparency = 0 })
		Tween(ContentScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Cubic)
		Tween(Content, 0.5, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Cubic)
	end)
	end)
	if not okShow then warn("[SkyLine Hub] show error:", errShow) end
end

HideInterface = function()
	if Hidden or BusyUI then return end
	BusyUI = true
	task.delay(0.55, function()
		Hidden = true
		WindowLayer.Visible = false
		BusyUI = false
	end)
	local okHide, errHide = pcall(function()
	pcall(CloseAllDD)

	Tween(NavCanvas, 0.35, { GroupTransparency = 1 })
	Tween(NavScale, 0.35, { Scale = 0.94 })
	Tween(Nav, 0.4,
		{ Position = UDim2.new(0, NAV_HIDDEN_X, 0.5, 0) },
		Enum.EasingStyle.Cubic, Enum.EasingDirection.In)

	Tween(ContentCanvas, 0.35, { GroupTransparency = 1 })
	Tween(ContentScale, 0.35, { Scale = 0.95 })
	Tween(Content, 0.4,
		{ Position = UDim2.new(0.5, 0, 0.5, S(22)) },
		Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	-- плавно гасим амбиент вместе с меню
	Tween(AmbientDim, 0.55, { BackgroundTransparency = 1 })
	for _, e in ipairs(GlowEdges) do
		Tween(e.Frame, 0.55, { BackgroundTransparency = 1 })
	end

	Tween(ArrowLbl, 0.3, { Rotation = 0 }, Enum.EasingStyle.Quad)
	Tween(ArrowBtn, 0.4, { Position = UDim2.new(0, ARROW_HIDDEN_X, 0.5, 0) })

	end)
	if not okHide then warn("[SkyLine Hub] hide error:", errHide) end
end

-- [34] INITIAL TAB VISIBILITY -----------------------------------------
Tabs[1].Page.Visible = true

-- страховка: если цепочка загрузки где-то упала — принудительно показать UI
task.delay(6, function()
	if (not BootedOnce) and Hidden and not BusyUI then
		pcall(function() ShowInterface() end)
	end
end)


-- [35] LOADING SCREEN -------------------------------------------------
local function RunLoading()
	WindowLayer.Visible = false -- окно показывается только после загрузки
	local LoadingLayer = New("CanvasGroup", {
		Name                   = "LoadingLayer",
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.fromScale(1, 1),
		ZIndex                 = 200,
		Parent                 = ScreenGui,
	})
	local loadingScale = New("UIScale", { Scale = 1, Parent = LoadingLayer })

	local scrim = New("Frame", {
		Name                   = "Scrim",
		BackgroundColor3       = C(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.fromScale(1, 1),
		Parent                 = LoadingLayer,
	})

	local card = New("CanvasGroup", {
		Name                   = "LoadingCard",
		BackgroundColor3       = COLORS.Background,
		BorderSizePixel        = 0,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.fromScale(0.5, 0.5),
		Size                   = UDim2.fromOffset(S(340), S(190)),
		GroupTransparency      = 1,
		Parent                 = LoadingLayer,
	})
	Corner(card, S(18))
	StrokeOf(card)
	local cardScale = New("UIScale", { Scale = 0.7, Parent = card })

	local titleGrad = New("UIGradient",
		{ Color = ColorSequence.new(COLORS.Text, Theme.Accent), Parent = nil })
	local title = New("TextLabel", {
		Name                   = "Title",
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = UDim2.new(0.5, 0, 0, S(34)),
		Size                   = UDim2.fromOffset(S(300), S(40)),
		Font                   = Enum.Font.GothamBlack,
		Text                   = "SkyLine Hub",
		TextSize               = S(30),
		TextColor3             = COLORS.Text,
		Parent                 = card,
	})
	titleGrad.Parent = title

	local status = New("TextLabel", {
		Name                   = "Status",
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = UDim2.new(0.5, 0, 0, S(84)),
		Size                   = UDim2.fromOffset(S(280), S(16)),
		Font                   = FONT_MED,
		Text                   = "Loading",
		TextColor3             = COLORS.SubText,
		TextSize               = S(12),
		Parent                 = card,
	})

	local waveArea = New("Frame", {
		Name                   = "WaveArea",
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Position               = UDim2.new(0, 0, 0, S(120)),
		Size                   = UDim2.new(1, 0, 0, S(44)),
		Parent                 = card,
	})
	local BALL_COUNT = 8
	local balls = {}
	for i = 1, BALL_COUNT do
		local b = New("Frame", {
			Name             = "Ball" .. i,
			BackgroundColor3 = i % 2 == 1 and Theme.Accent or COLORS.Text,
			BackgroundTransparency = i % 2 == 0 and 0.25 or 0,
			BorderSizePixel  = 0,
			AnchorPoint      = Vector2.new(0.5, 0.5),
			Size             = UDim2.fromOffset(S(11), S(11)),
			Position         = UDim2.new(0.5, S((i - 4) * 18), 0.5, 0),
			Parent           = waveArea,
		})
		Corner(b, S(6))
		balls[i] = b
	end

	Tween(scrim, 0.5, { BackgroundTransparency = 0.35 })
	Tween(LoadingLayer, 0.45, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
	Tween(card, 0.5, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
	Tween(cardScale, 0.55, { Scale = 1 }, Enum.EasingStyle.Back)

	local statuses = { "Loading assets...", "Building interface...", "Injecting modules...", "Almost ready..." }
	local t0 = os.clock()
	local done = false

	local animConn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		for i, b in ipairs(balls) do
			local ph = t * 2.6 - (i - 1) * 0.85
		local x = math.sin(ph) * S(56)
		local y = math.sin(ph * 2) * S(4)
			b.Position = UDim2.new(0.5, x - S((i - 4) * 18), 0.5, y)
		end
		titleGrad.Offset = Vector2.new(math.sin(t * 0.9) * 0.35, 0)
	end)

	task.spawn(function()
		while not done do
			for _, s in ipairs(statuses) do
				if done then break end
				status.Text = s
				task.wait(0.55)
			end
		end
	end)

	task.delay(2.2, function()
		done = true
		pcall(function() animConn:Disconnect() end)

		Tween(card, 0.32, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Tween(cardScale, 0.3, { Scale = 0.92 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Tween(LoadingLayer, 0.35, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Tween(scrim, 0.4, { BackgroundTransparency = 1 })

		Tween(AmbientDim, 0.7, { BackgroundTransparency = 0.38 })

		for i, e in ipairs(GlowEdges) do
			task.delay(i * 0.06, function()
				Tween(e.Frame, 0.9, { BackgroundTransparency = e.Base })
			end)
		end

		task.delay(0.4, function() pcall(function() LoadingLayer:Destroy() end) end)
		task.delay(0.45, function() pcall(function() ShowInterface() end) end)
		task.delay(1.6, function()
			if FS.Exists(FOLDER .. "/_autosave.skyline") then
				pcall(LoadPreset, "_autosave", true)
			end
		end)
	end)
end


-- [36] PUBLIC API -----------------------------------------------------
Library = {}

Library.Version = "1.0"
Library.Flags   = Flags
Library.Themes  = THEMES

Library.Window = {
	Tabs            = TabByName,
	GetTab          = function(self, name) return TabByName[tostring(name)] end,
	AddScriptButton = function(self, cfg)
		return AddScriptRow(Tabs[4].Host, cfg)
	end,
	Show   = function() pcall(ShowInterface) end,
	Hide   = function() pcall(HideInterface) end,
	Toggle = function()
		if Hidden then pcall(ShowInterface) else pcall(HideInterface) end
	end,
	SetTheme = function(self, name) return ApplyTheme(name) end,
}

Library.Notify     = Notify
Library.SetTheme   = ApplyTheme
Library.SavePreset = function(_, name) return SavePreset(name) end
Library.LoadPreset = function(_, name) return LoadPreset(name) end
Library.GetPresets = ListPresets

Library.Destroy = function(_)
	pcall(function()
		Features.Speed.On  = false
		Features.Jump.On   = false
		Features.Noclip    = false
		Features.Spin.On   = false
		ApplySpeed()
		ApplyJump()
		SetESP(false)
		SetBoost(false)
	end)
	for _, co in ipairs(Threads) do
		pcall(function() task.cancel(co) end)
	end
	for _, conn in ipairs(Conns) do
		pcall(function() conn:Disconnect() end)
	end
	for i = #Threads, 1, -1 do Threads[i] = nil end
	for i = #Conns, 1, -1 do Conns[i] = nil end
	pcall(function() ScreenGui:Destroy() end)
	local g = _G
	pcall(function() if getgenv then g = getgenv() end end)
	g.SkyLineHubInstance = nil
end

RunLoading()

do
	local g = _G
	pcall(function() if getgenv then g = getgenv() end end)
	g.SkyLineHubInstance = Library
end

print("[SkyLine Hub] v" .. Library.Version .. " loaded")

return Library

--[[ ═══════════════════ SKYLINE HUB • ПОЛНЫЙ ПРИМЕР API ═══════════════════

-- 1) Подключение -----------------------------------------------------------
local SkyLine = loadstring(game:HttpGet("https://your-url/SkyLineHub.lua"))()
-- локально:  local SkyLine = loadstring(readfile("SkyLineHub.lua"))()

local Win  = SkyLine.Window   -- главное окно (создаётся автоматически)
local Tabs = Win.Tabs         -- { Home, Main, Player, LoadScript, Settings }
local Main = Tabs.Main

-- 2) Toggle -----------------------------------------------------------------
Main:AddToggle({
	Title    = "My Toggle",
	Default  = false,
	Flag     = "MyToggle",            -- имя для автосохранения в пресет
	Callback = function(state)
		print("toggle:", state)
	end,
})

-- 3) Button (+ Danger-вариант) ----------------------------------------------
Main:AddButton({
	Title    = "Action",
	Callback = function()
		print("clicked!")
	end,
})
Tabs.Settings:AddButton({
	Title    = "Panic",
	Danger   = true,
	Callback = function()
		SkyLine:Destroy()             -- полный cleanup интерфейса
	end,
})

-- 4) Label -------------------------------------------------------------------
Main:AddLabel({ Text = "Обычная строка" })
Main:AddLabel({ Text = "Крупный текст", Bold = true, Size = 14 })

-- 5) Slider ------------------------------------------------------------------
Main:AddSlider({
	Title     = "Volume",
	Min       = 0,
	Max       = 100,
	Default   = 50,
	Increment = 1,                    -- шаг
	Suffix    = "%",
	Flag      = "MySlider",
	Callback  = function(v)
		print("slider:", v)           -- число едет вместе с бегунком
	end,
})

-- 5b) Slider со встроенным переключателем (общий фон) ------------------------
Main:AddSlider({
	Title       = "Field Of View",
	Min         = 60,
	Max         = 120,
	Default     = 70,
	WithToggle  = true,
	ToggleTitle = "Enable FOV",
	Flag        = "FovValue",
	ToggleFlag  = "FovEnabled",
	OnToggle    = function(on)
		print("fov on:", on)
	end,
	Callback    = function(v)
		print("fov:", v)
	end,
})

-- 6) Dropdown — одинарный выбор -----------------------------------------------
Main:AddDropdown({
	Title    = "Quality",
	Options  = { "Low", "Medium", "High" },
	Default  = "Medium",
	Flag     = "Quality",
	Callback = function(sel)
		print("quality:", sel)
	end,
})

-- 7) Dropdown — мультивыбор (чекбоксы + Select All / Clear) --------------------
local espDD = Main:AddDropdown({
	Title    = "ESP Filters",
	Options  = { "Players", "NPCs", "Animals", "Vehicles" },
	Default  = { "Players" },
	Multi    = true,
	Flag     = "EspFilters",
	Callback = function(list)
		print("selected:", table.concat(list, ", "))
	end,
})

-- программное управление дропдауном:
espDD.Refresh({ "A", "B", "C" })      -- заменить список опций
espDD.Set({ "A", "C" })               -- установить выбор таблицей
print(espDD.Get())                    -- -> { "A", "C" }

-- 8) Block — сворачиваемая секция (стрелка вниз, содержимое выезжает) ----------
local Combat = Main:AddBlock("Combat")
Combat.AddToggle({ Title = "Aim Assist", Flag = "AA" })
Combat.AddSlider({ Title = "Smoothness", Min = 1, Max = 10, Default = 3 })
Combat.AddDropdown({ Title = "Target Part", Options = { "Head", "Torso" } })
Combat.Set(true)                      -- открыть программно
print(Combat.Get())                   -- состояние откры/закрыт
-- правая панель блоков появляется сама, когда блоков больше одного

-- 9) ScriptButton — кнопка запуска скрипта (вкладка LoadScript) ----------------
Win:AddScriptButton({
	Title    = "My Script",
	Callback = function()
		print("running my script...")
	end,
})

-- 10) Темы ---------------------------------------------------------------------
SkyLine.SetTheme("Indigo Night")      -- Ocean | Indigo Night | Emerald | Crimson
for name in pairs(SkyLine.Themes) do
	print("тема:", name)
end

-- 11) Пресеты ------------------------------------------------------------------
SkyLine:SavePreset("my-config")       -- сохранить все Flag'и в файл
SkyLine:LoadPreset("my-config")       -- загрузить
for _, name in ipairs(SkyLine:GetPresets()) do
	print("пресет:", name)
end
-- Auto Save (Settings): каждое изменение Flag сохраняется в "_autosave"
-- и автоматически подхватывается при следующем запуске.

-- 12) Уведомления ----------------------------------------------------------------
SkyLine.Notify("Заголовок", "Текст уведомления", 3)

-- 13) Окно ------------------------------------------------------------------------
Win.Toggle()                          -- показать/скрыть (как стрелочка)
Win.Hide()
task.wait(1)
Win.Show()
Win:GetTab("Player"):AddLabel({ Text = "добавлено на лету" })

-- 14) Флаги напрямую ----------------------------------------------------------------
SkyLine.Flags.MyToggle.Set(true)      -- программно включить элемент
print(SkyLine.Flags.MyToggle.Get())   -- текущее состояние

-- 15) Destroy -----------------------------------------------------------------------
-- SkyLine:Destroy()                  -- отключить все соединения/циклы и убрать GUI
================================================================ ]]
