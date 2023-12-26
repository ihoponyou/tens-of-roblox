local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local NonplayerCharacter = Component.new({
	Tag = "NPC",
	Extensions = {
		Logger,
	},
})

function NonplayerCharacter:Construct()
	self._trove = Trove.new()

	-- self.Character = self._trove:Clone(game.StarterPlayer.StarterCharacter)
	-- self.Character:PivotTo(self.Instance:GetPivot())
end

function NonplayerCharacter:Start()
	
end

function NonplayerCharacter:Stop()
	self._trove:Destroy()
end

return NonplayerCharacter
