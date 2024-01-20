
-- allows clients to request interaction with melee (server)

local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Spring = require(ReplicatedStorage.Packages.Spring)

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
    self._canFire = true
    self._firing = false
    self._triggerDown = false

    self._trove = Trove.new()
    self._clientComm = self._trove:Construct(Comm.ClientComm, self.Instance, true, "Gun")

    for k, v in GunConfig[self.Instance.Name] do
        self[k] = v
    end

    self.FireEvent = self._clientComm:GetSignal("FireEvent")
    self.FireEvent:Connect(function(origin, direction)
        -- server telling us to replicate a shot
        self:Shoot(origin, direction, true)
    end)

    self.HitEvent = self._clientComm:GetSignal("HitEvent")

    self.CameraSpring = Spring.new(Vector3.zero)
    -- TODO: make these depend on gun handling
    self.CameraSpring.Speed = self.SpringScales.Camera.Speed
    self.CameraSpring.Damper = self.SpringScales.Camera.Damper

    self.ViewmodelSpring = Spring.new(Vector3.zero)
    self.ViewmodelSpring.Speed = self.SpringScales.Animation.Speed
    self.ViewmodelSpring.Damper = self.SpringScales.Animation.Damper

    self._lastOffset = CFrame.new()
end

function GunClient:Start()
    Knit.OnStart():andThen(function()
        ViewmodelController = Knit.GetController("ViewmodelController")
    end, warn):await()

    self.Equipment = self:GetComponent(EquipmentClient)
    self.ProjectileCaster = self:GetComponent(ProjectileCaster)

    self.ProjectileCaster.OnRayHit = function(raycastResult: RaycastResult)
        self.HitEvent:Fire(raycastResult.Instance)
    end

    self.FireSound = self.Equipment.Folder:FindFirstChild("FireSound") :: Sound?
    if self.FireSound == nil then warn(self.Instance.Name, "missing a fire sound") end

    local worldModel: Model = self.Equipment.WorldModel
    self.FirePoint = worldModel.PrimaryPart:FindFirstChild("FirePoint") :: Attachment?
    if self.FirePoint == nil then error(self.Instance.Name.." missing a fire point") end
    self._fireball = self.FirePoint.fireball :: ParticleEmitter
    self._gas = self.FirePoint.gas :: ParticleEmitter
    self._smoke = self.FirePoint.smoke :: ParticleEmitter
    self._flash = self.FirePoint.flash :: PointLight

    self.EjectionPort = worldModel.PrimaryPart:FindFirstChild("EjectionPort") :: Attachment?
    if self.FirePoint == nil then warn(self.Instance.Name.." missing an ejection port") end

    self.Casing = self.Equipment.Folder:FindFirstChild("Casing") :: BasePart?
    if self.Casing == nil then warn(self.Instance.Name.." missing a casing model") end
end

function GunClient:Stop()
    self._trove:Destroy()
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

function GunClient:HandleTriggerInput()
    if not self._triggerDown then return end
    if not self._canFire then return end
    if not self.Equipment.IsEquipped:Get() then return end

    local cf = workspace.CurrentCamera.CFrame
    self:Shoot(cf.Position, cf.LookVector)
end

function GunClient:UpdateRecoilOffsets()
    local recoilSpringPosition = self.CameraSpring.Position
    local cameraScales = self.SpringScales.Camera
    local cameraOffset = CFrame.fromOrientation(
        recoilSpringPosition.Y * cameraScales.Rotation.X,
        recoilSpringPosition.X * cameraScales.Rotation.Y,
        0
    )

    workspace.CurrentCamera.CFrame *= (cameraOffset * self._lastOffset:Inverse())

    local animationSpringPosition = self.ViewmodelSpring.Position
    local animationScales = self.SpringScales.Animation
    local viewmodelPosition = Vector3.new(
        animationSpringPosition.X * animationScales.Position.X,
        animationSpringPosition.Y * animationScales.Position.Y,
        animationSpringPosition.Y * animationScales.Position.Z
    )
    local viewmodelOrientation = {
        animationSpringPosition.Y * animationScales.Rotation.X,
        animationSpringPosition.X * animationScales.Rotation.Y,
        0 * animationScales.Rotation.Z
    }
    local viewmodelOffset = CFrame.new(viewmodelPosition) * CFrame.fromOrientation(table.unpack(viewmodelOrientation))

    ViewmodelController.Viewmodel.OffsetManager:SetOffsetValue(self.Instance.Name.."Recoil", viewmodelOffset)

    self._lastOffset = cameraOffset
end

function GunClient:_onEquipped()
    self._canFire = false

    ContextActionService:BindAction(self.Instance.Name.."Shoot",
        function(_, uis, _)
            self._triggerDown = uis == Enum.UserInputState.Begin
        end,
        false, Enum.UserInputType.MouseButton1)

    self._readyThread = task.delay(self.DeployTime, function()
        self._canFire = true
        self._readyThread = nil
    end)

    ViewmodelController.Viewmodel.OffsetManager:AddOffset(self.Instance.Name.."Recoil", CFrame.new(), 1)

    RunService:BindToRenderStep(self.Instance.Name.."Recoil", Enum.RenderPriority.Last.Value, function(_dt) self:UpdateRecoilOffsets() end)
    RunService:BindToRenderStep(self.Instance.Name.."TriggerInput", Enum.RenderPriority.Input.Value, function(_dt) self:HandleTriggerInput() end)
end

function GunClient:_onUnequipped()
    self._canFire = false

    ContextActionService:UnbindAction(self.Instance.Name.."Shoot")

    if self._readyThread then
        -- print("cancel")
        task.cancel(self._readyThread)
        self._readyThread = nil
    end

    if self._fireRateThread then
        task.cancel(self._fireRateThread)
        self._fireRateThread = nil
    end

    RunService:UnbindFromRenderStep(self.Instance.Name.."Recoil")
    RunService:UnbindFromRenderStep(self.Instance.Name.."TriggerInput")
    -- prevent camera from resetting to "center" when re equipped
    self._lastOffset = CFrame.new()
    ViewmodelController.Viewmodel.OffsetManager:RemoveOffset(self.Instance.Name.."Recoil")
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

function GunClient:DoCameraRecoil()
    local recoil = Vector3.new(self.HorizontalRecoil * math.random(-1, 1), self.VerticalRecoil, 0)
    self.CameraSpring:Impulse(recoil)
    self.ViewmodelSpring:Impulse(recoil)
end

function GunClient:Shoot(origin: Vector3, direction: Vector3, replicated: boolean?)
    self:PlayFireSound()
    self:DoMuzzleFlash()
    self:EjectCasing()

    self.ProjectileCaster:Cast(origin, direction)

    if replicated then return end

    self._canFire = false

    self:DoCameraRecoil()

    if not self.FullAuto then
        self._triggerDown = false
    end

    self.FireEvent:Fire(origin, direction)

    if self.Equipment.AllowFirstPerson then
        ViewmodelController.Viewmodel.AnimationManager:PlayAnimation("Fire")
    end

    self._fireRateThread = task.delay(60/self.RoundsPerMinute, function()
        self._canFire = true
    end)
end

return GunClient
