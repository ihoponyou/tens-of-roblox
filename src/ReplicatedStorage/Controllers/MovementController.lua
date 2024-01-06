--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local MovementController = Knit.CreateController({
    Name = "MovementController";

    Running = Signal.new()
})

local WALK_SPEED = 8
local RUN_SPEED = 20

function MovementController:KnitInit()
    Players.LocalPlayer.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(character)
    end)
    Players.LocalPlayer.CharacterRemoving:Connect(function(character)
        self:OnCharacterRemoving(character)
    end)
end

function MovementController:OnCharacterAdded(character: Model)
    self.Character = character
    self.Humanoid = character:WaitForChild("Humanoid")
    self._characterTrove = Trove.new()
end

function MovementController:OnCharacterRemoving(character: Model)
    self.Character = nil
    self.Humanoid = nil
    self._characterTrove:Destroy()
end

function MovementController:StartRun()
    if not self.Character then return end

    self.Humanoid.WalkSpeed = RUN_SPEED

    self.Running:Fire(true)
end

function MovementController:StopRun()
    if not self.Character then return end

    self.Humanoid.WalkSpeed = WALK_SPEED

    self.Running:Fire(false)
end

return MovementController
