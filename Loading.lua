local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("CoinHubGui") then
	playerGui.CoinHubGui:Destroy()
end

-- ==========================================
-- CONFIGURAÇÕES PRINCIPAIS
-- ==========================================
local enabled = false
local currentMode = "TP" -- "TP", "TWEEN" ou "FARM_XP"

local tpDelay = 2.0        -- 0.5s até 20s (aba TP)
local tweenSpeed = 16.0    -- até 21 studs/s (aba Tween)

local MAX_COINS_NO_ELITE = 40
local MAX_COINS_ELITE = 50
local ELITE_GAMEPASS_IDS = { 429957 }

local cachedParts = {}
local lastCacheRefresh = 0
local cacheRefreshInterval = 3.5
local activeTween = nil
local afkPlatformPart = nil

-- ==========================================
-- INTERFACE (BOTÃO FLUTUANTE + PAINEL)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinHubGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.DisplayOrder = 100
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local floatBtn = Instance.new("TextButton")
floatBtn.Name = "FloatButton"
floatBtn.Size = UDim2.new(0, 58, 0, 58)
floatBtn.Position = UDim2.new(0.08, 0, 0.35, 0)
floatBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
floatBtn.TextColor3 = Color3.fromRGB(255, 210, 45)
floatBtn.Text = "HUB"
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 13
floatBtn.Active = true
floatBtn.ZIndex = 10
floatBtn.Parent = screenGui

Instance.new("UICorner", floatBtn).CornerRadius = UDim2.new(1, 0)
local floatStroke = Instance.new("UIStroke", floatBtn)
floatStroke.Color = Color3.fromRGB(255, 200, 40)
floatStroke.Thickness = 2

local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.new(0, 268, 0, 224)
panel.Position = UDim2.new(0.08, 70, 0.35, -45)
panel.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
panel.BorderSizePixel = 0
panel.Active = true
panel.Visible = true
panel.ZIndex = 15
panel.Parent = screenGui

Instance.new("UICorner", panel).CornerRadius = UDim2.new(0, 12)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = Color3.fromRGB(60, 65, 85)
panelStroke.Thickness = 1.5

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -16, 0, 24)
titleLabel.Position = UDim2.new(0, 8, 0, 6)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Coin & Murder Hub"
titleLabel.TextColor3 = Color3.fromRGB(240, 242, 248)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 16
titleLabel.Parent = panel

-- ==========================================
-- 3 ÁREAS / ABAS ACIMA DO BOTÃO LIGA/DESLIGA
-- ==========================================
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -16, 0, 30)
tabsFrame.Position = UDim2.new(0, 8, 0, 32)
tabsFrame.BackgroundTransparency = 1
tabsFrame.ZIndex = 16
tabsFrame.Parent = panel

