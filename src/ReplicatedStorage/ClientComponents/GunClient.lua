
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
local CameraController

local EquipmentClient = require(ReplicatedStorage.Source.ClientComponents.EquipmentClient)
local LocalPlayerExclusive = require(ReplicatedStorage.Source.Extensions.LocalPlayerExclusive)
local GunConfig = require(ReplicatedStorage.Source.GunConfig)
local ProjectileCaster = require(ReplicatedStorage.Source.ClientComponents.ProjectileCaster)
local Find = require(ReplicatedStorage.Source.Modules.Find)

local GunClient = Component.new({
    Tag = "Gun";
    Extensions = {
        LocalPlayerExclusive
    };
})

local RAND = Random.new()
local TAU = math.pi * 2

function GunClient:Construct()
    -- self.Instance:SetAttribute("Log", true)

    self._firing = false
    self._triggerDown = false

    self._trove = Trove.new()
    self._clientComm = self._trove:Construct(Comm.ClientComm, self.Instance, true, "Gun")

    for k, v in GunConfig[self.Instance.Name] do
        self[k] = v
    end

    -- time between shots
    self._fireDelay = 60/self.RoundsPerMinute
    -- self._delayAccumulator = 0

    self._canFire = false
    self.CanFire = self._clientComm:GetProperty("CanFire")

    self.CurrentAmmo = 0
    self.UpdateCurrentAmmo = self._clientComm:GetSignal("UpdateCurrentAmmo")
    self._trove:Connect(self.UpdateCurrentAmmo, function(newAmount: number)
        self.CurrentAmmo = newAmount
    end)

    self.ReserveAmmo = 0
    self.UpdateReserveAmmo = self._clientComm:GetSignal("UpdateReserveAmmo")
    self._trove:Connect(self.UpdateReserveAmmo, function(newAmount: number)
        self.ReserveAmmo = newAmount
    end)

    self.ReloadEvent = self._clientComm:GetSignal("ReloadEvent")
    self.ReloadEvent:Connect(function()
        if self.AllowFirstPerson then
            ViewmodelController.Viewmodel.AnimationManager:PlayAnimation("Reload")
        end
    end)

    self.FireEvent = self._clientComm:GetSignal("FireEvent")
    self.FireEvent:Connect(function(origin, direction)
        -- server telling us to replicate a shot
        self:Shoot(origin, direction, true)
    end)

    self.HitEvent = self._clientComm:GetSignal("HitEvent")

    self:_resetSprings()
end

function GunClient:Start()
    Knit.OnStart():andThen(function()
        ViewmodelController = Knit.GetController("ViewmodelController")
	CameraController = Knit.GetController("CameraController")
    end, warn):await()

    self.Equipment = self:GetComponent(EquipmentClient)

    self.Magazine = self.Equipment.WorldModel:FindFirstChild("Magazine") :: BasePart?

    self.FireSound = Find.path(self.Equipment.Folder, "FireSound") :: Sound

    local worldModel: Model = self.Equipment.WorldModel
    self.FirePoint = Find.path(worldModel.PrimaryPart, "FirePoint") :: Attachment
    self._fireball = self.FirePoint.fireball :: ParticleEmitter
    self._gas = self.FirePoint.gas :: ParticleEmitter
    self._smoke = self.FirePoint.smoke :: ParticleEmitter
    self._flash = self.FirePoint.flash :: PointLight

    self.EjectionPort = Find.path(worldModel.PrimaryPart, "EjectionPort") :: Attachment

    self.Casing = Find.path(self.Equipment.Folder, "Casing") :: BasePart

    self.ProjectileCaster = self:GetComponent(ProjectileCaster)

    self.ProjectileCaster.OnRayHit = function(raycastResult: RaycastResult, segmentVelocity: Vector3)
        self.HitEvent:Fire(raycastResult.Instance, segmentVelocity)
    end
end

function GunClient:Stop()
    self._trove:Destroy()
end

function GunClient:_setupForLocalPlayer()
    self._localPlayerTrove = self._trove:Extend()

    self._localPlayerTrove:Connect(self.Equipment.ClientEquipped, function(isEquipped: boolean)
        if isEquipped then
            self:_onEquipped()
        else
            self:_onUnequipped()
        end
    end)

    self.ProjectileCaster:UpdateFilter({ Players.LocalPlayer.Character })
end

function GunClient:_cleanUpForLocalPlayer()
    if self._localPlayerTrove then
        self._localPlayerTrove:Destroy()
    end
end

function GunClient:_resetSprings()
    self.CameraSpring = Spring.new(Vector3.zero)
    self.CameraSpring.Speed = self.SpringScales.Camera.Speed
    self.CameraSpring.Damper = self.SpringScales.Camera.Damper

    self.ViewmodelSpring = Spring.new(Vector3.zero)
    self.ViewmodelSpring.Speed = self.SpringScales.Animation.Speed
    self.ViewmodelSpring.Damper = self.SpringScales.Animation.Damper

    self._lastOffset = CFrame.new()
end

function GunClient:HandleTriggerInput(deltaTime: number)
    if not self._triggerDown then return end
    if not self._canFire then return end
    if self.CurrentAmmo == 0 then return end
    if not self.Equipment.IsEquipped:Get() then return end
    if not self.CanFire:Get() then return end

    if not self.FullAuto then
        self._triggerDown = false
    end

    local origin, direction
    local cameraCFrame = workspace.CurrentCamera.CFrame
    if CameraController.InFirstPerson then
        origin = cameraCFrame.Position
        direction = cameraCFrame.LookVector
    else
        origin = self.FirePoint.WorldPosition

        local castParams = RaycastParams.new()
        castParams.FilterDescendantsInstances = { self.Equipment.WorldModel.Parent }
        castParams.FilterType = Enum.RaycastFilterType.Exclude
        local forwardCast = workspace:Raycast(cameraCFrame.Position, cameraCFrame.LookVector * 1000, castParams)

        if forwardCast ~= nil then
            direction = forwardCast.Position - origin
        else
            direction = cameraCFrame.LookVector
        end
    end

    self:Shoot(origin, direction)
