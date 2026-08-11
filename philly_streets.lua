-- =========================================================
-- Lyzn Hub — Crystal-themed UI + Luarmor key auth
-- =========================================================
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Lucide icons
local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"))()
end)
local function lucideProps(name)
	if not Lucide then return nil end
	local ok, asset = pcall(function() return Lucide.GetAsset(name) end)
	if not ok or not asset then return nil end
	return { Image = asset.Url or asset.Id, ImageRectOffset = asset.ImageRectPosition or asset.ImageRectOffset, ImageRectSize = asset.ImageRectSize }
end

local Cfg = {
	WinSize = Vector2.new(800, 580),
	TopH = 56,
	SidebarW = 190,
	ProfileH = 84,
	CrystalLogo = "rbxassetid://78492884826986",
	ScriptId = "cc39c2c657dcac097bac251bc38de8b2",

	-- Colors sampled from the screenshot
	Bg = Color3.fromRGB(15, 15, 20),           -- deep black with slight blue tint
	Panel = Color3.fromRGB(22, 22, 30),        -- row / card
	PanelHi = Color3.fromRGB(30, 30, 40),
	Row = Color3.fromRGB(26, 26, 34),
	TabBar = Color3.fromRGB(18, 18, 24),
	Stroke = Color3.fromRGB(40, 40, 52),
	StrokeSoft = Color3.fromRGB(32, 32, 44),

	Accent = Color3.fromRGB(255, 255, 255),    -- toggles/sliders fill WHITE
	AccentDim = Color3.fromRGB(200, 200, 210),
	Text = Color3.fromRGB(245, 245, 250),
	TextDim = Color3.fromRGB(160, 160, 175),
	TextFaint = Color3.fromRGB(105, 105, 120),

	FontTitle = Enum.Font.Bangers,
	FontBold = Enum.Font.Bangers,
	FontMed = Enum.Font.Bangers,
	FontReg = Enum.Font.Bangers,

	Tween = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Fade = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	MinScale = 0.4,
	ScaleBase = Vector2.new(880, 660),
	ToggleKey = Enum.KeyCode.LeftControl,
}

local function New(cls, props, kids)
	local o = Instance.new(cls)
	for k, v in pairs(props or {}) do if k ~= "Parent" then o[k] = v end end
	if kids then for _, c in ipairs(kids) do c.Parent = o end end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function corner(p, r) return New("UICorner", { CornerRadius = r or UDim.new(0, 10), Parent = p }) end
local function stroke(p, c, t) return New("UIStroke", { Color = c or Cfg.Stroke, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p }) end
local function padding(p, t, b, l, r) return New("UIPadding", { PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or t or 0), PaddingLeft = UDim.new(0, l or t or 0), PaddingRight = UDim.new(0, r or t or 0), Parent = p }) end

-- =========================================================
-- Luarmor key auth
-- =========================================================
local function getExecutorName()
	local ok, n = pcall(function() return identifyexecutor() end)
	if ok and typeof(n) == "string" and n ~= "" then return n end
	ok, n = pcall(function() return getexecutorname() end)
	if ok and typeof(n) == "string" and n ~= "" then return n end
	return "Unknown"
end
local KeyCheckUrl = "https://sdkapi-public.luarmor.net/library.lua"
local function fetchSecondsLeft()
	if typeof(LuarmorExpiry) == "number" then
		if LuarmorExpiry <= 0 or LuarmorExpiry < 1000000000 then return math.huge end
		return LuarmorExpiry - os.time()
	end
	local key = (typeof(script_key) == "string" and script_key ~= "" and script_key)
	         or (typeof(LuarmorKey)  == "string" and LuarmorKey  ~= "" and LuarmorKey)
	         or nil
	if not key then return nil end
	local ld, api = pcall(function() return loadstring(game:HttpGet(KeyCheckUrl))() end)
	if not ld or typeof(api) ~= "table" then return nil end
	api.script_id = Cfg.ScriptId
	local ok, st = pcall(api.check_key, key)
	if not ok or typeof(st) ~= "table" or st.code ~= "KEY_VALID" then return nil end
	local e = tonumber(st.data and st.data.auth_expire)
	if not e then return nil end
	if e <= 0 then return math.huge end
	return e - os.time()
end
local function formatSecondsLeft(s)
	if typeof(s) ~= "number" or s ~= s then return "—" end
	if s == math.huge then return "Lifetime" end
	if s <= 0 then return "Expired" end
	local d = math.floor(s/86400); local h = math.floor((s%86400)/3600); local m = math.floor((s%3600)/60)
	if d > 0 then return string.format("%dd %dh left", d, h) end
	if h > 0 then return string.format("%dh %dm left", h, m) end
	return string.format("%dm left", math.max(m, 1))
end

local function protectGui(gui)
	local ok = pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent = game:GetService("CoreGui")
		elseif gethui then gui.Parent = gethui()
		else gui.Parent = game:GetService("CoreGui") end
	end)
	if not ok then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
end

-- =========================================================
-- Library
-- =========================================================
local Library = {}; Library.__index = Library

