--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MovementController

local AnimationManager = require(ReplicatedStorage.Source.Modules.AnimationManager)

local CHARACTER_ANIMATIONS = ReplicatedStorage.Character.Animations:GetChildren()

local AnimationController = Knit.CreateController({
    Name = "AnimationController";
})

function AnimationController:KnitInit()
    Players.LocalPlayer.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(character)
    end)
    Players.LocalPlayer.CharacterRemoving:Connect(function(character)
        self:OnCharacterRemoving(character)
    end)
end

function AnimationController:KnitStart()
    MovementController = Knit.GetController("MovementController")

    -- MovementController.Running:Connect(function(isRunning: boolean)
    --     if isRunning then
    --         self.AnimationManager:StopAnimation("Walk")
    --         self.AnimationManager:PlayAnimation("Run")
    --     else
    --         self.AnimationManager:StopAnimation("Run")
    --         self.AnimationManager:PlayAnimation("Walk")
    --     end
    -- end)
end

function AnimationController:OnCharacterAdded(character: Model)
    self.Character = character
    local humanoid = character:WaitForChild("Humanoid")
    self.Animator = humanoid:WaitForChild("Animator")
    self.AnimationManager = AnimationManager.new(self.Animator)

    self.AnimationManager:LoadAnimations(CHARACTER_ANIMATIONS)
end

function AnimationController:OnCharacterRemoving(_)
    self.AnimationManager:Destroy()
end

return AnimationController
