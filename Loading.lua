local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local TARGET_TOOL_NAME = "Broom26"
local flySpeed = 30
local EQUIP_GRACE_SECONDS = 0.65

local flying = false
local activeBroomTrack = nil
local currentTool = nil
local lastEquipTime = 0

local flyConn = nil
local animPlayedConn = nil
local animStoppedConn = nil
local bodyVel = nil
local bodyGyro = nil

local speedInput = nil

local function stopFly()
	flying = false
	activeBroomTrack = nil

	if animStoppedConn then
		animStoppedConn:Disconnect()
		animStoppedConn = nil
	end
	if flyConn then
		flyConn:Disconnect()
		flyConn = nil
	end
	if bodyVel then
		bodyVel:Destroy()
		bodyVel = nil
	end
	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
	end
end

local function isBroomEquipped()
	local char = player.Character
	return currentTool ~= nil and char ~= nil and currentTool.Parent == char
end

local function startFly()
	if flying or not isBroomEquipped() then return end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	flying = true
	hum.PlatformStand = false

	bodyVel = Instance.new("BodyVelocity")
	bodyVel.Name = "BroomFlyVelocity"
	bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bodyVel.P = 1250
	bodyVel.Velocity = Vector3.zero
	bodyVel.Parent = root

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.Name = "BroomFlyGyro"
	bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	bodyGyro.P = 3000
	bodyGyro.D = 200
	bodyGyro.CFrame = root.CFrame
	bodyGyro.Parent = root

	flyConn = RunService.RenderStepped:Connect(function()
		local charNow = player.Character
		if not flying or not currentTool or not charNow or currentTool.Parent ~= charNow or not root.Parent then
			stopFly()
			return
		end

		local cam = workspace.CurrentCamera
		local moveDir = hum.MoveDirection

		local velocity = Vector3.zero

		if moveDir.Magnitude > 0 then
			local look = cam.CFrame.LookVector
			local right = cam.CFrame.RightVector

			local flatLook = Vector3.new(look.X, 0, look.Z)
			if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end

			local flatRight = Vector3.new(right.X, 0, right.Z)
			if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end

			local forwardAmount = moveDir:Dot(flatLook)
			local rightAmount = moveDir:Dot(flatRight)

			local moveVec = (flatLook * forwardAmount) + (flatRight * rightAmount)

			if math.abs(forwardAmount) > 0.05 then
				moveVec += Vector3.new(0, look.Y * forwardAmount, 0)
			end

			if moveVec.Magnitude > 0 then
				velocity = moveVec.Unit * flySpeed
			end
		end

		bodyVel.Velocity = velocity

		local targetLook = Vector3.new(
			root.Position.X + cam.CFrame.LookVector.X,
			root.Position.Y + cam.CFrame.LookVector.Y,
			root.Position.Z + cam.CFrame.LookVector.Z
		)
		bodyGyro.CFrame = CFrame.lookAt(root.Position, targetLook)
	end)
end

local function bindTrackStop(track)
	if animStoppedConn then
		animStoppedConn:Disconnect()
		animStoppedConn = nil
	end

	animStoppedConn = track.Stopped:Connect(function()
		if activeBroomTrack == track then
			activeBroomTrack = nil
			stopFly()
		end
	end)
end

local function bindAnimator(char)
	if animPlayedConn then
		animPlayedConn:Disconnect()
		animPlayedConn = nil
	end

	local hum = char:WaitForChild("Humanoid", 10)
	local animator = hum and hum:WaitForChild("Animator", 10)
	if not animator then return end

	animPlayedConn = animator.AnimationPlayed:Connect(function(track)
		if not isBroomEquipped() then return end
		if not track or track.Priority == Enum.AnimationPriority.Core then return end
		if (os.clock() - lastEquipTime) < EQUIP_GRACE_SECONDS then return end

		activeBroomTrack = track
		bindTrackStop(track)

		if not flying then
			startFly()
		end
	end)
end

local function checkCharacterTools(char)
	if not char then return end

	local foundBroom = nil
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") and child.Name == TARGET_TOOL_NAME then
			foundBroom = child
			break
		end
	end

	if foundBroom then
		if foundBroom ~= currentTool then
			lastEquipTime = os.clock()
			currentTool = foundBroom
			stopFly()
		end
	else
		currentTool = nil
		stopFly()
	end
end

local function createUI()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return end

	local old = playerGui:FindFirstChild("Broom26FlyHud")
	if old then
		old:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Broom26FlyHud"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	-- Botão flutuante marrom com emoji de vassoura
	local broomBtn = Instance.new("TextButton")
	broomBtn.Name = "BroomButton"
	broomBtn.Size = UDim2.new(0, 48, 0, 48)
	broomBtn.Position = UDim2.new(0.86, 0, 0.22, 0)
	broomBtn.BackgroundColor3 = Color3.fromRGB(110, 62, 30)
	broomBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	broomBtn.Text = "🧹"
	broomBtn.TextScaled = true
	broomBtn.Font = Enum.Font.GothamBold
	broomBtn.Active = true
	broomBtn.Draggable = true
	broomBtn.Parent = screenGui

	local broomCorner = Instance.new("UICorner")
	broomCorner.CornerRadius = UDim.new(1, 0)
	broomCorner.Parent = broomBtn

	local panel = Instance.new("Frame")
	panel.Name = "SpeedPanel"
	panel.Size = UDim2.new(0, 250, 0, 145)
	panel.Position = UDim2.new(0.5, -125, 0.32, 0)
	panel.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	panel.BackgroundTransparency = 0.08
	panel.Visible = false
	panel.Active = true
	panel.Draggable = true
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0, 24)
	title.Position = UDim2.new(0, 8, 0, 6)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(214, 142, 82)
	title.Text = "🧹 Vassoura Voadora"
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = panel

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, -24, 0, 32)
	input.Position = UDim2.new(0, 12, 0, 34)
	input.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
	input.TextColor3 = Color3.fromRGB(255, 255, 255)
	input.PlaceholderText = "Digite a velocidade (ex: 30)"
	input.Text = tostring(flySpeed)
	input.TextScaled = true
	input.Font = Enum.Font.GothamBold
	input.ClearTextOnFocus = false
	input.Parent = panel
	speedInput = input

	local warning = Instance.new("TextLabel")
	warning.Size = UDim2.new(1, -16, 0, 62)
	warning.Position = UDim2.new(0, 8, 0, 72)
	warning.BackgroundTransparency = 1
	warning.TextColor3 = Color3.fromRGB(255, 110, 110)
	warning.TextWrapped = true
	warning.TextScaled = true
	warning.Font = Enum.Font.GothamMedium
	warning.Text = "Aviso: velocidades altas podem resultar em ser expulso (kick) ou banido do jogo com mais facilidade."
	warning.Parent = panel

	local function applySpeedText()
		local parsed = tonumber(input.Text)
		if parsed and parsed > 0 then
			flySpeed = math.clamp(parsed, 1, 300)
			input.Text = tostring(flySpeed)
		else
			input.Text = tostring(flySpeed)
		end
	end

	input.FocusLost:Connect(applySpeedText)

	broomBtn.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			input.Text = tostring(flySpeed)
		end
	end)
end

local function watchCharacter(char)
	createUI()
	stopFly()
	bindAnimator(char)
	checkCharacterTools(char)

	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == TARGET_TOOL_NAME then
			checkCharacterTools(char)
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name == TARGET_TOOL_NAME then
			checkCharacterTools(char)
		end
	end)
end

createUI()

if player.Character then
	watchCharacter(player.Character)
end

player.CharacterAdded:Connect(watchCharacter)
