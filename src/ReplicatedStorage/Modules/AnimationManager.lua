
local AnimationManager = {}
AnimationManager.__index = AnimationManager

function isValidOwnerType(owner: Instance?)
    return typeof(owner) == "Instance" and owner.ClassName == "Animator"
end
function AnimationManager.new(animator: Animator)
    if not isValidOwnerType(animator) then error("Invalid animator") end
    local self = setmetatable({}, AnimationManager)

    local anims: {AnimationTrack} = {}
    self._animations = anims
    self._animator = animator

    return self
end

function AnimationManager:LoadAnimations(anims: {Animation})
	-- empty current animation dict
	self._animations = {}

	for _,v: Animation in anims do
		if not v:IsA("Animation") then continue end

		local animTrack: AnimationTrack = self._animator:LoadAnimation(v)
		-- if animTrack.Name:match("[iI]dle") then
        --     animTrack.Priority = Enum.AnimationPriority.Idle
        -- end

        -- index each animation with its name as key and animationtrack as value
		self._animations[v.Name] = animTrack
		-- print(v.Name, "@", animTrack.Priority)
	end
end

function AnimationManager:GetAnimation(animationName: string): AnimationTrack
	if type(animationName) ~= "string" then error("Invalid animation name") end
	local animationTrack = self._animations[animationName]
	if animationTrack == nil then error("No loaded animation with name \""..animationName.."\"") end

	return self._animations[animationName]
end

function AnimationManager:PlayAnimation(animationName: string, fadeTime: number?, weight: number?, speed: number?)
	local animationTrack = self:GetAnimation(animationName)
	-- if string.match(animationName, "[iI]dle") then animationTrack.Priority = Enum.AnimationPriority.Idle end
	animationTrack:Play(fadeTime or 0.100000001, weight or 1, speed or 1)
end

function AnimationManager:StopAnimation(animationName: string, fadeTime: number?)
	local animationTrack = self:GetAnimation(animationName)
	animationTrack:Stop(fadeTime or 0.100000001)
end

function AnimationManager:StopPlayingAnimations(fadeTime: number?)
	for name, track: AnimationTrack in self._animations do
		if not track.IsPlaying then continue end
		self:StopAnimation(name, fadeTime)
	end
end

function AnimationManager:Destroy()
    setmetatable(self, nil)
    table.clear(self)
    table.freeze(self)
end

return AnimationManager
