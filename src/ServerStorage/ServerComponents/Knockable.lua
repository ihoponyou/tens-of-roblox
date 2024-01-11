
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local Respawnable = require(ServerStorage.Source.ServerComponents.Respawnable)

local Knockable = Component.new({
	Tag = "Knockable",
	Extensions = {
		Logger,
	},
})

local KNOCK_THRESHOLD = 0
local RECOVER_THRESHOLD = 0.10
local BLEED_OUT_TIME = 5

function Knockable:Construct()
    self.IsKnocked = false

    self._trove = Trove.new()

    self.Knocked = Signal.new()

	self.Humanoid = self.Instance:FindFirstChildOfClass("Humanoid") :: Humanoid
    self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
end

function Knockable:SetKnocked(isKnocked: boolean)
    self.IsKnocked = isKnocked
    self.Instance:SetAttribute("Ragdolled", isKnocked)
    self.Instance:SetAttribute("Knocked", isKnocked)
    self.Humanoid:UnequipTools() -- TODO: replace this

    if isKnocked then
        -- TODO: reviving

        self._bleedOutThread = task.delay(BLEED_OUT_TIME, function()
            self._bleedOutThread = nil

            if self.Respawnable ~= nil then
                self.Respawnable:Respawn()
            else
                local player = Players:GetPlayerFromCharacter(self.Instance)
                if player then
                    player:LoadCharacter()
                else
                    self.Instance:Destroy()
                end
            end
        end)
    else
        if self._bleedOutThread then
            task.cancel(self._bleedOutThread)
        end
    end

    self.Knocked:Fire(isKnocked)
end

function Knockable:Start()
    self.Respawnable = self:GetComponent(Respawnable)

    self._trove:Connect(self.Humanoid.HealthChanged, function(health: number)
        if self.IsKnocked and health > (self.Humanoid.MaxHealth * RECOVER_THRESHOLD) then
            self:SetKnocked(false)
            return
        elseif health > (self.Humanoid.MaxHealth * KNOCK_THRESHOLD) then
            return
        end

        self:SetKnocked(true)
    end)
end

return Knockable
