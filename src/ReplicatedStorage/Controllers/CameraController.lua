
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local CameraController = Knit.CreateController({
    Name = "CameraController",

    InFirstPerson = true,
    PointOfViewChanged = Signal.new(),

    AllowFirstPerson = true,
    AllowFirstPersonChanged = Signal.new(),

    InCutscene = false,

    _playerModule = nil,
})

function CameraController:KnitInit()
    self._playerModule = require(Knit.Player.PlayerScripts:WaitForChild("PlayerModule"))

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        if input.KeyCode == Enum.KeyCode.V then
            self:TogglePointOfView()
        end
    end)

    self.AllowFirstPersonChanged:Connect(function()
        if self.InFirstPerson and not self.AllowFirstPerson then
            self:TogglePointOfView(false)
        end
    end)
end

function CameraController:KnitStart()
    self:TogglePointOfView(self.InFirstPerson)
end

function CameraController:TogglePointOfView(firstPerson: boolean?)
    local enterFirstPerson = if firstPerson == nil then not self.InFirstPerson else firstPerson

    if not self.AllowFirstPerson and enterFirstPerson then return end

    -- print(self.InFirstPerson, "->", enterFirstPerson)

    self.InFirstPerson = enterFirstPerson

    if enterFirstPerson then
		Knit.Player.CameraMinZoomDistance = 0.5
		Knit.Player.CameraMaxZoomDistance = 0.5
	else
		Knit.Player.CameraMaxZoomDistance = 12
		Knit.Player.CameraMinZoomDistance = 4
	end

    self._playerModule:ToggleShiftLock(not enterFirstPerson)
    self.PointOfViewChanged:Fire(self.InFirstPerson)
end

function CameraController:SetAllowFirstPerson(bool: boolean)
    self.AllowFirstPerson = bool
    self.AllowFirstPersonChanged:Fire(bool)
end

return CameraController