local function makeTab(text, index)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.32, 0, 1, 0)
	btn.Position = UDim2.new((index - 1) * 0.34, 0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(36, 40, 54)
	btn.TextColor3 = Color3.fromRGB(215, 220, 235)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Active = true
	btn.ZIndex = 17
	btn.Parent = tabsFrame
	Instance.new("UICorner", btn).CornerRadius = UDim2.new(0, 7)
	return btn
end

local tabTP = makeTab("TP", 1)
local tabTween = makeTab("Tween", 2)
local tabFarm = makeTab("Farm XP", 3)

local controlArea = Instance.new("Frame")
controlArea.Size = UDim2.new(1, -16, 0, 52)
controlArea.Position = UDim2.new(0, 8, 0, 68)
controlArea.BackgroundColor3 = Color3.fromRGB(29, 32, 42)
controlArea.BorderSizePixel = 0
controlArea.ZIndex = 16
controlArea.Parent = panel
Instance.new("UICorner", controlArea).CornerRadius = UDim2.new(0, 8)

local sliderTitle = Instance.new("TextLabel")
sliderTitle.Size = UDim2.new(1, -12, 0, 20)
sliderTitle.Position = UDim2.new(0, 6, 0, 3)
sliderTitle.BackgroundTransparency = 1
sliderTitle.TextColor3 = Color3.fromRGB(210, 215, 230)
sliderTitle.Font = Enum.Font.GothamMedium
sliderTitle.TextSize = 11
sliderTitle.TextXAlignment = Enum.TextXAlignment.Left
sliderTitle.ZIndex = 17
sliderTitle.Parent = controlArea

local track = Instance.new("Frame")
track.Size = UDim2.new(1, -16, 0, 10)
track.Position = UDim2.new(0, 8, 0, 30)
track.BackgroundColor3 = Color3.fromRGB(50, 55, 72)
track.BorderSizePixel = 0
track.Active = true
track.ZIndex = 17
track.Parent = controlArea
Instance.new("UICorner", track).CornerRadius = UDim2.new(1, 0)

local fill = Instance.new("Frame")
fill.Size = UDim2.new(0.1, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
fill.BorderSizePixel = 0
fill.ZIndex = 18
fill.Parent = track
Instance.new("UICorner", fill).CornerRadius = UDim2.new(1, 0)

local knob = Instance.new("TextButton")
knob.Size = UDim2.new(0, 20, 0, 20)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.new(0.1, 0, 0.5, 0)
knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
knob.Text = ""
knob.Active = true
knob.ZIndex = 19
knob.Parent = track
Instance.new("UICorner", knob).CornerRadius = UDim2.new(1, 0)

local farmInfoLabel = Instance.new("TextLabel")
farmInfoLabel.Size = UDim2.new(1, -12, 1, -6)
farmInfoLabel.Position = UDim2.new(0, 6, 0, 3)
farmInfoLabel.BackgroundTransparency = 1
farmInfoLabel.TextColor3 = Color3.fromRGB(185, 205, 230)
farmInfoLabel.Font = Enum.Font.Gotham
farmInfoLabel.TextSize = 10
farmInfoLabel.TextWrapped = true
farmInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
farmInfoLabel.TextYAlignment = Enum.TextYAlignment.Center
farmInfoLabel.Text = "Inocente: Coins + AFK alto | Xerife: Atira no Murder | Murder: TP em quem tem faca (vivo)"
farmInfoLabel.ZIndex = 17
farmInfoLabel.Visible = false
farmInfoLabel.Parent = controlArea

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.new(1, -16, 0, 36)
toggleBtn.Position = UDim2.new(0, 8, 0, 128)
toggleBtn.BackgroundColor3 = Color3.fromRGB(175, 45, 55)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Text = "DESLIGADO"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.Active = true
toggleBtn.ZIndex = 17
toggleBtn.Parent = panel
Instance.new("UICorner", toggleBtn).CornerRadius = UDim2.new(0, 8)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, 42)
statusLabel.Position = UDim2.new(0, 8, 0, 172)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Pronto"
statusLabel.TextColor3 = Color3.fromRGB(165, 172, 192)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.ZIndex = 16
statusLabel.Parent = panel

-- ==========================================
-- CONTROLE DE SLIDER (PAUSA 0.5-20s OU VELOCIDADE <=21)
-- ==========================================
local draggingSlider = false

local function refreshSliderVisual()
	if currentMode == "TP" then
		sliderTitle.Visible = true
		track.Visible = true
		farmInfoLabel.Visible = false

		local alpha = math.clamp((tpDelay - 0.5) / (20.0 - 0.5), 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		sliderTitle.Text = string.format("Pausa TP: %.1fs (0.5s - 20s)", tpDelay)
	elseif currentMode == "TWEEN" then
		sliderTitle.Visible = true
		track.Visible = true
		farmInfoLabel.Visible = false

		local alpha = math.clamp(tweenSpeed / 21.0, 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		sliderTitle.Text = string.format("Velocidade Tween: %.1f / 21", tweenSpeed)
	else
		sliderTitle.Visible = false
		track.Visible = false
		farmInfoLabel.Visible = true
	end
end

local function updateSliderFromX(xPos)
	local absX = track.AbsolutePosition.X
	local absW = track.AbsoluteSize.X
	if absW <= 0 then return end
	local alpha = math.clamp((xPos - absX) / absW, 0, 1)

	if currentMode == "TP" then
		local raw = 0.5 + (20.0 - 0.5) * alpha
		tpDelay = math.floor(raw * 10 + 0.5) / 10
	elseif currentMode == "TWEEN" then
		local raw = 1.0 + (21.0 - 1.0) * alpha
		tweenSpeed = math.min(21.0, math.floor(raw * 10 + 0.5) / 10)
	end
	refreshSliderVisual()
end

local function setMode(mode)
	currentMode = mode
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end

	local activeColor = Color3.fromRGB(65, 130, 245)
	local idleColor = Color3.fromRGB(36, 40, 54)

	tabTP.BackgroundColor3 = (mode == "TP") and activeColor or idleColor
	tabTween.BackgroundColor3 = (mode == "TWEEN") and activeColor or idleColor
	tabFarm.BackgroundColor3 = (mode == "FARM_XP") and activeColor or idleColor

	refreshSliderVisual()
	statusLabel.Text = "Status: Modo alterado para " .. mode
end

tabTP.MouseButton1Click:Connect(function() setMode("TP") end)
tabTween.MouseButton1Click:Connect(function() setMode("TWEEN") end)
tabFarm.MouseButton1Click:Connect(function() setMode("FARM_XP") end)
setMode("TP")

knob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
	end
end)

track.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
		updateSliderFromX(input.Position.X)
	end
end)

-- ==========================================
-- ABRIR/FECHAR PAINEL E ARRASTAR BOTÃO FLUTUANTE
-- ==========================================
local function positionPanelNearButton()
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local btnPos = floatBtn.AbsolutePosition
	local btnSize = floatBtn.AbsoluteSize
	local panelW = panel.AbsoluteSize.X
	local panelH = panel.AbsoluteSize.Y

	local targetX = btnPos.X + btnSize.X + 10
	if targetX + panelW > viewport.X - 10 then
		targetX = math.max(10, btnPos.X - panelW - 10)
	end

	local targetY = math.clamp(btnPos.Y - 40, 10, math.max(10, viewport.Y - panelH - 10))
	panel.Position = UDim2.fromOffset(targetX, targetY)
end

local draggingFloat = false
local wasDragged = false
local dragStartPos, floatStartPos

floatBtn.MouseButton1Click:Connect(function()
	if wasDragged then
		wasDragged = false
		return
	end
	panel.Visible = not panel.Visible
	if panel.Visible then
		positionPanelNearButton()
	end
end)

floatBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingFloat = true
		wasDragged = false
		dragStartPos = input.Position
		floatStartPos = floatBtn.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateSliderFromX(input.Position.X)
	elseif draggingFloat and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStartPos
		if delta.Magnitude > 8 then
			wasDragged = true
			floatBtn.Position = UDim2.new(
				floatStartPos.X.Scale,
				floatStartPos.X.Offset + delta.X,
				floatStartPos.Y.Scale,
				floatStartPos.Y.Offset + delta.Y
			)
			if panel.Visible then
				positionPanelNearButton()
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = false
		draggingFloat = false
	end
end)

toggleBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	if not enabled and activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
	if enabled then
		toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 165, 90)
		toggleBtn.Text = "LIGADO"
		statusLabel.Text = "Status: Executando (" .. currentMode .. ")..."
	else
		toggleBtn.BackgroundColor3 = Color3.fromRGB(175, 45, 55)
		toggleBtn.Text = "DESLIGADO"
		statusLabel.Text = "Status: Pausado"
	end
end)

-- ==========================================
-- ELITE / CONTAGEM DE MOEDAS / AUTO-RESET
-- ==========================================
local function hasElitePass()
	for _, gpId in ipairs(ELITE_GAMEPASS_IDS) do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gpId)
		end)
		if ok and owns then
			return true
		end
	end
	return false
end

local function getMaxCoins()
	return hasElitePass() and MAX_COINS_ELITE or MAX_COINS_NO_ELITE
end

local function getCurrentCoinsCount()
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		for _, stat in ipairs(ls:GetChildren()) do
			local n = string.lower(stat.Name)
			if string.find(n, "coin") or string.find(n, "bag") or string.find(n, "moeda") then
				if tonumber(stat.Value) then
					return tonumber(stat.Value)
				end
			end
		end
	end

	local bagAttr = player:GetAttribute("Coins") or player:GetAttribute("Bag")
	if tonumber(bagAttr) then
		return tonumber(bagAttr)
	end

	for _, obj in ipairs(playerGui:GetDescendants()) do
		if obj:IsA("TextLabel") and not obj:IsDescendantOf(screenGui) then
			local parentName = string.lower(obj.Parent and obj.Parent.Name or "")
			local objName = string.lower(obj.Name)
			if string.find(parentName, "coin") or string.find(parentName, "bag") or string.find(objName, "coin") or string.find(objName, "bag") then
				local num = tonumber(string.match(obj.Text, "%d+"))
				if num then
					return num
				end
			end
		end
	end

	return nil
