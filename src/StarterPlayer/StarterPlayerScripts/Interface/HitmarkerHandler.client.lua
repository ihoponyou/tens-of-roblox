
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local HIT_REGISTERED = ReplicatedStorage.UIEvents.HitRegistered
local START_SIZE = UDim2.fromScale(0.07, 0.07)
local END_SIZE = UDim2.fromScale(0.05, 0.05)
local START_TRANSPARENCY = 0
local END_TRANSPARENCY = 0.4
local MARKER_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local root = Instance.new("ScreenGui")
root.Name = "Hitmarkers"
root.Parent = Players.LocalPlayer.PlayerGui
root.IgnoreGuiInset = true

export type Marker = {
    Instance: ImageLabel;
    Priority: number;
    Tween: Tween;
}

local activeMarker: Marker
local markers: {Marker} = {
    Graze = {
        Instance = ReplicatedStorage.Graze:Clone();
        Priority = 0;
    };
    Hit = {
        Instance = ReplicatedStorage.Hit:Clone();
        Priority = 1;
    };
    Kill = {
        Instance = ReplicatedStorage.Kill:Clone();
        Priority = 2;
    };
}

local function createMarkerTween(instance: ImageLabel): Tween
    local tween = TweenService:Create(instance, MARKER_TWEEN_INFO, {
        Size = END_SIZE,
        -- ImageTransparency = END_TRANSPARENCY
    })
    tween.Completed:Connect(function(playbackState)
        instance.Visible = false
    end)
    return tween
end

for _, v in markers do
    v.Instance.Parent = root
    v.Tween = createMarkerTween(v.Instance)
end

local function spawnHitmarker(marker: Marker)
    if activeMarker ~= nil then
        activeMarker.Tween:Cancel()
        activeMarker.Visible = false
    end
    activeMarker = marker

    marker.Instance.Size = START_SIZE
    marker.Instance.ImageTransparency = START_TRANSPARENCY
    marker.Instance.Visible = true
    marker.Tween:Play()
end

HIT_REGISTERED.OnClientEvent:Connect(function(hitType: string)
    SoundService:PlayLocalSound(SoundService:WaitForChild("HitmarkerSound")) 
    spawnHitmarker(markers[hitType])
end)
