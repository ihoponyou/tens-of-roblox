
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local CameraController = Knit.CreateController {
	Name = "CameraController";

	Distance = 20;
	Sensitivity = 1;
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

function CameraController:KnitInit()
	-- workspace.CurrentCamera:GetPropertyChangedSignal("CameraType"):Connect(function()
	-- 	print(workspace.CurrentCamera.CameraType)
	-- 	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	-- end)
	-- workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	self._lastIncrement = Vector3.zero

	self._trove = Trove.new()
end

function CameraController:KnitStart()
	if Knit.Player.Character then
		self:OnCharacterAdded(Knit.Player.Character)
	end
	self._trove:Connect(Knit.Player.CharacterAdded, function(...)
		self:OnCharacterAdded(...)
	end)
end

function CameraController:Destroy()
	self._trove:Destroy()
end

return CameraController