function Library:CreateWindow(opts)
	opts = opts or {}
	local screen = New("ScreenGui", { Name = "\0Crystal\0", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 999 })
	protectGui(screen)

	local root = New("CanvasGroup", {
		Parent = screen, Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Cfg.WinSize.X, Cfg.WinSize.Y),
		BackgroundColor3 = Cfg.Bg, GroupTransparency = 1, ClipsDescendants = true,
	})
	corner(root, UDim.new(0, 14)); stroke(root, Cfg.StrokeSoft, 1)

	-- =====================================================
	-- Background: subtle rotated crystal shapes + gradient
	-- =====================================================
	local bg = New("Frame", { Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Cfg.Bg, BorderSizePixel = 0, ZIndex = 0 })
	-- Vertical gradient
	New("UIGradient", {
		Parent = bg, Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 14)),
		}),
	})

	-- Rotated crystal shapes (diamonds) scattered behind everything
	local shapes = {
		{ x = 0.85, y = 0.25, size = 220, rot = 25, alpha = 0.94 },
		{ x = 0.15, y = 0.85, size = 260, rot = -20, alpha = 0.95 },
		{ x = 0.9,  y = 0.75, size = 180, rot = 35, alpha = 0.94 },
		{ x = 0.05, y = 0.15, size = 160, rot = 40, alpha = 0.96 },
		{ x = 0.55, y = 0.55, size = 200, rot = -15, alpha = 0.96 },
	}
	for _, s in ipairs(shapes) do
		local d = New("Frame", {
			Parent = bg, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(s.x, s.y), Size = UDim2.fromOffset(s.size, s.size),
			Rotation = s.rot, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = s.alpha, BorderSizePixel = 0, ZIndex = 0,
		})
		corner(d, UDim.new(0, 24))
		stroke(d, Color3.fromRGB(255, 255, 255), 1).Transparency = 0.9
	end

	-- Faint diagonal line pattern top-right
	for i = 1, 8 do
		local line = New("Frame", {
			Parent = bg, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -20 * i, 0, -30), Size = UDim2.new(0, 1, 0, 90),
			Rotation = 30, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.95, BorderSizePixel = 0, ZIndex = 0,
		})
	end

	local uiScale = New("UIScale", { Parent = root, Scale = 1 })
	local cam = workspace.CurrentCamera
	local function updScale()
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local raw = math.min(vp.X / Cfg.ScaleBase.X, vp.Y / Cfg.ScaleBase.Y)
		-- Mobile: keep floor higher so text stays readable
		local isMobile = vp.X < 900 or vp.Y < 600
		local floor = isMobile and 0.45 or Cfg.MinScale
		uiScale.Scale = math.clamp(raw, floor, 1)
	end
	updScale(); if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(updScale) end

	-- ================================================
	-- TOPBAR
	-- ================================================
	local topbar = New("Frame", { Parent = root, Size = UDim2.new(1, 0, 0, Cfg.TopH), BackgroundTransparency = 1 })

	-- Logo — crystal image, no background, bigger
	local mark = New("CanvasGroup", {
		Parent = topbar, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(46, 46),
		BackgroundTransparency = 1, ClipsDescendants = true,
	})
	corner(mark, UDim.new(0, 10))
	New("ImageLabel", {
		Parent = mark, Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, Image = Cfg.CrystalLogo,
		ScaleType = Enum.ScaleType.Stretch,
	})

	-- Centered title with subtle side dashes
	local titleWrap = New("Frame", {
		Parent = topbar, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 340, 0, 30),
		BackgroundTransparency = 1,
	})
	New("Frame", { Parent = titleWrap, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(24, 1), BackgroundColor3 = Cfg.Stroke, BorderSizePixel = 0 })
	New("Frame", { Parent = titleWrap, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(24, 1), BackgroundColor3 = Cfg.Stroke, BorderSizePixel = 0 })
	New("TextLabel", {
		Parent = titleWrap, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1, Font = Cfg.FontTitle,
		Text = string.upper(opts.Title or "Lyzn Hub"),
		TextColor3 = Cfg.Text, TextSize = 24,
	})

	-- Minimize button top-right
	local minBtn = New("TextButton", {
		Parent = topbar, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = Cfg.Panel, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "",
	})
	corner(minBtn, UDim.new(0, 7)); stroke(minBtn, Cfg.Stroke, 1)
	New("Frame", {
		Parent = minBtn, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(12, 2),
		BackgroundColor3 = Cfg.TextDim, BorderSizePixel = 0,
	})
	minBtn.MouseEnter:Connect(function() TweenService:Create(minBtn, Cfg.Tween, { BackgroundColor3 = Cfg.PanelHi }):Play() end)
	minBtn.MouseLeave:Connect(function() TweenService:Create(minBtn, Cfg.Tween, { BackgroundColor3 = Cfg.Panel }):Play() end)

	-- Bottom border with gradient fade
	local topDiv = New("Frame", {
		Parent = topbar, Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Cfg.Text, BorderSizePixel = 0,
	})
	New("UIGradient", { Parent = topDiv, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})})

	-- ================================================
	-- SIDEBAR (tab list + profile card at bottom) — same nebula theme as the profile
	-- ================================================
	local sidebar = New("Frame", {
		Parent = root, Position = UDim2.new(0, 0, 0, Cfg.TopH),
		Size = UDim2.new(0, Cfg.SidebarW, 1, -Cfg.TopH),
		BackgroundColor3 = Color3.fromRGB(14, 12, 22), BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	-- Nebula gradient (matches profile card)
	New("UIGradient", {
		Parent = sidebar, Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 20, 40)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(24, 12, 26)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 8, 18)),
		}),
	})
	-- Star layer behind everything (drifting)
	do
		local rng = Random.new()
		for i = 1, 40 do
			local sz = rng:NextNumber(0.8, 1.8)
			local base = rng:NextNumber(0.4, 0.8)
			local x0 = rng:NextNumber(0.02, 0.98)
			local y0 = rng:NextNumber(0.02, 0.98)
			local s = New("Frame", {
				Parent = sidebar, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(x0, y0), Size = UDim2.fromOffset(sz, sz),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = base, BorderSizePixel = 0, ZIndex = 0,
			})
			corner(s, UDim.new(1, 0))
			TweenService:Create(s, TweenInfo.new(rng:NextNumber(1.5, 3.2), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 2)), { BackgroundTransparency = math.min(1, base + 0.35) }):Play()
			local dy = rng:NextNumber(-3, 3) / 100
			TweenService:Create(s, TweenInfo.new(rng:NextNumber(6, 12), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 3)), { Position = UDim2.fromScale(x0, y0 + dy) }):Play()
		end
	end
	-- Right border
	New("Frame", { Parent = sidebar, Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Color3.fromRGB(80, 30, 50), BorderSizePixel = 0, ZIndex = 5 })
	-- Top glow band (accent-tinted, matches profile card feel)
	local topGlow = New("Frame", {
		Parent = sidebar, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(1.4, 0, 0, 50),
		BackgroundColor3 = Color3.fromRGB(180, 40, 80), BorderSizePixel = 0, ZIndex = 0,
	})
	New("UIGradient", { Parent = topGlow, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1) }) })

	local tabList = New("ScrollingFrame", {
		Parent = sidebar, Size = UDim2.new(1, 0, 1, -(Cfg.ProfileH + 16)),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 2,
	})
	padding(tabList, 10, 10, 10, 10)
	New("UIListLayout", { Parent = tabList, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })

	-- Profile card (bottom of sidebar) — nebula bg, avatar, name, online status
	do
		local LP = Players.LocalPlayer
		local uid = LP and LP.UserId or 1
		local un = LP and LP.Name or "Player"
		local disp = (LP and LP.DisplayName ~= "" and LP.DisplayName) or un

		local card = New("TextButton", {
			Parent = sidebar, AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, Cfg.ProfileH),
			BackgroundColor3 = Color3.fromRGB(14, 12, 22), AutoButtonColor = false, Text = "",
			BorderSizePixel = 0, ClipsDescendants = true,
		})
		corner(card, UDim.new(0, 12)); stroke(card, Color3.fromRGB(80, 30, 50), 1)

		-- Nebula gradient
		New("UIGradient", {
			Parent = card, Rotation = 135,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 25, 45)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 15, 30)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 10, 22)),
			}),
		})

		-- Twinkling stars behind
		do
			local rng = Random.new()
			for i = 1, 14 do
				local sz = rng:NextNumber(1, 1.8)
				local base = rng:NextNumber(0.35, 0.7)
				local s = New("Frame", {
					Parent = card, AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.05, 0.95)),
					Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = base, BorderSizePixel = 0,
				})
				corner(s, UDim.new(1, 0))
				TweenService:Create(s, TweenInfo.new(rng:NextNumber(1.4, 3), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 2)), { BackgroundTransparency = math.min(1, base + 0.35) }):Play()
			end
		end

		-- Avatar with double-ring
		local avatarGlow = New("Frame", {
			Parent = card, AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(54, 54),
			BackgroundColor3 = Cfg.Accent, BackgroundTransparency = 0.85, BorderSizePixel = 0,
		})
		corner(avatarGlow, UDim.new(1, 0))
		local avatar = New("ImageLabel", {
			Parent = card, AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(46, 46),
			BackgroundColor3 = Cfg.Bg, BorderSizePixel = 0, Image = "",
		})
		corner(avatar, UDim.new(1, 0)); stroke(avatar, Cfg.Text, 1.5)
		task.spawn(function()
			local ok, ct = pcall(function() return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
			avatar.Image = ok and ct or ("rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=48&h=48")
		end)

		-- Name
		New("TextLabel", {
			Parent = card, Position = UDim2.fromOffset(72, 12),
			Size = UDim2.new(1, -80, 0, 18),
			BackgroundTransparency = 1, Font = Cfg.FontBold, Text = string.upper(disp),
			TextColor3 = Cfg.Text, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		-- Executor
		New("TextLabel", {
			Parent = card, Position = UDim2.fromOffset(72, 32),
			Size = UDim2.new(1, -80, 0, 14),
			BackgroundTransparency = 1, Font = Cfg.FontMed, Text = getExecutorName(),
			TextColor3 = Cfg.TextDim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		-- Expiry row: green dot + countdown
		local statusWrap = New("Frame", { Parent = card, Position = UDim2.fromOffset(72, 52), Size = UDim2.new(1, -80, 0, 14), BackgroundTransparency = 1 })
		local dot = New("Frame", { Parent = statusWrap, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = Color3.fromRGB(80, 220, 130), BorderSizePixel = 0 })
		corner(dot, UDim.new(1, 0))
		TweenService:Create(dot, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.5 }):Play()
		local expiryLbl = New("TextLabel", {
			Parent = statusWrap, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -12, 1, 0),
			BackgroundTransparency = 1, Font = Cfg.FontMed, Text = "Checking key…",
			TextColor3 = Color3.fromRGB(120, 220, 160), TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		})
		task.spawn(function()
			local sl = fetchSecondsLeft()
			local mA = os.clock()
			expiryLbl.Text = formatSecondsLeft(sl)
			if typeof(sl) ~= "number" or sl == math.huge then return end
			while expiryLbl.Parent do
				local r = sl - (os.clock() - mA)
				expiryLbl.Text = formatSecondsLeft(r)
				if r <= 0 then expiryLbl.TextColor3 = Cfg.TextFaint; break end
				task.wait(r > 3600 and 30 or 1)
			end
		end)

		-- Click → copy profile link
		card.MouseButton1Click:Connect(function()
			pcall(function()
				local link = "https://www.roblox.com/users/" .. uid .. "/profile"
				if setclipboard then setclipboard(link) end
				local StarterGui = game:GetService("StarterGui")
				StarterGui:SetCore("SendNotification", { Title = "Profile copied", Text = link, Duration = 4 })
			end)
		end)
	end

	-- ================================================
	-- CONTENT (right of sidebar)
	-- ================================================
	local content = New("Frame", {
		Parent = root, Position = UDim2.new(0, Cfg.SidebarW, 0, Cfg.TopH),
		Size = UDim2.new(1, -Cfg.SidebarW, 1, -Cfg.TopH),
		BackgroundTransparency = 1,
	})
	padding(content, 14, 14, 14, 14)

	-- Smooth drag
	local function bindDrag(frame, handle)
		local dragging, dragStart, startPos, target = false
		local rc, ec
		local function stop()
			if rc then rc:Disconnect(); rc = nil end
			if ec then ec:Disconnect(); ec = nil end
			if dragging then dragging = false; if target then frame.Position = target end end
		end
		handle.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true; dragStart = i.Position; startPos = frame.Position; target = startPos
				rc = RunService.RenderStepped:Connect(function()
					local c = frame.Position
					frame.Position = UDim2.new(target.X.Scale, c.X.Offset + (target.X.Offset - c.X.Offset) * 0.3, target.Y.Scale, c.Y.Offset + (target.Y.Offset - c.Y.Offset) * 0.3)
				end)
				ec = i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then stop() end end)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - dragStart
				target = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then stop() end
		end)
	end
	bindDrag(root, topbar)

	-- Minimize-to-crystal pill (bottom-left, draggable, tap opens)
	local minPill = New("ImageButton", {
		Parent = screen, Position = UDim2.fromOffset(24, 200),
		Size = UDim2.fromOffset(56, 56),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		AutoButtonColor = false, Image = Cfg.CrystalLogo,
		ScaleType = Enum.ScaleType.Stretch,
		Selectable = false, Modal = false, Active = true,
		Visible = false, ZIndex = 200,
	})
	corner(minPill, UDim.new(0, 12))

	local shown = true
	local function setShown(s)
		shown = s
		if s then
			root.Visible = true; minPill.Visible = false
			TweenService:Create(root, Cfg.Fade, { GroupTransparency = 0 }):Play()
		else
			local f = TweenService:Create(root, Cfg.Fade, { GroupTransparency = 1 }); f:Play()
			f.Completed:Once(function() if not shown then root.Visible = false; minPill.Visible = true end end)
		end
	end
	minBtn.MouseButton1Click:Connect(function() setShown(false) end)

	-- Drag on minimize pill + tap to open
	do
		local dragging, dragStart, startPos, target, moved
		local rc, ec
		local function stop()
			if rc then rc:Disconnect(); rc = nil end
			if ec then ec:Disconnect(); ec = nil end
			if dragging then dragging = false; if target then minPill.Position = target end end
		end
		minPill.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true; moved = false; dragStart = i.Position; startPos = minPill.Position; target = startPos
				rc = RunService.RenderStepped:Connect(function()
					local c = minPill.Position
					minPill.Position = UDim2.new(target.X.Scale, c.X.Offset + (target.X.Offset - c.X.Offset) * 0.3, target.Y.Scale, c.Y.Offset + (target.Y.Offset - c.Y.Offset) * 0.3)
				end)
				ec = i.Changed:Connect(function()
					if i.UserInputState == Enum.UserInputState.End then
						if not moved then setShown(true) end
						stop()
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - dragStart
				if math.abs(d.X) + math.abs(d.Y) > 5 then moved = true end
				target = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
				if not moved then setShown(true) end
				stop()
			end
		end)
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Cfg.ToggleKey then setShown(not shown) end
	end)
	task.spawn(function() task.wait(0.1); TweenService:Create(root, Cfg.Fade, { GroupTransparency = 0 }):Play() end)

	local w = setmetatable({ Screen = screen, Root = root, TabList = tabList, Content = content, Tabs = {}, Current = nil }, { __index = Library.Window })
	return w
