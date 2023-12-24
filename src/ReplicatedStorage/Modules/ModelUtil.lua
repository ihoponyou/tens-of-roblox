
local ModelUtil = {}

local function validateModel(model: Model?)
    if typeof(model) ~= "Instance" then error("model is nil or incorrect type") end
    if model.ClassName ~= "Model" then error("model is not a model") end
end

function ModelUtil.ChangeModelTransparency(model: Model, transparency: number)
    if type(transparency) ~= "number" or transparency > 1 or transparency < 0 then error("transpaency must be a number between 0 and 1") end
    validateModel(model)

    for _, part: BasePart in model:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        part.Transparency = transparency
    end
end

function ModelUtil.SetModelCanCollide(model: Model, canCollide: boolean)
    if type(canCollide) ~= "boolean" then error("canCollide must be a boolean") end
    validateModel(model)

    for _, part: BasePart in model:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        part.CanCollide = canCollide
    end
end

return ModelUtil
