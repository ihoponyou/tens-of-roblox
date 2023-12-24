
export type Offset = {
    Value: CFrame;
    Alpha: number; -- between 0 and 1; essentially the "scale"
}

local OffsetManager = {}
OffsetManager.__index = OffsetManager

function OffsetManager.new()
    local self = setmetatable({}, OffsetManager)

    self.Offsets = {}

    return self
end

function OffsetManager:AddOffset(name: string, offset: CFrame, alpha: number)
	if type(name) ~= "string" then error("Invalid offset name") end

	if typeof(offset) ~= "CFrame" then error("Invalid offset value") end

    if type(alpha) ~= "number" then error("Invalid alpha value") end
    if alpha > 1 or alpha < 0 then error("Alpha must be in the range [0, 1]") end

	self.Offsets[name] = {
		Value = offset,
		Alpha = alpha
	}
end

function OffsetManager:AddOffsets(offsets: {Offset})
    for name, offset in offsets do
        self:AddOffset(name, offset.Value, offset.Alpha)
    end
end

function OffsetManager:SetOffsetValue(name: string, newOffset: CFrame)
	if type(name) ~= "string" then error("Invalid offset name") end

    if typeof(newOffset) ~= "CFrame" then error("Invalid offset value") end

    local offset = self.Offsets[name]
	if not offset then
        error("no offset found with name: "..name)
    end

    offset.Value = newOffset
end

function OffsetManager:SetOffsetAlpha(name: string, newAlpha: number)
	if type(name) ~= "string" then error("Invalid offset name") end

    if type(newAlpha) ~= "number" then error("Invalid alpha value") end
    if newAlpha > 1 or newAlpha < 0 then error("Alpha must be in the range [0, 1]") end

	local offset: Offset = self.Offsets[name]
	if not offset then warn("no offset found with name: "..name) return end

    offset.Alpha = newAlpha
end

-- removes an offset from Offsets if the offset exists; otherwise does nothing
function OffsetManager:RemoveOffset(name: string)
	if type(name) ~= "string" then error("Invalid offset name") end
	self.Offsets[name] = nil
end

-- returns the value of all offsets combined weighted by alpha
function OffsetManager:GetCombinedOffset(): CFrame
	local combinedOffset = CFrame.new()

	for k, v in self.Offsets do
		combinedOffset = combinedOffset:Lerp((combinedOffset * v.Value), v.Alpha)
	end

    return combinedOffset
end

function OffsetManager:Destroy()
    setmetatable(self, nil)
    table.clear(self)
    table.freeze(self)
end

return OffsetManager