end

-- =========================================================
-- Tabs — pill with dot indicator on the left (dot = active state)
-- =========================================================
Library.Window = {}
-- Auto-map tab names to Lucide icons
local TabIconMap = {
	main = "home", home = "home", general = "home",
	combat = "swords", fight = "swords", pvp = "swords", kill = "swords",
	player = "user", players = "users", character = "user", char = "user",
	movement = "footprints", move = "footprints", walk = "footprints",
	settings = "settings", config = "settings", options = "settings",
	visuals = "eye", visual = "eye", esp = "eye", render = "eye",
	misc = "box", other = "box", extra = "box",
	world = "globe", server = "server", game = "gamepad-2",
	teleport = "map-pin", tp = "map-pin", location = "map-pin",
	farm = "sprout", auto = "zap", automation = "zap",
	shop = "shopping-cart", store = "shopping-cart",
	inventory = "package", items = "package", inv = "package",
	stats = "bar-chart-3", info = "info",
	credits = "heart", credit = "heart", about = "info",
	throwing = "send", throw = "send",
	catching = "hand", catch = "hand",
	defense = "shield", defence = "shield", block = "shield",
	physics = "atom", magnet = "magnet", magnets = "magnet",
	pull = "move", teleport_vector = "move",
	util = "wrench", utilities = "wrench", tools = "wrench",
	script = "file-code", scripts = "file-code",
	fun = "sparkles", troll = "sparkles",
	admin = "shield-check", dev = "code", developer = "code",
}
local function guessIcon(n)
	local key = string.lower(n or "")
	key = key:gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
	if TabIconMap[key] then return TabIconMap[key] end
	for word in string.gmatch(key, "[%w]+") do
		if TabIconMap[word] then return TabIconMap[word] end
	end
	return "circle"
end

