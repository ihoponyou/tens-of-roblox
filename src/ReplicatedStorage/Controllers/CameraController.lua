
-- basically copy pasted from sleitnicks knit api cameracontroller

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local OffsetManager = require(ReplicatedStorage.Source.Modules.OffsetManager)
local PlayerModule = require(Knit.Player.PlayerScripts:WaitForChild("PlayerModule"))

local CameraController = Knit.CreateController {
	Name = "CameraController";

	Distance = 20;
	Sensitivity = 1;
	FieldOfView = 90;
	Locked = false;
	RenderName = "CustomCamRender";
	Priority = Enum.RenderPriority.Camera.Value;

	OffsetManager = OffsetManager.new();
	_lastOffset = CFrame.new();

	LockedChanged = Signal.new();

	-- shift lock doesnt show initially if player starts in third person
	InFirstPerson = true;
	AllowFirstPerson = true;
	FirstPersonChanged = Signal.new();

	ShiftLocked = false;
	ForceShiftLock = false;
}

function CameraController:KnitInit()
	self._trove = Trove.new()
end

function CameraController:KnitStart()
	self._trove:Connect(RunService.RenderStepped, function(_)
		self:OnRenderStepped()
	end)

	workspace.CurrentCamera.FieldOfView = self.FieldOfView

	self:TogglePOV(self.InFirstPerson)
end

function CameraController:Destroy()
	self._trove:Destroy()
end

function CameraController:OnCharacterAdded(character: Model)
	self.Character = character
end

function CameraController:TogglePOV(enterFirstPerson: boolean?)
	local inFirstPerson = if enterFirstPerson == nil then not self.InFirstPerson else enterFirstPerson
	if inFirstPerson and not self.AllowFirstPerson then return end
	local localPlayer = Knit.Player

	if inFirstPerson then
		localPlayer.CameraMinZoomDistance = 0.5
		localPlayer.CameraMaxZoomDistance = 0.5
	else
		localPlayer.CameraMaxZoomDistance = 8
		localPlayer.CameraMinZoomDistance = 4
	end

	self.InFirstPerson = inFirstPerson
	self.FirstPersonChanged:Fire(inFirstPerson)
end

function CameraController:OnRenderStepped(_)
	if not self.AllowFirstPerson and self.InFirstPerson then
		self:TogglePOV(false)
	end
	if self.ForceShiftLock and not self.ShiftLocked then
		self:ToggleShiftLock(true)
	end

	local camera = workspace.CurrentCamera
	local combinedOffset = self.OffsetManager:GetCombinedOffset()

	camera.CFrame = camera.CFrame * combinedOffset * self._lastOffset:Inverse()

	self._lastOffset = combinedOffset
end

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

function CameraController:ToggleShiftLock(lock: boolean)
	self.ShiftLocked = lock
	PlayerModule:ToggleShiftLock(lock)
end

return CameraController