end

local function checkAndResetIfBagFull()
	local maxCoins = getMaxCoins()
	local currentCoins = getCurrentCoinsCount()
	if currentCoins and currentCoins >= maxCoins then
		statusLabel.Text = string.format("Bag cheia (%d/%d)! Resetando...", currentCoins, maxCoins)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = 0
		end
		task.wait(2.5)
		return true
	end
	return false
end

-- ==========================================
-- BUSCA DE COINS ("coin" + filtro de tamanho < 25)
-- ==========================================
local function collectPartsFromCoin(obj, targetList, seen, character)
	if character and obj:IsDescendantOf(character) then return end

	if obj:IsA("BasePart") then
		if not seen[obj] and obj.Size.Magnitude < 25 then
			seen[obj] = true
			table.insert(targetList, obj)
		end
	elseif obj:IsA("Model") then
		for _, child in ipairs(obj:GetDescendants()) do
			if child:IsA("BasePart") and not seen[child] and child.Size.Magnitude < 25 then
				seen[child] = true
				table.insert(targetList, child)
			end
		end
	end
end

local function refreshCoinCache(character)
	local newCache = {}
	local seen = {}

	local container = workspace:FindFirstChild("Coins") or workspace:FindFirstChild("CoinFolder") or workspace
	local items = (container ~= workspace) and container:GetChildren() or workspace:GetDescendants()

	for _, item in ipairs(items) do
		if string.find(string.lower(item.Name), "coin") then
			collectPartsFromCoin(item, newCache, seen, character)
		end
	end

	cachedParts = newCache
end

local function findNearestCoinPart(originPos, character)
	local now = os.clock()
	if #cachedParts == 0 or (now - lastCacheRefresh) >= cacheRefreshInterval then
		lastCacheRefresh = now
		refreshCoinCache(character)
	end

	local nearestPart = nil
	local shortestDist = math.huge

	for i = #cachedParts, 1, -1 do
		local part = cachedParts[i]
		if not part or not part:IsDescendantOf(workspace) then
			table.remove(cachedParts, i)
		else
			local dist = (part.Position - originPos).Magnitude
			if dist < shortestDist then
				shortestDist = dist
				nearestPart = part
			end
		end
	end

	return nearestPart, shortestDist
end

-- ==========================================
-- MOVIMENTO: TP E TWEEN (EMBAIXO DA COIN)
-- ==========================================
local function teleportBelowPart(character, rootPart, part)
	local destCFrame = CFrame.new(part.Position - Vector3.new(0, 3.2, 0))
	pcall(function() character:PivotTo(destCFrame) end)
	pcall(function()
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		rootPart.CFrame = destCFrame
	end)
