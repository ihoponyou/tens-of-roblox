
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local Knockable = Component.new({
	Tag = "Knockable",
	Extensions = {
		Logger,
	},
})

local KNOCK_THRESHOLD = 0
local RECOVER_THRESHOLD = 0.10

function Knockable:Construct()
    self.IsKnocked = false

    self._trove = Trove.new()

    self.Knocked = Signal.new()
    self._trove:Connect(self.Knocked, function(isKnocked: boolean)
        self:_onKnockedChanged(isKnocked)
    end)

    local h: Humanoid = self.Instance:FindFirstChildOfClass("Humanoid") -- for intellisense
	self.Humanoid = h
    self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
end

function Knockable:_onKnockedChanged(isKnocked: boolean)
    self.IsKnocked = isKnocked
    self.Instance:SetAttribute("Ragdolled", isKnocked)
    self.Humanoid:UnequipTools() -- TODO: replace this
end

function Knockable:Start()
    self._trove:Connect(self.Humanoid.HealthChanged, function(health: number)
        if self.IsKnocked and health > self.Humanoid.MaxHealth * RECOVER_THRESHOLD then
            self.Knocked:Fire(false)
        elseif health > KNOCK_THRESHOLD then return end

        self.Knocked:Fire(true)
    end)
end

return Knockable