end

function GunClient:UpdateRecoilOffsets()
    local recoilSpringPosition = self.CameraSpring.Position
    local cameraScales = self.SpringScales.Camera
    local cameraOffset = CFrame.fromOrientation(
        recoilSpringPosition.Y * cameraScales.Rotation.X,
        recoilSpringPosition.X * cameraScales.Rotation.Y,
        0)

    workspace.CurrentCamera.CFrame *= (cameraOffset * self._lastOffset:Inverse())

    local animationSpringPosition = self.ViewmodelSpring.Position
    local animationScales = self.SpringScales.Animation
    local viewmodelPosition = Vector3.new(
        animationSpringPosition.X * animationScales.Position.X,
        animationSpringPosition.Y * animationScales.Position.Y,
        animationSpringPosition.Y * animationScales.Position.Z)
    local viewmodelOrientation = {
        animationSpringPosition.Y * animationScales.Rotation.X,
        animationSpringPosition.X * animationScales.Rotation.Y,
        0 * animationScales.Rotation.Z}
    local viewmodelOffset = CFrame.new(viewmodelPosition) * CFrame.fromOrientation(table.unpack(viewmodelOrientation))

    ViewmodelController.Viewmodel.OffsetManager:SetOffsetValue(self.Instance.Name.."Recoil", viewmodelOffset)

    self._lastOffset = cameraOffset
end

function GunClient:_setupAnimationEvents()
    local animationManager = ViewmodelController.Viewmodel.AnimationManager

    local reloadTrack: AnimationTrack = animationManager:GetAnimation("Reload")

    if self.Magazine == nil then return end
    self._magOutConn = self._trove:Connect(reloadTrack:GetMarkerReachedSignal("out"), function()
        local magazineClone = self.Magazine:Clone()
        magazineClone.Parent = workspace.GunDebris
        magazineClone.CFrame = self.Magazine.CFrame
        magazineClone.AssemblyLinearVelocity = Vector3.zero -- TODO: inherit character velocity?
        magazineClone.CollisionGroup = "GunDebris"
        magazineClone.CanCollide = true
        magazineClone.Transparency = 0
        -- magazineClone.Anchored = true

        Debris:AddItem(magazineClone, 5)
    end)
end

function GunClient:_cleanupAnimationEvents()
    self._trove:Remove(self._magOutConn)
    self._magOutConn = nil
end

function GunClient:_onEquipped()
    self._canFire = false

    self:_resetSprings()

    if self.AllowFirstPerson then
        self:_setupAnimationEvents() 
    end

    ViewmodelController.Viewmodel.OffsetManager:AddOffset(self.Instance.Name.."Recoil", CFrame.new(), 1)

    RunService:BindToRenderStep(self.Instance.Name.."Recoil", Enum.RenderPriority.Last.Value, function(_dt) self:UpdateRecoilOffsets() end)
    RunService:BindToRenderStep(self.Instance.Name.."TriggerInput", Enum.RenderPriority.Input.Value, function(dt) self:HandleTriggerInput(dt) end)

    ContextActionService:BindAction(self.Instance.Name.."Shoot",
        function(_, uis, _)
            self._triggerDown = uis == Enum.UserInputState.Begin
        end,
        false, Enum.UserInputType.MouseButton1)

    ContextActionService:BindAction(self.Instance.Name.."Reload",
        function(_, uis, _)
            if uis ~= Enum.UserInputState.Begin then return end
            self.ReloadEvent:Fire()
        end,
        false, Enum.KeyCode.R)

    self._readyThread = task.delay(self.DeployTime, function()
        self._canFire = true
        self._readyThread = nil
    end)
end

function GunClient:_onUnequipped()
    self._canFire = false

    ContextActionService:UnbindAction(self.Instance.Name.."Shoot")
    ContextActionService:UnbindAction(self.Instance.Name.."Reload")

    self:_cleanupAnimationEvents()

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
    casingClone.CanCollide = true

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

    Debris:AddItem(casingClone, 5)
end

function GunClient:DropMagazine()
    local magazineClone = self.Magazine:Clone()
    magazineClone.Parent = workspace.GunDebris
    magazineClone.CFrame = self.Magazine.CFrame
    magazineClone.CollisionGroup = "GunDebris"
    magazineClone.CanCollide = true

    Debris:AddItem(magazineClone, 3)
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

    for _=1, self.BulletsPerShot do
        local directionalCF = CFrame.new(Vector3.new(), direction)
        local bulletDirection = (directionalCF * CFrame.fromOrientation(0, 0, RAND:NextNumber(0, TAU)) * CFrame.fromOrientation(math.rad(RAND:NextNumber(self.MinSpreadAngle, self.MaxSpreadAngle)), 0, 0)).LookVector

        self.ProjectileCaster:Cast(origin, bulletDirection)
    end

    if replicated then return end
    self._canFire = false

    self:DoCameraRecoil()

    self.FireEvent:Fire(origin, direction)

    if self.Equipment.AllowFirstPerson then
        ViewmodelController.Viewmodel.AnimationManager:PlayAnimation("Fire")
    end

    self._fireRateThread = task.delay(self._fireDelay, function()
        self._canFire = true
    end)
end

return GunClient