function Library.Window:CreateTab(name, iconName)
	local btn = New("TextButton", {
		Name = name, Parent = self.TabList,
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Cfg.Panel, BackgroundTransparency = 1,
		AutoButtonColor = false, Text = "",
	})
	corner(btn, UDim.new(0, 8))

	local iconHolder = New("Frame", {
		Parent = btn, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
	})
	local icon
	local resolved = iconName or guessIcon(name)
	local props = resolved and lucideProps(resolved)
	-- try guess as last resort if user-supplied name isn't a real Lucide
	if (not props or not props.Image or props.Image == "") and iconName then
		props = lucideProps(guessIcon(name))
	end
	-- final fallback to "circle"
	if not props or not props.Image or props.Image == "" then
		props = lucideProps("circle")
	end
	if props and props.Image and props.Image ~= "" then
		icon = New("ImageLabel", {
			Parent = iconHolder, Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1, ImageColor3 = Cfg.TextDim,
			Image = props.Image,
		})
		if props.ImageRectOffset then icon.ImageRectOffset = props.ImageRectOffset end
		if props.ImageRectSize then icon.ImageRectSize = props.ImageRectSize end
	else
		-- Lucide failed to load entirely — use a small dot instead of the letter tile
		icon = New("Frame", {
			Parent = iconHolder, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = Cfg.TextDim, BorderSizePixel = 0,
		})
		corner(icon, UDim.new(1, 0))
	end

	local lbl = New("TextLabel", {
		Parent = btn, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -46, 1, 0),
		BackgroundTransparency = 1, Font = Cfg.FontBold, Text = string.upper(name),
		TextColor3 = Cfg.TextDim, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- Left accent bar for active tab
	local activeBar = New("Frame", {
		Parent = btn, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -2, 0.5, 0), Size = UDim2.fromOffset(3, 26),
		BackgroundColor3 = Cfg.Accent, BorderSizePixel = 0, Visible = false,
	})
	corner(activeBar, UDim.new(1, 0))

	local page = New("ScrollingFrame", {
		Parent = self.Content, Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false,
	})
	-- Two columns
	local left = New("Frame", { Parent = page, Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
	local right = New("Frame", { Parent = page, Position = UDim2.new(0.5, 6, 0, 0), Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
	New("UIListLayout", { Parent = left, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	New("UIListLayout", { Parent = right, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

	local tab = setmetatable({ Window = self, Btn = btn, Label = lbl, Icon = icon, ActiveBar = activeBar, Page = page, Left = left, Right = right }, { __index = Library.Tab })
	btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
	table.insert(self.Tabs, tab)
	if not self.Current then self:SelectTab(tab) end
	return tab
end

function Library.Window:SelectTab(tab)
	for _, t in ipairs(self.Tabs) do
		local active = t == tab
		t.Page.Visible = active
		t.ActiveBar.Visible = active
		TweenService:Create(t.Btn, Cfg.Tween, { BackgroundTransparency = active and 0 or 1, BackgroundColor3 = active and Cfg.Panel or Cfg.Panel }):Play()
		TweenService:Create(t.Label, Cfg.Tween, { TextColor3 = active and Cfg.Text or Cfg.TextDim }):Play()
		if t.Icon:IsA("ImageLabel") then
			TweenService:Create(t.Icon, Cfg.Tween, { ImageColor3 = active and Cfg.Text or Cfg.TextDim }):Play()
		else
			TweenService:Create(t.Icon, Cfg.Tween, { TextColor3 = active and Cfg.Text or Cfg.TextDim }):Play()
		end
	end
	self.Current = tab
end

-- =========================================================
-- Sections (header with dot + uppercase title, then rows)
-- =========================================================
Library.Tab = {}
function Library.Tab:CreateSection(title, side)
	local col = (side == "Right") and self.Right or self.Left

	-- Outer card (groupbox)
	local card = New("Frame", {
		Parent = col, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Cfg.PanelDark or Color3.fromRGB(20, 18, 26),
		BorderSizePixel = 0,
	})
	corner(card, UDim.new(0, 12))
	stroke(card, Cfg.StrokeSoft, 1)
	padding(card, 10, 12, 12, 12)

	-- Header row
	local header = New("Frame", { Parent = card, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = -1 })
	local hDot = New("Frame", {
		Parent = header, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(4, 4),
		BackgroundColor3 = Cfg.TextDim, BorderSizePixel = 0,
	})
	corner(hDot, UDim.new(1, 0))
	New("TextLabel", {
		Parent = header, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -12, 1, 0),
		BackgroundTransparency = 1, Font = Cfg.FontBold,
		Text = string.upper(title), TextColor3 = Cfg.TextDim,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- Divider under header
	New("Frame", {
		Parent = card, Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Cfg.StrokeSoft, BorderSizePixel = 0,
		BackgroundTransparency = 0.4, LayoutOrder = 0,
	})

	-- Inner wrap that rows go into
	local wrap = New("Frame", {
		Parent = card, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = 1,
	})
	New("UIListLayout", { Parent = wrap, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

	-- Card's own vertical stack (header, divider, wrap)
	New("UIListLayout", { Parent = card, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

	return setmetatable({ Wrap = wrap, Card = card }, { __index = Library.Section })
end

-- =========================================================
-- Row helpers
-- =========================================================
Library.Section = {}
local function makeRow(sec, h)
	local r = New("Frame", {
		Parent = sec.Wrap, Size = UDim2.new(1, 0, 0, h or 44),
		BackgroundColor3 = Cfg.Panel, BorderSizePixel = 0,
	})
	corner(r, UDim.new(0, 10)); stroke(r, Cfg.StrokeSoft, 1)
	padding(r, 0, 0, 14, 14)
	return r
end

function Library.Section:AddToggle(o)
	local r = makeRow(self, 44)
	New("TextLabel", {
		Parent = r, Size = UDim2.new(1, -56, 1, 0), BackgroundTransparency = 1,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Toggle"),
		TextColor3 = Cfg.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local state = o.Default == true

	-- Track — same nebula theme as profile card
	local track = New("TextButton", {
		Parent = r, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = Color3.fromRGB(14, 12, 22), BorderSizePixel = 0,
		AutoButtonColor = false, Text = "", ClipsDescendants = true,
	})
	corner(track, UDim.new(1, 0))
	local trackStroke = stroke(track, Color3.fromRGB(80, 30, 50), 1)

	-- Nebula gradient fill (only visible when ON)
	local trackGrad = New("UIGradient", {
		Parent = track, Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 25, 45)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 15, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 10, 22)),
		}),
	})

	local knob = New("Frame", {
		Parent = track, AnchorPoint = Vector2.new(0, 0.5),
		Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Cfg.TextDim,
		BorderSizePixel = 0,
	})
	corner(knob, UDim.new(1, 0))

	local ob = { State = state }
	local function render()
		local on = ob.State
		TweenService:Create(track, Cfg.Tween, {
			BackgroundColor3 = on and Color3.fromRGB(140, 30, 50) or Color3.fromRGB(14, 12, 22),
		}):Play()
		TweenService:Create(trackStroke, Cfg.Tween, {
			Color = on and Color3.fromRGB(200, 60, 90) or Color3.fromRGB(80, 30, 50),
		}):Play()
		TweenService:Create(knob, Cfg.Tween, {
			Position = on and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Cfg.TextDim,
		}):Play()
	end
	render()

	function ob:Set(v) ob.State = v and true or false; render(); if o.Callback then task.spawn(o.Callback, ob.State) end end
	track.MouseButton1Click:Connect(function() ob:Set(not ob.State) end)
	if state and o.Callback then task.spawn(o.Callback, true) end
	return ob
end

function Library.Section:AddSlider(o)
	local min, max = o.Min or 0, o.Max or 100
	local dec = o.Decimals or 1
	local val = math.clamp(o.Default or min, min, max)
	local function round(n) local m = 10^dec; return math.floor(n*m+0.5)/m end

	local r = makeRow(self, 52)
	local topRow = New("Frame", { Parent = r, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
	New("TextLabel", {
		Parent = topRow, Size = UDim2.new(1, -64, 1, 0), BackgroundTransparency = 1,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Slider"),
		TextColor3 = Cfg.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local valLbl = New("TextLabel", {
		Parent = topRow, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(60, 20),
		BackgroundTransparency = 1, Font = Cfg.FontBold,
		Text = tostring(round(val)), TextColor3 = Cfg.Text,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
	})
	local track = New("Frame", {
		Parent = r, AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -6), Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = Cfg.Bg, BorderSizePixel = 0,
	})
	corner(track, UDim.new(1, 0))
	local fill = New("Frame", { Parent = track, Size = UDim2.fromScale((val - min) / (max - min), 1), BackgroundColor3 = Cfg.Accent, BorderSizePixel = 0 })
	corner(fill, UDim.new(1, 0))
	local knob = New("Frame", {
		Parent = track, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((val - min) / (max - min), 0, 0.5, 0),
		Size = UDim2.fromOffset(10, 10), BackgroundColor3 = Cfg.Accent, BorderSizePixel = 0, ZIndex = 2,
	})
	corner(knob, UDim.new(1, 0))

	local ob = { Value = val }
	local function apply(a, fire)
		a = math.clamp(a, 0, 1); ob.Value = round(min + (max - min) * a)
		local t = (ob.Value - min) / (max - min)
		fill.Size = UDim2.fromScale(t, 1); knob.Position = UDim2.new(t, 0, 0.5, 0)
		valLbl.Text = tostring(ob.Value)
		if fire and o.Callback then task.spawn(o.Callback, ob.Value) end
	end
	function ob:Set(v) apply((math.clamp(v, min, max) - min) / (max - min), true) end
	local d = false
	local function upd(i) apply((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, true) end
	track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = true; upd(i) end end)
	UserInputService.InputChanged:Connect(function(i) if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i) end end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = false end end)
	return ob
end

function Library.Section:AddDropdown(o)
	local list = o.List or {}
	local selected = o.Default or list[1] or "None"

	local r = makeRow(self, 44)
	New("TextLabel", {
		Parent = r, Size = UDim2.new(1, -110, 1, 0), BackgroundTransparency = 1,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Dropdown"),
		TextColor3 = Cfg.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local valLbl = New("TextButton", {
		Parent = r, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0), Size = UDim2.fromOffset(90, 24),
		BackgroundTransparency = 1, AutoButtonColor = false,
		Font = Cfg.FontBold, Text = string.upper(tostring(selected)),
		TextColor3 = Cfg.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
	})
	local chev = New("TextLabel", {
		Parent = r, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(14, 20),
		BackgroundTransparency = 1, Font = Cfg.FontBold, Text = "V",
		TextColor3 = Cfg.Text, TextSize = 12,
	})

	local menu = New("Frame", { Parent = self.Wrap, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Cfg.Panel, Visible = false, BorderSizePixel = 0 })
	corner(menu, UDim.new(0, 10)); stroke(menu, Cfg.StrokeSoft, 1); padding(menu, 4)
	New("UIListLayout", { Parent = menu, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })

	local ob = { Value = selected }; local open = false
	local function setOpen(s) open = s; menu.Visible = s end
	local function sel(it) ob.Value = it; valLbl.Text = string.upper(tostring(it)); setOpen(false); if o.Callback then task.spawn(o.Callback, it) end end
	for _, it in ipairs(list) do
		local ib = New("TextButton", { Parent = menu, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Cfg.Panel, BackgroundTransparency = 1, AutoButtonColor = false, Font = Cfg.FontBold, Text = string.upper(tostring(it)), TextColor3 = Cfg.TextDim, TextSize = 13 })
		corner(ib, UDim.new(0, 5))
		ib.MouseEnter:Connect(function() TweenService:Create(ib, Cfg.Tween, { BackgroundTransparency = 0, BackgroundColor3 = Cfg.PanelHi, TextColor3 = Cfg.Text }):Play() end)
		ib.MouseLeave:Connect(function() TweenService:Create(ib, Cfg.Tween, { BackgroundTransparency = 1, TextColor3 = Cfg.TextDim }):Play() end)
		ib.MouseButton1Click:Connect(function() sel(it) end)
	end
	valLbl.MouseButton1Click:Connect(function() setOpen(not open) end)
	function ob:Set(it) sel(it) end
	return ob
end

-- =========================================================
-- DEMO — mirrors the Lyzn Hub reference
function Library.Section:AddButton(o)
	local r = makeRow(self, 32)
	local b = New("TextButton", {
		Parent = r, Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Cfg.Panel, BorderSizePixel = 0, AutoButtonColor = false,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Button"),
		TextColor3 = Cfg.Text, TextSize = 14,
	})
	corner(b, UDim.new(0, 8)); stroke(b, Cfg.StrokeSoft, 1)
	New("UIGradient", { Parent = b, Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 20, 40)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 26)),
		})})
	b.MouseEnter:Connect(function() TweenService:Create(b, Cfg.Tween, { BackgroundColor3 = Color3.fromRGB(140, 30, 50) }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, Cfg.Tween, { BackgroundColor3 = Cfg.Panel }):Play() end)
	b.MouseButton1Click:Connect(function() if o.Callback then task.spawn(o.Callback) end end)
	return b
end

function Library.Section:AddLabel(t)
	local r = makeRow(self, 20)
	local lbl = New("TextLabel", {
		Parent = r, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Font = Cfg.FontMed, Text = t, TextColor3 = Cfg.TextDim,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	})
	return { Set = function(_, v) lbl.Text = v end }
end

function Library.Section:AddKeybind(o)
	local r = makeRow(self, Cfg.RowHeight or 30)
	New("TextLabel", {
		Parent = r, Size = UDim2.new(1, -80, 1, 0), BackgroundTransparency = 1,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Keybind"),
		TextColor3 = Cfg.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
	})
	local cur = o.Default
	local btn = New("TextButton", {
		Parent = r, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(74, 24),
		BackgroundColor3 = Color3.fromRGB(14, 12, 22), BorderSizePixel = 0,
		AutoButtonColor = false, Font = Cfg.FontBold,
		Text = cur and cur.Name or "NONE",
		TextColor3 = Cfg.TextDim, TextSize = 12,
	})
	corner(btn, UDim.new(0, 6)); stroke(btn, Color3.fromRGB(80, 30, 50), 1)
	local ob = { Key = cur }; local listening = false; local cn
	btn.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true; btn.Text = "..."; btn.TextColor3 = Cfg.Accent
		cn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			listening = false; cn:Disconnect(); cn = nil
			if input.KeyCode == Enum.KeyCode.Escape then ob.Key = nil; btn.Text = "NONE"
			elseif input.UserInputType == Enum.UserInputType.Keyboard then ob.Key = input.KeyCode; btn.Text = input.KeyCode.Name end
			btn.TextColor3 = Cfg.TextDim
			if o.Callback then task.spawn(o.Callback, ob.Key) end
		end)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or listening or not ob.Key then return end
		if input.KeyCode == ob.Key and o.OnPress then task.spawn(o.OnPress) end
	end)
	function ob:Set(k) ob.Key = k; btn.Text = k and k.Name or "NONE" end
	return ob
end


-- ===== Converted by gemini (gemini-flash-lite-latest) =====

shared._lyzn_stop = true
task.wait(0.2)
if shared._lyzn_cleanup then shared._lyzn_cleanup() end
shared._lyzn_stop = false

pcall(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer
local conns = {}
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local pg = LP:WaitForChild("PlayerGui")
local guiParent
do
    local ok, hui = pcall(gethui)
    if ok and hui then guiParent = hui else guiParent = game:GetService("CoreGui") end
end

pcall(function()
    for _, g in pairs(guiParent:GetChildren()) do
        if g.Name == "\0Lyzn\0" then g:Destroy() end
    end
    for _, g in pairs(pg:GetChildren()) do
        if g.Name == "\0Lyzn\0" then g:Destroy() end
    end
end)

local function safe(fn) return function(...) pcall(fn, ...) end end

local ConnectionManager = {}
ConnectionManager.connections = {}
function ConnectionManager:Add(n, c) if self.connections[n] then self.connections[n]:Disconnect() end; self.connections[n] = c end
function ConnectionManager:Remove(n) if self.connections[n] then self.connections[n]:Disconnect(); self.connections[n] = nil end end
function ConnectionManager:CleanupAll() for _, c in pairs(self.connections) do pcall(function() c:Disconnect() end) end; self.connections = {} end

local character = LP.Character or LP.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local defaultWalkSpeed = humanoid.WalkSpeed
local defaultJumpPower = humanoid.JumpPower

local function onCharAdded(c)
    character = c; humanoid = c:WaitForChild("Humanoid"); hrp = c:WaitForChild("HumanoidRootPart")
    defaultWalkSpeed = humanoid.WalkSpeed; defaultJumpPower = humanoid.JumpPower
end
ConnectionManager:Add("CharAdded", LP.CharacterAdded:Connect(safe(onCharAdded)))

-- ============================================================
-- State
-- ============================================================
local speedEnabled = false
local customSpeed = 25
local flyEnabled = false
local isFlying = false
local flySpeed = 50
local noclipEnabled = false
local jumpPowerEnabled = false
local customJumpPower = 50
local fullbrightEnabled = false
local infEnergyEnabled = false
local infHungerEnabled = false

local highlightESP = false
local boxESP = false
local skeletonESP = false
local tracerESP = false
local nameESP = false
local healthBarESP = false
local espColor = Color3.fromRGB(120, 80, 255)
local espTeamColors = false

local silentAimEnabled = false
local silentAimFOV = 120
local silentAimShowFOV = true
local silentAimTargetPart = "Head"
local silentAimPrediction = 0

-- ============================================================
-- ESP Overlay (Instance-based, for ESP rendering)
-- ============================================================
local espOverlay = Instance.new("ScreenGui")
espOverlay.Name = "LyznESPOverlay"; espOverlay.ResetOnSpawn = false; espOverlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
espOverlay.DisplayOrder = 998; espOverlay.IgnoreGuiInset = true; espOverlay.Parent = guiParent

local fovCircle = Instance.new("Frame", espOverlay)
fovCircle.BackgroundTransparency = 1; fovCircle.AnchorPoint = Vector2.new(0.5, 0.5); fovCircle.Visible = false; fovCircle.BorderSizePixel = 0
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovCircle); fovStroke.Color = Color3.fromRGB(120, 80, 255); fovStroke.Thickness = 1; fovStroke.Transparency = 0.4

local function positionLine(frame, from, to, thickness)
    local dx, dy = to.X - from.X, to.Y - from.Y
    local length = math.sqrt(dx*dx + dy*dy)
    frame.Size = UDim2.new(0, length, 0, thickness)
    frame.Position = UDim2.new(0, (from.X + to.X)/2, 0, (from.Y + to.Y)/2)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Rotation = math.deg(math.atan2(dy, dx))
end

local function makeLine(parent, thickness, color)
    local f = Instance.new("Frame", parent); f.BackgroundColor3 = color or Color3.new(1,1,1)
    f.BorderSizePixel = 0; f.Visible = false; f.AnchorPoint = Vector2.new(0.5, 0.5); f.Size = UDim2.new(0,0,0,thickness)
    return f
end

-- ============================================================
-- Locations
-- ============================================================
local LOCATIONS = {
    {"Trash Sell (Garbage Truck)", Vector3.new(294, 319, 659)},
    {"Gummy Sell", Vector3.new(-542, 2, 11)},
    {"Corner Store", Vector3.new(-489, 318, -131)},
    {"Gas Station", Vector3.new(286, 318, 368)},
    {"Tattoo Shop", Vector3.new(-492, 318, 200)},
    {"Clinic Office", Vector3.new(-260, 318, -402)},
    {"Post Office", Vector3.new(-20, 320, -408)},
    {"Studio", Vector3.new(-1091, 318, -501)},
    {"Guapo NPC", Vector3.new(171, 318, -166)},
    {"Condo", Vector3.new(-870, 317, -90)},
    {"Rooftop", Vector3.new(-979, 454, -119)},
    {"Black Market", Vector3.new(-137, 318, 161)},
    {"ATM (Main)", Vector3.new(-448, 319, -129)},
    {"ATM (Bank)", Vector3.new(-464, 317, -432)},
    {"Freedom Tactical", Vector3.new(277, 315, 365)},
    {"Basketball Court", Vector3.new(-936, 497, -150)},
}

-- ============================================================
-- Core Functions
-- ============================================================
local function teleportTo(pos)
    if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
end

local function startFly()
    if isFlying then return end
    isFlying = true
    if hrp and humanoid then
        humanoid.PlatformStand = true
        ConnectionManager:Add("FlyLoop", RunService.RenderStepped:Connect(safe(function(dt)
            if not flyEnabled or not hrp then return end
            local dir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
            hrp.CFrame = hrp.CFrame + dir * flySpeed * dt
            hrp.Velocity = Vector3.new(0,0,0)
            hrp.RotVelocity = Vector3.new(0,0,0)
        end)))
    end
end

local function stopFly()
    isFlying = false
    ConnectionManager:Remove("FlyLoop")
    if humanoid then humanoid.PlatformStand = false end
end

local originalLighting = {}
local function setFullbright(on)
    local lighting = game:GetService("Lighting")
    if on then
        originalLighting.Ambient = lighting.Ambient; originalLighting.Brightness = lighting.Brightness; originalLighting.FogEnd = lighting.FogEnd
        lighting.Ambient = Color3.fromRGB(255,255,255); lighting.Brightness = 2; lighting.FogEnd = 1e6
        for _, e in pairs(lighting:GetChildren()) do if e:IsA("PostEffect") then e.Enabled = false end end
    else
        if originalLighting.Ambient then lighting.Ambient = originalLighting.Ambient end
        if originalLighting.Brightness then lighting.Brightness = originalLighting.Brightness end
        if originalLighting.FogEnd then lighting.FogEnd = originalLighting.FogEnd end
        for _, e in pairs(lighting:GetChildren()) do if e:IsA("PostEffect") then e.Enabled = true end end
    end
end

-- Noclip
ConnectionManager:Add("NoclipLoop", RunService.Stepped:Connect(safe(function()
    if noclipEnabled and character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)))

-- Speed (CFrame-based to avoid Adonis WalkSpeed detection)
ConnectionManager:Add("SpeedLoop", RunService.RenderStepped:Connect(safe(function(dt)
    if speedEnabled and humanoid and hrp then
        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            local boost = customSpeed - humanoid.WalkSpeed
            if boost > 0 then
                hrp.CFrame = hrp.CFrame + moveDir * boost * dt
            end
        end
    end
end)))

-- Infinite Energy & Hunger
task.spawn(safe(function()
    while not shared._lyzn_stop do
        task.wait(0.5)
        local attrs = LP:FindFirstChild("Settings") and LP.Settings:FindFirstChild("Attributes")
        if attrs then
            if infEnergyEnabled then attrs:SetAttribute("Energy", 100) end
            if infHungerEnabled then attrs:SetAttribute("Hunger", 100) end
        end
    end
end))

-- ============================================================
-- ESP System (Instance-based, no Drawing library)
-- ============================================================
local BONE_CONNECTIONS = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local R6_BONES = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}

local playerDrawings = {}

local function createPlayerESP(player)
    if playerDrawings[player] then return end
    local data = {highlight = nil, skeletonLines = {}, skeletonOutlines = {}}
    data.box = Instance.new("Frame", espOverlay); data.box.BackgroundTransparency = 1; data.box.BorderSizePixel = 0; data.box.Visible = false
    data.boxStroke = Instance.new("UIStroke", data.box); data.boxStroke.Thickness = 1
    data.boxOutline = Instance.new("Frame", espOverlay); data.boxOutline.BackgroundTransparency = 1; data.boxOutline.BorderSizePixel = 0; data.boxOutline.Visible = false
    data.boxOutlineStroke = Instance.new("UIStroke", data.boxOutline); data.boxOutlineStroke.Thickness = 3; data.boxOutlineStroke.Color = Color3.new(0,0,0)
    data.tracer = makeLine(espOverlay, 1, Color3.new(1,1,1))
    data.tracerOutline = makeLine(espOverlay, 3, Color3.new(0,0,0))
    data.nameTag = Instance.new("TextLabel", espOverlay); data.nameTag.BackgroundTransparency = 1; data.nameTag.Size = UDim2.new(0,200,0,16)
    data.nameTag.AnchorPoint = Vector2.new(0.5,0.5); data.nameTag.TextSize = 13; data.nameTag.Font = Enum.Font.FredokaOne
    data.nameTag.TextStrokeTransparency = 0; data.nameTag.TextStrokeColor3 = Color3.new(0,0,0); data.nameTag.Visible = false
    data.healthBarBG = makeLine(espOverlay, 3, Color3.new(0,0,0))
    data.healthBar = makeLine(espOverlay, 1, Color3.new(0,1,0))
    for i = 1, 14 do
        table.insert(data.skeletonOutlines, makeLine(espOverlay, 3, Color3.new(0,0,0)))
        table.insert(data.skeletonLines, makeLine(espOverlay, 1, Color3.new(1,1,1)))
    end
    playerDrawings[player] = data
end

local function removePlayerESP(player)
    local data = playerDrawings[player]; if not data then return end
    pcall(function() data.box:Destroy() end); pcall(function() data.boxOutline:Destroy() end)
    pcall(function() data.tracer:Destroy() end); pcall(function() data.tracerOutline:Destroy() end)
    pcall(function() data.nameTag:Destroy() end)
    pcall(function() data.healthBarBG:Destroy() end); pcall(function() data.healthBar:Destroy() end)
    if data.highlight then pcall(function() data.highlight:Destroy() end) end
    for _, l in pairs(data.skeletonLines) do pcall(function() l:Destroy() end) end
    for _, l in pairs(data.skeletonOutlines) do pcall(function() l:Destroy() end) end
    playerDrawings[player] = nil
end

local function removeAllESP()
    for player in pairs(playerDrawings) do removePlayerESP(player) end
end

local function getESPColor(player)
    if espTeamColors and player.Team then return player.TeamColor.Color end
    return espColor
end

local function worldToScreen(pos)
    local vec, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen, vec.Z
end

local function hideAllData(d)
    d.box.Visible = false; d.boxOutline.Visible = false; d.tracer.Visible = false; d.tracerOutline.Visible = false
    d.nameTag.Visible = false; d.healthBarBG.Visible = false; d.healthBar.Visible = false
    for _, l in pairs(d.skeletonLines) do l.Visible = false end
    for _, l in pairs(d.skeletonOutlines) do l.Visible = false end
end

local function updateAllESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LP then continue end
        local char = player.Character
        if not char then
            if playerDrawings[player] then hideAllData(playerDrawings[player]) end
            continue
        end
        local pHRP = char:FindFirstChild("HumanoidRootPart")
        local pHum = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        if not pHRP or not pHum or not head then continue end
        createPlayerESP(player)
        local data = playerDrawings[player]
        local col = getESPColor(player)
        local _, onScreen, depth = worldToScreen(pHRP.Position)
        if not onScreen or depth < 0 then
            hideAllData(data)
        else
            local headTop = head.Position + Vector3.new(0, head.Size.Y/2 + 0.5, 0)
            local footBottom = pHRP.Position - Vector3.new(0, 3, 0)
            local topSS = worldToScreen(headTop)
            local bottomSS = worldToScreen(footBottom)
            local height = math.abs(bottomSS.Y - topSS.Y)
            local width = height * 0.6
            if boxESP then
                data.boxOutline.Position = UDim2.new(0, topSS.X - width/2, 0, topSS.Y)
                data.boxOutline.Size = UDim2.new(0, width, 0, height); data.boxOutline.Visible = true
                data.box.Position = UDim2.new(0, topSS.X - width/2, 0, topSS.Y)
                data.box.Size = UDim2.new(0, width, 0, height); data.boxStroke.Color = col; data.box.Visible = true
            else data.box.Visible = false; data.boxOutline.Visible = false end
            if tracerESP then
                local from = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                positionLine(data.tracerOutline, from, bottomSS, 3); data.tracerOutline.Visible = true
                positionLine(data.tracer, from, bottomSS, 1); data.tracer.BackgroundColor3 = col; data.tracer.Visible = true
            else data.tracer.Visible = false; data.tracerOutline.Visible = false end
            if nameESP then
                data.nameTag.Position = UDim2.new(0, topSS.X, 0, topSS.Y - 16)
                data.nameTag.Text = player.DisplayName; data.nameTag.TextColor3 = col; data.nameTag.Visible = true
            else data.nameTag.Visible = false end
            if healthBarESP then
                local hp = pHum.Health / pHum.MaxHealth
                local barX = topSS.X - width/2 - 5
                positionLine(data.healthBarBG, Vector2.new(barX, topSS.Y), Vector2.new(barX, bottomSS.Y), 3); data.healthBarBG.Visible = true
                local hpBot = bottomSS.Y - (bottomSS.Y - topSS.Y) * hp
                positionLine(data.healthBar, Vector2.new(barX, hpBot), Vector2.new(barX, bottomSS.Y), 1)
                data.healthBar.BackgroundColor3 = Color3.fromRGB(255*(1-hp), 255*hp, 0); data.healthBar.Visible = true
            else data.healthBarBG.Visible = false; data.healthBar.Visible = false end
            if skeletonESP then
                local bones = char:FindFirstChild("UpperTorso") and BONE_CONNECTIONS or R6_BONES
                for i, bone in ipairs(bones) do
                    local p1 = char:FindFirstChild(bone[1]); local p2 = char:FindFirstChild(bone[2])
                    local sLine = data.skeletonLines[i]; local sOutline = data.skeletonOutlines[i]
                    if sLine and sOutline then
                        if p1 and p2 then
                            local s1 = worldToScreen(p1.Position); local s2 = worldToScreen(p2.Position)
                            positionLine(sOutline, s1, s2, 3); sOutline.Visible = true
                            positionLine(sLine, s1, s2, 1); sLine.BackgroundColor3 = col; sLine.Visible = true
                        else sLine.Visible = false; sOutline.Visible = false end
                    end
                end
                for i = #bones + 1, #data.skeletonLines do
                    if data.skeletonLines[i] then data.skeletonLines[i].Visible = false end
                    if data.skeletonOutlines[i] then data.skeletonOutlines[i].Visible = false end
                end
            else
                for _, l in pairs(data.skeletonLines) do l.Visible = false end
                for _, l in pairs(data.skeletonOutlines) do l.Visible = false end
            end
            if highlightESP then
                if not data.highlight or data.highlight.Parent ~= char then
                    if data.highlight then pcall(function() data.highlight:Destroy() end) end
                    local h = Instance.new("Highlight"); h.Name = "LyznESP"
                    h.FillColor = col; h.OutlineColor = Color3.fromRGB(200, 150, 255)
                    h.FillTransparency = 0.5; h.OutlineTransparency = 0; h.Parent = char; data.highlight = h
                end
            else if data.highlight then data.highlight:Destroy(); data.highlight = nil end end
        end
    end
end

ConnectionManager:Add("ESPRender", RunService.RenderStepped:Connect(safe(function()
    if boxESP or tracerESP or nameESP or healthBarESP or skeletonESP or highlightESP then updateAllESP() end
end)))
ConnectionManager:Add("PlayerLeave", Players.PlayerRemoving:Connect(safe(function(p) removePlayerESP(p) end)))

-- ============================================================
-- Aimlock System
-- ============================================================
local function getClosestPlayerToCursor()
    local closest, closestDist, closestPart = nil, silentAimFOV, nil
    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in pairs(Players:GetPlayers()) do
        if player == LP then continue end
        local char = player.Character
        if not char then continue end
        local pHum = char:FindFirstChildOfClass("Humanoid")
        if not pHum or pHum.Health <= 0 then continue end
        local targetPart = char:FindFirstChild(silentAimTargetPart) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end
        local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end
        local screenPos = Vector2.new(pos.X, pos.Y)
        local dist = (screenPos - mousePos).Magnitude
        if dist < closestDist then closest = player; closestDist = dist; closestPart = targetPart end
    end
    return closestPart
end

local aimlockTarget = nil

ConnectionManager:Add("FOVCircle", RunService.RenderStepped:Connect(safe(function()
    fovCircle.Position = UDim2.new(0, Camera.ViewportSize.X / 2, 0, Camera.ViewportSize.Y / 2)
    fovCircle.Size = UDim2.new(0, silentAimFOV * 2, 0, silentAimFOV * 2)
    fovCircle.Visible = silentAimEnabled and silentAimShowFOV
end)))

ConnectionManager:Add("AimlockLoop", RunService.RenderStepped:Connect(safe(function()
    if not silentAimEnabled then aimlockTarget = nil; return end
    if aimlockTarget then
        local char = aimlockTarget.Parent
        if not char or not char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("Humanoid").Health <= 0 then
            aimlockTarget = nil; return
        end
        local aimPos = aimlockTarget.Position
        if silentAimPrediction > 0 then
            local pHRP = char:FindFirstChild("HumanoidRootPart")
            if pHRP then aimPos = aimPos + pHRP.AssemblyLinearVelocity * silentAimPrediction end
        end
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)
    end
end)))

local aimlockHeld = false
ConnectionManager:Add("AimlockInput", UserInputService.InputBegan:Connect(safe(function(input, gpe)
    if gpe or not silentAimEnabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.Q then
        aimlockHeld = true
        aimlockTarget = getClosestPlayerToCursor()
    end
end)))
ConnectionManager:Add("AimlockRelease", UserInputService.InputEnded:Connect(safe(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.Q then
        aimlockHeld = false
        aimlockTarget = nil
    end
end)))
local mobileAimlockToggled = false

-- ============================================================
-- Cleanup
-- ============================================================
shared._lyzn_cleanup = function()
    shared._lyzn_stop = true
    silentAimEnabled = false
    ConnectionManager:CleanupAll()
    removeAllESP()
    pcall(function() espOverlay:Destroy() end)
    aimlockTarget = nil
    pcall(function() if guiParent:FindFirstChild("\0Lyzn\0") then guiParent:FindFirstChild("\0Lyzn\0"):Destroy() end end)
    pcall(function() if pg:FindFirstChild("\0Lyzn\0") then pg:FindFirstChild("\0Lyzn\0"):Destroy() end end)
    if humanoid then pcall(function() humanoid.PlatformStand = false end) end
    if jumpPowerEnabled and humanoid then pcall(function() humanoid.JumpPower = defaultJumpPower end) end
    if fullbrightEnabled then pcall(function() setFullbright(false) end) end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then local e = p.Character:FindFirstChild("LyznESP"); if e then e:Destroy() end end
    end
    for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
end

LP.CharacterRemoving:Connect(function()
    stopFly()
end)
LP.CharacterAdded:Connect(function(c) task.wait(0.5); onCharAdded(c); if flyEnabled then startFly() end end)

local Window = Library:CreateWindow({ Title = "Lyzn Hub", SubTitle = "Main" })

-- === ESP TAB ===
local VisualsTab = Window:CreateTab("Visuals")

local espSection = VisualsTab:CreateSection("Player ESP", "Left")
espSection:AddToggle({ Text = "Highlight ESP", Default = false, Callback = function(v)
    highlightESP = v
    if not v then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then local e = p.Character:FindFirstChild("LyznESP"); if e then e:Destroy() end end
        end
    end
end })
espSection:AddToggle({ Text = "Box ESP", Default = false, Callback = function(v) boxESP = v end })
espSection:AddToggle({ Text = "Skeleton ESP", Default = false, Callback = function(v) skeletonESP = v end })
espSection:AddToggle({ Text = "Tracers", Default = false, Callback = function(v) tracerESP = v end })
espSection:AddToggle({ Text = "Name Tags", Default = false, Callback = function(v) nameESP = v end })
espSection:AddToggle({ Text = "Health Bars", Default = false, Callback = function(v) healthBarESP = v end })

-- === PLAYER TAB ===
local PlayerTab = Window:CreateTab("Player")

local moveSection = PlayerTab:CreateSection("Movement", "Left")
moveSection:AddToggle({ Text = "Speed Hack", Default = false, Callback = function(v) speedEnabled = v end })
moveSection:AddSlider({ Text = "Walk Speed", Min = 16, Max = 150, Default = 25, Decimals = 0, Callback = function(v) customSpeed = v end })
moveSection:AddToggle({ Text = "Fly", Default = false, Callback = function(v)
    flyEnabled = v; if v then startFly() else stopFly() end
end })
moveSection:AddSlider({ Text = "Fly Speed", Min = 10, Max = 200, Default = 50, Decimals = 0, Callback = function(v) flySpeed = v end })
moveSection:AddToggle({ Text = "Noclip", Default = false, Callback = function(v) noclipEnabled = v end })
moveSection:AddToggle({ Text = "Jump Power", Default = false, Callback = function(v)
    jumpPowerEnabled = v
    if humanoid then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = v and customJumpPower or defaultJumpPower
    end
end })
moveSection:AddSlider({ Text = "Jump Power", Min = 50, Max = 70, Default = 50, Decimals = 0, Callback = function(v) customJumpPower = v end })

local charSection = PlayerTab:CreateSection("Character", "Right")
charSection:AddButton({ Text = "Reset Character", Callback = function()
    if humanoid then humanoid.Health = 0 end
end })

-- === COMBAT TAB ===
local CombatTab = Window:CreateTab("Combat")

local aimSection = CombatTab:CreateSection("Aimlock", "Left")
aimSection:AddToggle({ Text = "Enable Aimlock", Default = false, Callback = function(v) silentAimEnabled = v end })
aimSection:AddToggle({ Text = "Show FOV Circle", Default = true, Callback = function(v) silentAimShowFOV = v end })
aimSection:AddSlider({ Text = "FOV Radius", Min = 30, Max = 500, Default = 120, Decimals = 0, Callback = function(v) silentAimFOV = v end })
aimSection:AddSlider({ Text = "Prediction", Min = 0, Max = 0.3, Default = 0, Decimals = 2, Callback = function(v) silentAimPrediction = v end })
aimSection:AddDropdown({ Text = "Target Part", List = {"Head", "UpperTorso", "HumanoidRootPart"}, Default = "Head", Callback = function(v) silentAimTargetPart = v end })

if isMobile then
    local mobileSection = CombatTab:CreateSection("Mobile", "Right")
    mobileSection:AddButton({ Text = "Lock Nearest Player", Callback = function()
        if not silentAimEnabled then return end
        if mobileAimlockToggled then
            mobileAimlockToggled = false; aimlockTarget = nil
        else
            aimlockTarget = getClosestPlayerToCursor()
            if aimlockTarget then mobileAimlockToggled = true end
        end
    end })
end

-- === TELEPORT TAB ===
local TeleportTab = Window:CreateTab("Teleport")

local locSection = TeleportTab:CreateSection("Locations", "Left")
for _, loc in ipairs(LOCATIONS) do
    locSection:AddButton({ Text = loc[1], Callback = function() teleportTo(loc[2]) end })
end

local playerTPSection = TeleportTab:CreateSection("Players", "Right")
playerTPSection:AddLabel("Click a player to teleport")
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LP then
        playerTPSection:AddButton({ Text = p.DisplayName, Callback = function()
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                teleportTo(p.Character.HumanoidRootPart.Position)
            end
        end })
    end
end

-- === MISC TAB ===
local MiscTab = Window:CreateTab("Misc")

local visualMisc = MiscTab:CreateSection("Visual", "Left")
visualMisc:AddToggle({ Text = "Fullbright", Default = false, Callback = function(v) fullbrightEnabled = v; setFullbright(v) end })

local survivalSection = MiscTab:CreateSection("Survival", "Left")
survivalSection:AddToggle({ Text = "Infinite Energy", Default = false, Callback = function(v) infEnergyEnabled = v end })
survivalSection:AddToggle({ Text = "Infinite Hunger", Default = false, Callback = function(v) infHungerEnabled = v end })

local utilSection = MiscTab:CreateSection("Utilities", "Right")
utilSection:AddToggle({ Text = "Anti-AFK", Default = false, Callback = function(v)
    if v then
        ConnectionManager:Add("AntiAFK", LP.Idled:Connect(function()
            local m = LP:GetMouse()
            if m then pcall(function() m.Hit = m.Hit end) end
        end))
    else ConnectionManager:Remove("AntiAFK") end
end })

end)