
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local CameraController = Knit.CreateController {
	Name = "CameraController";
	
	Distance = 20;
	Locked = false;
	RenderName = "CustomCamRender";
	Priority = Enum.RenderPriority.Camera.Value;

    AdditionalRotation = Vector3.zero;
	
	LockedChanged = Signal.new();
}



function CameraController:LockTo(part)
	if self.Locked then return end
	
	local cam = workspace.CurrentCamera
	self.Locked = true
	cam.CameraType = Enum.CameraType.Watch
	-- Bind to RenderStep:
	RunService:BindToRenderStep(self.RenderName, self.Priority, function()
		cam.CFrame = part.CFrame * CFrame.new(0, 0, self.Distance)
	end)
	
	self.LockedChanged:Fire(true)
end

function CameraController:Unlock()
	if not self.Locked then return end
	
	local cam = workspace.CurrentCamera
	self.Locked = false
	cam.CameraType = Enum.CameraType.Custom
	
	RunService:UnbindFromRenderStep(self.RenderName)
	
	self.LockedChanged:Fire(false)
end

function CameraController:IncrementRotation(degrees: Vector3)
	self.AdditionalRotation += degrees
end



function CameraController:OnKilled()
	print("killed D:")
	workspace.CurrentCamera.CameraSubject = self.Character.Head
end

function CameraController:OnCharacterAdded(character: Model)
	self.Character = character
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	workspace.CurrentCamera.CameraSubject = humanoid
end

local lastIncrement = Vector3.zero
function CameraController:OnRenderStepped(deltaTime: number)
	local cam = workspace.CurrentCamera
	local originalCFrame = cam.CFrame * CFrame.Angles(-math.rad(lastIncrement.X), -math.rad(lastIncrement.Y), -math.rad(lastIncrement.Z))
	cam.CFrame = originalCFrame * CFrame.Angles(math.rad(self.AdditionalRotation.X), math.rad(self.AdditionalRotation.Y), math.rad(self.AdditionalRotation.Z))
	lastIncrement = self.AdditionalRotation
end

function CameraController:KnitInit()
	self._trove = Trove.new()
end

function CameraController:KnitStart()
	if Knit.Player.Character then
		self:OnCharacterAdded(Knit.Player.Character)
	end
	self._trove:Connect(Knit.Player.CharacterAdded, function(...)
		self:OnCharacterAdded(...)
	end)
    self._trove:Connect(RunService.RenderStepped, function(...)
		self:OnRenderStepped(...)
	end)

	game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.UserInputState ~= Enum.UserInputState.Begin then return end
		if input.KeyCode ~= Enum.KeyCode.H then return end
		print("bump")
	end)
end

function CameraController:Destroy()
	self._trove:Destroy()
end

return CameraController
