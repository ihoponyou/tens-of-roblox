--!strict

local ModelUtil = {}

local function validateModel(model: Model?)
	if typeof(model) ~= "Instance" then
		error("model is nil or incorrect type")
	end
	if model.ClassName ~= "Model" then
		error("model is not a model")
	end
end

local function iterateModel(model: Model, operation: (part: BasePart) -> nil)
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		operation(part)
	end
end

function ModelUtil.ChangeModelTransparency(model: Model, transparency: number)
	if type(transparency) ~= "number" or transparency > 1 or transparency < 0 then
		error("transpaency must be a number between 0 and 1")
	end
	validateModel(model)

	iterateModel(model, function(part)
		part.Transparency = transparency
	end)
end

function ModelUtil.SetModelCanCollide(model: Model, canCollide: boolean)
	if type(canCollide) ~= "boolean" then
		error("canCollide must be a boolean")
	end
	validateModel(model)

	iterateModel(model, function(part)
		part.CanCollide = canCollide
	end)
end

function ModelUtil.SetModelNetworkOwner(model: Model, owner: Player?)
	if owner ~= nil then
		if typeof(owner) ~= "Instance" then
			error("owner is incorrect type")
		end
		if model.ClassName ~= "Player" then
			error("owner is not a Player")
		end
	end
	validateModel(model)

	iterateModel(model, function(part)
		part:SetNetworkOwner(owner)
	end)
end

function ModelUtil.SetModelNetworkOwnershipAuto(model: Model)
	validateModel(model)

	iterateModel(model, function(part)
		part:SetNetworkOwnershipAuto()
	end)
end

function ModelUtil.SetModelCollisionGroup(model: Model, collisionGroup: string)
    if type(collisionGroup) ~= "string" then error("collisionGroup must be a string") end
    validateModel(model)

    iterateModel(model, function(part: BasePart)
        part.CollisionGroup = collisionGroup
    end)
end

return ModelUtil
