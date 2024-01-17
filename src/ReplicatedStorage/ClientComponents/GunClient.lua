
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

local GunClient = Component.new({
    Tag = "Gun";
    Extensions = {
        LocalPlayerExclusive
    };
})

function GunClient:Construct()
    self._trove = Trove.new()
    self._clientComm = self._trove:Construct(Comm.ClientComm, self.Instance, true, "Gun")
end

function GunClient:Start()
    Knit.OnStart():andThen(function()
        ViewmodelController = Knit.GetController("ViewmodelController")
    end, warn):await()

    self.Equipment = self:GetComponent(EquipmentClient)
end

function GunClient:_setupForLocalPlayer()
    self._localPlayerTrove = self._trove:Extend()

    self._localPlayerTrove:Add(self.Equipment.IsEquipped:Observe(function(isEquipped: boolean)
        if isEquipped then
            self:_onEquipped()
        else
            self:_onUnequipped()
        end
    end))
end

function GunClient:_cleanUpForLocalPlayer()
    if self._localPlayerTrove then
        self._localPlayerTrove:Destroy()
    end
end

function GunClient:_onEquipped()
    ContextActionService:BindAction(self.Instance.Name.."Shoot", function(_, uis, _)
        if uis ~= Enum.UserInputState.Begin then return end
        if not self.Equipment.IsEquipped:Get() then return end
        self:Shoot()
     end, false, Enum.UserInputType.MouseButton1)
end

function GunClient:_onUnequipped()
    ContextActionService:UnbindAction(self.Instance.Name.."Shoot")
end

function GunClient:Shoot()
    if self.Equipment.AllowFirstPerson then
        ViewmodelController.Viewmodel.AnimationManager:PlayAnimation("Fire")
    end
end

return GunClient
