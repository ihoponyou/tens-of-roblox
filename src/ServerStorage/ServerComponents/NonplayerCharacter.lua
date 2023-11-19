local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(script.Parent.Extensions.Logger)

local NonplayerCharacter = Component.new({
	Tag = "NPC",
	Extensions = {
		Logger,
	},
})

function NonplayerCharacter:Construct()
	self._trove = Trove.new()
end

function NonplayerCharacter:Start()
	-- https://devforum.roblox.com/t/how-to-set-network-ownership-on-npc/1276268
	for _, descendant in pairs(self.Instance:GetDescendants()) do
		if not descendant:IsA("BasePart") then continue end
		-- Try to set the network owner
		local success, errorReason = descendant:CanSetNetworkOwnership()
		if success then
			descendant:SetNetworkOwner(nil)
		else
			-- Sometimes this can fail, so throw an error to prevent mixed networkownership in the 'model'
			error(errorReason)
		end
	end
end

function NonplayerCharacter:Stop()
	self._trove:Destroy()
end

return NonplayerCharacter
