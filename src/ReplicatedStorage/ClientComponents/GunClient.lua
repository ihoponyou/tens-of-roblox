local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Logger = require(script.Parent.Extensions.Logger)

local ViewmodelClient

local GunClient = Component.new({
	Tag = "Gun",
	Extensions = {
		Logger,
	},
})

function GunClient:Construct()
	self._trove = Trove.new()

	self._primaryDown = false

	-- the clientside gun component refers to the 3rd person gun model
	-- BUT it reuses it in viewmodel so that visual/sound effects replicate
	-- also, since this is all clientside, the serverside version of the model actually stays
	-- in the character's hands; thus 3rd person animations work
	self.Model = self.Instance:WaitForChild("GunModel")
	for _,v in self.Model:GetDescendants() do
		if v:IsA("BasePart") then
			local trans = v.Transparency
			v.LocalTransparencyModifier = 1
			v.Transparency = trans
		end
	end

	self.MouseEvent = self.Instance:WaitForChild("MouseEvent")
	self.RecoilEvent = self.Instance:WaitForChild("RecoilEvent")
	self.AimEvent = self.Instance:WaitForChild("AimEvent")
	self.EquipEvent = self.Instance:WaitForChild("EquipEvent")

	self.Config = ReplicatedStorage.Weapons[self.Instance.Name].Configuration
end

function GunClient:UpdateMouseIcon()
	if self.Mouse and not self.Instance.Parent:IsA("Backpack") then
		self.Mouse.Icon = "rbxasset://textures/GunCursor.png"
	end
end

function GunClient:Aim(bool: boolean)
	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)
	self.Aiming = if bool == nil then not self.Aiming else bool
	self.AimEvent:FireServer(self.Aiming)
	-- print("aiming:", self.Aiming)

	local adsSpeed = 0.5

	UserInputService.MouseIconEnabled = not self.Aiming

	-- local tweeningInformation =
	-- 	TweenInfo.new(if self.Aiming then adsSpeed else adsSpeed / 2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	-- local properties = { Value = if self.Aiming then 1 else 0 }

	-- TweenService:Create(viewmodel.LerpValues.Aiming, tweeningInformation, properties):Play()
end

function GunClient:_handleAimInput(actionName: string, userInputState: Enum.UserInputState, inputObject: InputObject)
	if userInputState == Enum.UserInputState.Cancel then return Enum.ContextActionResult.Pass end
	self:Aim(userInputState == Enum.UserInputState.Begin)
	return Enum.ContextActionResult.Sink
end

function GunClient:_handleFireInput(actionName: string, userInputState: Enum.UserInputState, inputObject: InputObject)
	self._primaryDown = userInputState == Enum.UserInputState.Begin
end

function GunClient:_equip(mouse: Mouse)
	-- print(self.Instance.Parent, "equipped", self.Instance.Name)

	local viewmodel = workspace.CurrentCamera:WaitForChild("Viewmodel")
	self.Model.Parent = viewmodel
	self.Model.PrimaryPart.RootJoint.Part0 = viewmodel["Right Arm"]

	local viewmodelComponent = ViewmodelClient:FromInstance(viewmodel)
	viewmodelComponent:ToggleVisibility(true)
	viewmodelComponent:LoadAnimations(ReplicatedStorage.Weapons[self.Instance.Name].Animations["1P"])
	viewmodelComponent:PlayAnimation("Idle")

	self.RecoilSpring = Spring.new(Vector3.new(0, 0, 0))
	self.RecoilSpring.Speed = 10
	self.RecoilSpring.Damper = 1
	self._lastOffset = Vector3.new()

	self.Mouse = mouse
	self:UpdateMouseIcon()

	ContextActionService:BindAction("aim" .. self.Instance.Name, function(...)
		self:_handleAimInput(...)
	end, true, Enum.UserInputType.MouseButton2)

	ContextActionService:BindAction("fire" .. self.Instance.Name, function(...)
		self:_handleFireInput(...)
	end, true, Enum.UserInputType.MouseButton1)

	RunService:BindToRenderStep("GunClientOnRenderStepped", Enum.RenderPriority.Camera.Value, function(...)
		self:OnRenderStepped(...)
	end)
end

function GunClient:_unequip()
	local viewmodel = workspace.CurrentCamera:WaitForChild("Viewmodel")
	local viewmodelComponent = ViewmodelClient:FromInstance(viewmodel)
	viewmodelComponent:ToggleVisibility(false)

	ContextActionService:UnbindAction("aim" .. self.Instance.Name)
	RunService:UnbindFromRenderStep("GunClientOnRenderStepped")

	self._primaryDown = false
	self:UpdateMouseIcon()
end

-- use remote event to prevent race condition while giving gun to viewmodel
function GunClient:OnEquipEvent(equipped: boolean)
	if equipped then
		self:_equip()
	else
		self:_unequip()
	end
end

function GunClient:OnRecoilEvent(verticalKick: number, horizontalKick: number)
	self.RecoilSpring:Impulse(Vector3.new(verticalKick * 5, horizontalKick * 5, 0))

	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)

	viewmodel.Animations.Fire:Play()
	for _, v in viewmodel.Instance.Receiver.FirePoint:GetChildren() do
		task.spawn(function()
			if v:IsA("ParticleEmitter") then
				v.Enabled = true
				task.delay(.05, function()
					v.Enabled = false
					v.Transparency = NumberSequence.new(1)
				end)
			elseif v:IsA("PointLight") then
				v.Enabled = true
				task.delay(.05, function()
					v.Enabled = false
				end)
			end
		end)
	end
end

function GunClient:OnDeactivated()
	--print(self.Instance.Parent, "deactivated", self.Instance.Name)
	self._primaryDown = false
end

function GunClient:OnStepped(deltaTime: number)
	if self._primaryDown then
		self.MouseEvent:FireServer(workspace.CurrentCamera.CFrame.LookVector)
	end
end

local function toRoundedString(number: number): string
	local num = math.round(number)
	return tostring(num)
end

function GunClient:OnRenderStepped(deltaTime: number)
	local currentOffset = self.RecoilSpring.Position
	-- self.RecoilIndicator.Text = ("curr: "..toRoundedString(self.RecoilSpring.Position.X).."\n".."last: "..toRoundedString(self._lastOffset.X))
	workspace.CurrentCamera.CFrame *= CFrame.Angles(
		math.rad(currentOffset.X - self._lastOffset.X),
		math.rad(currentOffset.Y - self._lastOffset.Y),
		0
	)
	self._lastOffset = self.RecoilSpring.Position
end

function GunClient:Start()
	ViewmodelClient = require(script.Parent.ViewmodelClient)
	-- CameraController = Knit.GetController("CameraController")

	self._trove:Connect(self.RecoilEvent.OnClientEvent, function(...) self:OnRecoilEvent(...) end)
	self._trove:Connect(self.EquipEvent.OnClientEvent, function(...) self:OnEquipEvent(...) end)

	self._trove:Connect(self.Instance.Activated, function(...) self:OnActivated(...) end)
	self._trove:Connect(self.Instance.Deactivated, function(...) self:OnDeactivated(...) end)

	self._trove:Connect(RunService.Stepped, function(...) self:OnStepped(...) end)
end

function GunClient:Stop()
	self._trove:Destroy()
end

return GunClient
