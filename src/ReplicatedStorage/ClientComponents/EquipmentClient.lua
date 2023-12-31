
local DEBUG = false

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local CameraController, ViewmodelController

local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local LocalPlayerExclusive = require(ReplicatedStorage.Source.Extensions.LocalPlayerExclusive)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local ModelUtil = require(ReplicatedStorage.Source.Modules.ModelUtil)
local PromptGui = require(ReplicatedStorage.Source.UIElements.PromptGui)

local EquipmentClient = Component.new({
	Tag = "Equipment",
	Extensions = {
		LocalPlayerExclusive,
        Logger,
	},
})

function EquipmentClient:Construct()
    self._cfg = EquipmentConfig[self.Instance.Name]
    self._folder = Find.path(ReplicatedStorage, "Equipment/"..self.Instance.Name)

    if not self._cfg.ThirdPersonOnly then
        Find.path(self._folder, "Animations/1P/Equip")
        Find.path(self._folder, "Animations/1P/Idle")
    end

    self._trove = Trove.new()

    self.IsEquipped = false
    self.Equipped = Signal.new()

    self.WorldModel = self.Instance:WaitForChild("WorldModel")

    self.ProximityPrompt = self.WorldModel:WaitForChild("PickUpPrompt")
    self.ProximityPrompt.RequiresLineOfSight = false
    -- self.PromptGui = Roact.createRef()
    -- local promptGui = Roact.createElement(PromptGui, {
    --     equipment_name = self.Instance.Name;
    --     -- ref = self.PromptGui;
    -- })
    -- self._promptTree = Roact.mount(promptGui, self.WorldModel)

    self.EquipRequest = self.Instance:WaitForChild("EquipRequest")
    self.PickUpRequest = self.Instance:WaitForChild("PickUpRequest")
    self.UseEvent = self.Instance:WaitForChild("UseEvent")

    self._riggedToViewmodel = false
end

function EquipmentClient:_onPickedUp()
    -- TODO: add to inventory GUI
end

function EquipmentClient:_rigToViewmodel()
    local viewmodel = ViewmodelController.Viewmodel
    if not viewmodel then error("Cannot rig equipment to viewmodel; no viewmodel") end

    local viewmodelAnimations = Find.path(self._folder, "Animations/1P")

    -- rig to viewmodel
    viewmodel:HoldModel(self.WorldModel)

    local animationManager = viewmodel.AnimationManager
    animationManager:LoadAnimations(viewmodelAnimations:GetChildren())
    animationManager:PlayAnimation("Idle", 0)
    self._riggedToViewmodel = true
end

function EquipmentClient:_rigToCharacter()
    if not self._riggedToViewmodel then return end

    self.WorldModel:ScaleTo(self.WorldModel:GetAttribute("WorldScale"))

	local rootJoint = self.WorldModel.PrimaryPart.RootJoint

    ViewmodelController.Viewmodel:ReleaseModel(self.WorldModel, self.Character)
    rootJoint.Part0 = self.Character["Right Arm"]
    rootJoint.C0 = rootJoint:GetAttribute("WorldEquippedC0")
end

function EquipmentClient:_onEquipped()
    self.IsEquipped = true
    self.Character = Players.LocalPlayer.Character

    if self._cfg.ThirdPersonOnly then
        self:_rigToCharacter()
        -- print("this thing is 3p only!!!")
        CameraController.AllowFirstPerson = false
    elseif CameraController.InFirstPerson then
        self:_rigToViewmodel()
        ViewmodelController.Viewmodel.AnimationManager:PlayAnimation("Equip", 0)
    end

    self.Equipped:Fire(true)
    self.IsEquipped = true
end

function EquipmentClient:_onUnequipped()
    if self._cfg.ThirdPersonOnly then
        -- print("that thing was 3p only!!!")
        CameraController.AllowFirstPerson = true
    elseif CameraController.InFirstPerson then
        local viewmodel = ViewmodelController.Viewmodel
        if not viewmodel then error("Cannot unrig equipment from viewmodel; no viewmodel") end

        viewmodel:ReleaseModel(self.WorldModel, self.Instance) -- instance always stays in owner's backpack
    end

    self.Equipped:Fire(false)
    self.IsEquipped = false
end

function EquipmentClient:_onDropped()
    if self.IsEquipped then self:_onUnequipped() end

    -- unrig from viewmodel and drop it
    self.Instance.Parent = workspace
    self.WorldModel.Parent = self.Instance

    local destinationCFrame
    if CameraController.InFirstPerson then
        destinationCFrame = workspace.CurrentCamera.CFrame
    else
        destinationCFrame = Players.LocalPlayer.Character.PrimaryPart.CFrame -- TODO: fix this
    end
    self.WorldModel:PivotTo(destinationCFrame + destinationCFrame.LookVector)
    self.WorldModel.PrimaryPart.AssemblyLinearVelocity = (workspace.CurrentCamera.CFrame.LookVector * 30)

    -- remove from inventory GUI
end

function EquipmentClient:Use(...: any)
    -- print(...)
    self.UseEvent:FireServer(...)
end

function EquipmentClient:PickUp(): boolean
    local pickUpSuccess = self.PickUpRequest:InvokeServer(true)
    if pickUpSuccess then self:_onPickedUp() end
    return pickUpSuccess
end

function EquipmentClient:Equip(): boolean
    local equipSuccess = self.EquipRequest:InvokeServer(true)
    self:_onEquipped() -- pre emptively equip
    if not equipSuccess then self:_onUnequipped() end
    return equipSuccess
end

function EquipmentClient:Unequip(): boolean
    local unequipSuccess = self.EquipRequest:InvokeServer(false)
    if unequipSuccess then self:_onUnequipped() end
    return unequipSuccess
end

function EquipmentClient:Drop(): boolean
    local dropSuccess = self.PickUpRequest:InvokeServer(false)
    if dropSuccess then self:_onDropped() end
    return dropSuccess
end

function EquipmentClient:_setupForLocalPlayer()
    if DEBUG then print('LOCAL PLAYER OWNS THIS') end
end

function EquipmentClient:_cleanUpForLocalPlayer()
    if DEBUG then print('LOCAL PLAYER NO LONGER OWNS THIS') end
end

function EquipmentClient:Start()
    Knit.OnStart():andThen(function()
        CameraController = Knit.GetController("CameraController")
        ViewmodelController = Knit.GetController("ViewmodelController")
    end)

    self._trove:Connect(CameraController.FirstPersonChanged, function(inFirstPerson: boolean)
        if not self.IsEquipped then return end
        if inFirstPerson then
            self:_rigToViewmodel()
        else
            self:_rigToCharacter()
        end
    end)

    self._trove:Connect(self.ProximityPrompt.Triggered, function()
        self:PickUp()
    end)
    -- self._trove:Connect(self.ProximityPrompt.PromptShown, function() self.PromptGui:getValue().Enabled = true end)
    -- self._trove:Connect(self.ProximityPrompt.PromptHidden, function() self.PromptGui:getValue().Enabled = false end)
end

function EquipmentClient:Stop()
    self._trove:Clean()
end

return EquipmentClient
