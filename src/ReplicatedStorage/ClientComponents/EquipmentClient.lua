
local DEBUG = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Find = require(ReplicatedStorage.Source.Modules.Find)
local LocalPlayerExclusive = require(ReplicatedStorage.Source.Extensions.LocalPlayerExclusive)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local Roact = require(ReplicatedStorage.Packages.Roact)

local PromptGui = require(ReplicatedStorage.Source.UIElements.PromptGui)

local ViewmodelController
local EquipmentClient = Component.new({
	Tag = "Equipment",
	Extensions = {
		LocalPlayerExclusive,
        Logger,
	},
})

function EquipmentClient:Construct()
    self._folder = Find.path(ReplicatedStorage, "Equipment/"..self.Instance.Name)

    Find.path(self._folder, "Animations/1P/Equip")
    Find.path(self._folder, "Animations/1P/Idle")

    self._trove = Trove.new()

    self.IsEquipped = false
    self.Equipped = Signal.new()

    self.WorldModel = self.Instance:WaitForChild("WorldModel")

    self.ProximityPrompt = self.WorldModel:WaitForChild("PickUpPrompt")
    self.ProximityPrompt.RequiresLineOfSight = false
    self.PromptGui = Roact.createRef()
    local promptGui = Roact.createElement(PromptGui, {
        equipment_name = self.Instance.Name;
        ref = self.PromptGui;
    })
    self._promptTree = Roact.mount(promptGui, self.WorldModel)

    self.EquipRequest = self.Instance:WaitForChild("EquipRequest")
    self.PickUpRequest = self.Instance:WaitForChild("PickUpRequest")
    self.UseEvent = self.Instance:WaitForChild("UseEvent")
end

function EquipmentClient:_onPickedUp()
    -- TODO: add to inventory GUI
end

function EquipmentClient:_onEquipped()
    self.IsEquipped = true
    local viewmodel = ViewmodelController.Viewmodel
    if not viewmodel then error("Cannot rig equipment to viewmodel; no viewmodel") end

    local viewmodelAnimations = Find.path(self._folder, "Animations/1P")

    -- rig to viewmodel
    viewmodel:HoldModel(self.WorldModel)

    local animationManager = viewmodel.AnimationManager
    animationManager:LoadAnimations(viewmodelAnimations:GetChildren())
    animationManager:PlayAnimation("Equip", 0)
    animationManager:PlayAnimation("Idle", 0)

    self.Equipped:Fire(true)
    self.IsEquipped = true
end

function EquipmentClient:_onUnequipped()
    self.IsEquipped = false
    local viewmodel = ViewmodelController.Viewmodel
    if not viewmodel then error("Cannot unrig equipment from viewmodel; no viewmodel") end

    viewmodel:ReleaseModel(self.WorldModel, self.Instance) -- instance always stays in owner's backpack

    -- viewmodel animations are internally stopped in ReleaseModel

    self.Equipped:Fire(false)
    self.IsEquipped = false
end

function EquipmentClient:_onDropped()
    if self.IsEquipped then self:_onUnequipped() end

    -- unrig from viewmodel and drop it
    self.Instance.Parent = workspace
    self.WorldModel.Parent = self.Instance

    -- throw it
    local cameraCFrame = workspace.CurrentCamera.CFrame
    self.WorldModel:PivotTo(cameraCFrame + cameraCFrame.LookVector)
    self.WorldModel.PrimaryPart.AssemblyLinearVelocity = (workspace.CurrentCamera.CFrame.LookVector * 30)

    -- remove from inventory GUI
end

function EquipmentClient:Use(...: any)
    self.UseEvent:FireServer(...)
end

function EquipmentClient:PickUp(): boolean
    local pickUpSuccess = self.PickUpRequest:InvokeServer(true)
    if pickUpSuccess then self:_onPickedUp() end
    return pickUpSuccess
end

function EquipmentClient:Equip(): boolean
    local equipSuccess = self.EquipRequest:InvokeServer(true)
    if equipSuccess then self:_onEquipped() end
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

    -- on picked up
end

function EquipmentClient:_cleanUpForLocalPlayer()
    if DEBUG then print('LOCAL PLAYER NO LONGER OWNS THIS') end

    -- on dropped
end

function EquipmentClient:Start()
    Knit.OnStart():andThen(function()
        ViewmodelController = Knit.GetController("ViewmodelController")
    end)

    self._trove:Connect(self.ProximityPrompt.Triggered, function()
        self:PickUp()
    end)
    self._trove:Connect(self.ProximityPrompt.PromptShown, function() self.PromptGui:getValue().Enabled = true end)
    self._trove:Connect(self.ProximityPrompt.PromptHidden, function() self.PromptGui:getValue().Enabled = false end)
end

function EquipmentClient:Stop()
    self._trove:Clean()
end

return EquipmentClient