end

local function tweenBelowPart(rootPart, part)
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end

	local speed = math.clamp(tweenSpeed, 1, 21)
	local targetPos = part.Position - Vector3.new(0, 3.2, 0)
	local dist = (targetPos - rootPart.Position).Magnitude
	local duration = math.max(0.05, dist / speed)

	local info = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tw = TweenService:Create(rootPart, info, { CFrame = CFrame.new(targetPos) })
	activeTween = tw

	local finished = false
	tw.Completed:Connect(function()
		finished = true
	end)

	tw:Play()
	while not finished and enabled and currentMode == "TWEEN" and part:IsDescendantOf(workspace) do
		task.wait(0.05)
	end

	if not finished then
		tw:Cancel()
	end
	if activeTween == tw then
		activeTween = nil
	end
end

-- ==========================================
-- FARM XP: PAPÉIS (INOCENTE, XERIFE, MURDER)
-- ==========================================
local function isPlayerAlive(plr)
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return hum and hum.Health > 0 and hrp ~= nil
end

local function hasKnifeEquipped(plr)
	local char = plr.Character
	if not char then return false end
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") then
			local n = string.lower(item.Name)
			if string.find(n, "knife") or string.find(n, "faca") or string.find(n, "blade") then
				return true
			end
		end
	end
	return false
end

local function hasGunEquipped(plr)
	local char = plr.Character
	local bp = plr:FindFirstChildOfClass("Backpack")
	local function checkContainer(c)
		if not c then return false end
		for _, item in ipairs(c:GetChildren()) do
			if item:IsA("Tool") then
				local n = string.lower(item.Name)
				if string.find(n, "gun") or string.find(n, "revolver") or string.find(n, "pistol") or string.find(n, "arma") then
					return item
				end
			end
		end
		return nil
	end
	return checkContainer(char) or checkContainer(bp)
end

local function detectRole()
	local char = player.Character
	local bp = player:FindFirstChildOfClass("Backpack")
	if char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and (string.find(string.lower(t.Name), "knife") or string.find(string.lower(t.Name), "faca")) then
				return "MURDER"
			end
		end
	end
	if bp then
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and (string.find(string.lower(t.Name), "knife") or string.find(string.lower(t.Name), "faca")) then
				return "MURDER"
			end
		end
	end

	if hasGunEquipped(player) then
		return "SHERIFF"
	end

	local roleAttr = player:GetAttribute("Role") or player:GetAttribute("Team")
	if type(roleAttr) == "string" then
		local r = string.lower(roleAttr)
		if string.find(r, "murd") or string.find(r, "assass") then return "MURDER" end
		if string.find(r, "sher") or string.find(r, "xerif") then return "SHERIFF" end
	end

	return "INNOCENT"
end

local function findMurderPlayer()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and isPlayerAlive(plr) and hasKnifeEquipped(plr) then
			return plr
		end
	end
	return nil
end

local function shootAtMurder(character, rootPart)
	local murder = findMurderPlayer()
	if not murder or not murder.Character then
		statusLabel.Text = "XP Xerife: Aguardando Murder com faca..."
		return
	end

	local mHrp = murder.Character:FindFirstChild("HumanoidRootPart")
	if not mHrp then return end

	rootPart.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(mHrp.Position.X, rootPart.Position.Y, mHrp.Position.Z))

	local gun = hasGunEquipped(player)
	if gun and gun.Parent == player:FindFirstChildOfClass("Backpack") and character:FindFirstChildOfClass("Humanoid") then
		character:FindFirstChildOfClass("Humanoid"):EquipTool(gun)
		task.wait(0.1)
	end

	if gun then
		pcall(function() gun:Activate() end)
		for _, rem in ipairs(gun:GetDescendants()) do
			if rem:IsA("RemoteEvent") then
				pcall(function() rem:FireServer(mHrp.Position, mHrp) end)
			end
		end
	end

	for _, rem in ipairs(ReplicatedStorage:GetDescendants()) do
		if rem:IsA("RemoteEvent") then
			local n = string.lower(rem.Name)
			if string.find(n, "shoot") or string.find(n, "fire") or string.find(n, "gun") or string.find(n, "tiro") then
				pcall(function() rem:FireServer(mHrp.Position, mHrp) end)
			end
		end
	end

	statusLabel.Text = "XP Xerife: Atirando em " .. murder.Name .. "!"
