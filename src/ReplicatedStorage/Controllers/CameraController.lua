
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

    AppliedOffsets = {};
	_lastOffset = CFrame.new();

	LockedChanged = Signal.new();
}



function CameraController:LockTo(part)
	if self.Locked then return end

	local cam = workspace.CurrentCamera
	self.Locked = true
	cam.CameraType = Enum.CameraType.Watch

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

function CameraController:ApplyOffset(name: string, offset: CFrame, alpha: number)
	if type(name) ~= "string" then error("Invalid offset name") end
	if typeof(offset) ~= "CFrame" then error("Invalid offset value") end

	self.AppliedOffsets[name] = {
		Value = offset,
		Alpha = 0
	}

	self:SetOffsetAlpha(name, alpha)
end

function CameraController:UpdateOffset(name: string, offset: CFrame)
	if type(name) ~= "string" then error("Invalid offset name") end
	if typeof(offset) ~= "CFrame" then error("Invalid offset value") end
	local appliedOffset = self.AppliedOffsets[name]
	if not appliedOffset then error("No offset to update") end
	appliedOffset.Value = offset
end

-- removes an offset from the AppliedOffsets table if the offset exists; otherwise does nothing
function CameraController:RemoveOffset(name: string)
	if type(name) ~= "string" then error("Invalid offset name") end
	self.AppliedOffsets[name] = nil
end

-- sets the alpha of an applied offset
function CameraController:SetOffsetAlpha(name: string, alpha: number)
	local offset: Offset = self.AppliedOffsets[name]
	if not offset then error("no offset found with name: "..name) end
	if type(alpha) ~= "number" then error("Invalid offset alpha") end
	if alpha < 0 or alpha > 1 then error("Offset alpha outside of range [0, 1]: "..alpha) end
	offset.Alpha = alpha
end

function CameraController:OnCharacterAdded(character: Model)
	self.Character = character
	-- local humanoid: Humanoid = character:WaitForChild("Humanoid")
	-- workspace.CurrentCamera.CameraSubject = humanoid
end

function CameraController:KnitInit()
	self._trove = Trove.new()
end

function CameraController:OnRenderStepped()
	local finalOffset = CFrame.new()
	for _, v: Offset in self.AppliedOffsets do
		finalOffset = finalOffset:Lerp((finalOffset * v.Value), v.Alpha)
	end
	workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * finalOffset * self._lastOffset:Inverse()
	self._lastOffset = finalOffset
end

function CameraController:KnitStart()
	print("started")
	if Knit.Player.Character then
		self:OnCharacterAdded(Knit.Player.Character)
	end
	self._trove:Connect(Knit.Player.CharacterAdded, function(...)
		self:OnCharacterAdded(...)
	end)

	self._trove:Connect(RunService.RenderStepped, function(_)
		self:OnRenderStepped()
	end)
end

function CameraController:Destroy()
	self._trove:Destroy()
end

return CameraController
