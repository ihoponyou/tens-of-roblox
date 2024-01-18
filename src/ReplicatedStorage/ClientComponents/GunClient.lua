
-- allows clients to request interaction with melee (server)

local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local ViewmodelController

local EquipmentClient = require(ReplicatedStorage.Source.ClientComponents.EquipmentClient)
local LocalPlayerExclusive = require(ReplicatedStorage.Source.Extensions.LocalPlayerExclusive)
local GunConfig = require(ReplicatedStorage.Source.GunConfig)
local ProjectileCaster = require(ReplicatedStorage.Source.ClientComponents.ProjectileCaster)

local GunClient = Component.new({
    Tag = "Gun";
    Extensions = {
        LocalPlayerExclusive
    };
})

function GunClient:Construct()
    self._trove = Trove.new()
    self._clientComm = self._trove:Construct(Comm.ClientComm, self.Instance, true, "Gun")

    for k, v in GunConfig[self.Instance.Name] do
        self[k] = v
    end

    self.FireEvent = self._clientComm:GetSignal("FireEvent")
    self.FireEvent:Connect(function()
        self:DoEffects()
    end)
end

function GunClient:Start()
    Knit.OnStart():andThen(function()
        ViewmodelController = Knit.GetController("ViewmodelController")
    end, warn):await()

    self.Equipment = self:GetComponent(EquipmentClient)
    self.ProjectileCaster = self:GetComponent(ProjectileCaster)

    self.FireSound = self.Equipment.Folder:FindFirstChild("FireSound") :: Sound?
    if self.FireSound == nil then
        warn(self.Instance.Name, "missing a fire sound")
    end

    local worldModel: Model = self.Equipment.WorldModel
    self.FirePoint = worldModel.PrimaryPart:FindFirstChild("FirePoint") :: Attachment?
    if self.FirePoint == nil then
        error(self.Instance.Name.." missing a fire point")
    end
    self._fireball = self.FirePoint.fireball :: ParticleEmitter
    self._gas = self.FirePoint.gas :: ParticleEmitter
    self._smoke = self.FirePoint.smoke :: ParticleEmitter
    self._flash = self.FirePoint.flash :: PointLight

    self.EjectionPort = worldModel.PrimaryPart:FindFirstChild("EjectionPort") :: Attachment?
    if self.FirePoint == nil then
        warn(self.Instance.Name.." missing an ejection port")
    end

    self.Casing = self.Equipment.Folder:FindFirstChild("Casing") :: BasePart?
    if self.Casing == nil then
        warn(self.Instance.Name.." missing a casing model")
    end
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

    self.ProjectileCaster:UpdateFilter({ Players.LocalPlayer.Character })
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

function GunClient:PlayFireSound()
    if self.FireSound == nil then return end

    local sound: Sound = self.FireSound:Clone()
    sound.Parent = self.Equipment.WorldModel.PrimaryPart
    sound.Ended:Once(function(_soundId)
        sound:Destroy()
    end)
    sound:Play()
end

function GunClient:DoMuzzleFlash()
    self._fireball:Emit()
    self._gas:Emit()

    task.spawn(function()
        self._smoke.Enabled = true
        self._flash.Enabled = true
        task.wait(0.02)
        self._smoke.Enabled = false
        self._flash.Enabled = false
    end)
end

function GunClient:EjectCasing()
	local casingClone = self.Casing:Clone()
	casingClone.Parent = workspace.GunDebris
	casingClone.CFrame = self.EjectionPort.WorldCFrame * CFrame.Angles(0, math.pi/2, 0)
	casingClone.CollisionGroup = "GunDebris"

    -- TODO: add a sound when it hits the ground

    local ejectionCFrame = self.EjectionPort.WorldCFrame
	casingClone.AssemblyLinearVelocity = (
		ejectionCFrame.LookVector * 2 +
		ejectionCFrame.RightVector * 0.2  +
		ejectionCFrame.UpVector
	) * 10
	local rotationMultiplier = 1 + math.random()
	local xRotation = 2*math.pi * rotationMultiplier
	local yRotation = -4*math.pi * rotationMultiplier
	casingClone.AssemblyAngularVelocity = Vector3.new(xRotation, yRotation, 0)

    -- for debugging
	-- task.wait(.1)
	-- casingClone.Anchored = true

    Debris:AddItem(casingClone, 3)
end

function GunClient:DoEffects()
    self:PlayFireSound()
    self:DoMuzzleFlash()
    self:EjectCasing()
end

function GunClient:Shoot()
    self.FireEvent:Fire()

    if self.Equipment.AllowFirstPerson then
        ViewmodelController.Viewmodel.AnimationManager:PlayAnimation("Fire")
    end

    self:DoEffects()

    local cf = workspace.CurrentCamera.CFrame
    self.ProjectileCaster:Cast(cf.Position, cf.LookVector)
end

return GunClient