end

local function goToHighSkyPlatform(character, rootPart)
	if not afkPlatformPart or not afkPlatformPart.Parent then
		local plat = Instance.new("Part")
		plat.Name = "SkyAfkPlatform_Hub"
		plat.Size = Vector3.new(24, 2, 24)
		plat.Anchored = true
		plat.CanCollide = true
		plat.Transparency = 0.35
		plat.Material = Enum.Material.SmoothPlastic
		plat.Position = Vector3.new(0, 650, 0)
		plat.Parent = workspace
		afkPlatformPart = plat
	end

	local skyPos = afkPlatformPart.Position + Vector3.new(0, 4, 0)
	local dest = CFrame.new(skyPos)
	pcall(function() character:PivotTo(dest) end)
	pcall(function()
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		rootPart.CFrame = dest
	end)
end

local function murderHuntKnifeHolders(character, rootPart)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and isPlayerAlive(plr) and hasKnifeEquipped(plr) then
			local targetHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if targetHrp then
				local dest = targetHrp.CFrame * CFrame.new(0, 0, -2.2)
				pcall(function() character:PivotTo(dest) end)
				pcall(function() rootPart.CFrame = dest end)
				statusLabel.Text = "XP Murder: TP em " .. plr.Name .. " (com faca)"
				return true
			end
		end
	end
	statusLabel.Text = "XP Murder: Nenhum jogador vivo com faca"
	return false
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================
task.spawn(function()
	while true do
		if enabled then
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")

			if character and rootPart then
				if currentMode == "TP" then
					if not checkAndResetIfBagFull() then
						local coinPart, dist = findNearestCoinPart(rootPart.Position, character)
						if coinPart then
							teleportBelowPart(character, rootPart, coinPart)
							statusLabel.Text = string.format("TP: %s (%.0f studs) | %.1fs", coinPart.Name, dist, tpDelay)
						else
							statusLabel.Text = "TP: Nenhuma coin encontrada."
						end
					end
					task.wait(tpDelay)

				elseif currentMode == "TWEEN" then
					if not checkAndResetIfBagFull() then
						local coinPart, dist = findNearestCoinPart(rootPart.Position, character)
						if coinPart then
							statusLabel.Text = string.format("Tween (vel %.1f): %s (%.0f)", tweenSpeed, coinPart.Name, dist)
							tweenBelowPart(rootPart, coinPart)
						else
							statusLabel.Text = "Tween: Nenhuma coin encontrada."
							task.wait(0.5)
						end
					else
						task.wait(1)
					end

				elseif currentMode == "FARM_XP" then
					local role = detectRole()

					if role == "MURDER" then
						murderHuntKnifeHolders(character, rootPart)
						task.wait(0.6)
					else
						local coinPart, dist = findNearestCoinPart(rootPart.Position, character)
						if coinPart then
							teleportBelowPart(character, rootPart, coinPart)
							statusLabel.Text = string.format("XP [%s]: Pegando %s (%.0f)", role, coinPart.Name, dist)
							task.wait(0.5)
						else
							if role == "SHERIFF" then
								shootAtMurder(character, rootPart)
								task.wait(0.7)
							else
								goToHighSkyPlatform(character, rootPart)
								statusLabel.Text = "XP [Inocente]: Coins coletadas, AFK no céu!"
								task.wait(1.5)
							end
						end
					end
				end
			else
				statusLabel.Text = "Aguardando personagem..."
				task.wait(0.5)
			end
		else
			task.wait(0.25)
		end
	end
end)
