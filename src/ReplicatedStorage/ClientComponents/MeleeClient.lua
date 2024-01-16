
-- allows clients to request interaction with melee (server)

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local ViewmodelController

local EquipmentClient = require(ReplicatedStorage.Source.ClientComponents.EquipmentClient)
local LocalPlayerExclusive = require(ReplicatedStorage.Source.Extensions.LocalPlayerExclusive)

local MeleeClient = Component.new({
    Tag = "Melee";
    Extensions = {
        LocalPlayerExclusive
    };
})

function MeleeClient:Construct()
    self._trove = Trove.new()
    self._clientComm = self._trove:Construct(Comm.ClientComm, self.Instance, true, "Melee")

    self.AttackRequest = self._clientComm:GetSignal("AttackRequest")
end

function MeleeClient:Start()
    Knit.OnStart():andThen(function()
        ViewmodelController = Knit.GetController("ViewmodelController")
    end, warn):await()

    self.Equipment = self:GetComponent(EquipmentClient)

    self._trove:Connect(self.AttackRequest, function(combo)
        if self.Equipment.Config.AllowFirstPerson then
            -- print(combo)
            ViewmodelController.Viewmodel.AnimationManager:PlayAnimation("Attack"..tostring(combo+1))
        end
    end)
end

function MeleeClient:_setupForLocalPlayer()
    self._localPlayerTrove = self._trove:Extend()

    self._localPlayerTrove:Add(self.Equipment.IsEquipped:Observe(function(isEquipped: boolean)
        if isEquipped then
            self:_onEquipped()
        else
            self:_onUnequipped()
        end
    end))
end

function MeleeClient:_cleanUpForLocalPlayer()
    if self._localPlayerTrove then
        self._localPlayerTrove:Destroy()
    end
end

function MeleeClient:_onEquipped()
    ContextActionService:BindAction(self.Instance.Name.."Attack", function(_, uis, _)
        if uis ~= Enum.UserInputState.Begin then return end
        if not self.Equipment.IsEquipped:Get() then return end
        self.AttackRequest:Fire()
     end, false, Enum.UserInputType.MouseButton1)
end

function MeleeClient:_onUnequipped()
    ContextActionService:UnbindAction(self.Instance.Name.."Attack")
end

return MeleeClient
