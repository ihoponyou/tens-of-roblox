
export type StatBlock = {
    Damage: number,
    DeployTime: number,
    MaxCombo: number,
    Endlag: number,
    UsesClientCast: boolean
}

-- max combo is the amount of possible successive m1s; a weapon with 1 m1 would have a maxcombo of 0

local BACKSTAB_THRESHOLD = math.sin(0)

local MeleeStats: {[string]: StatBlock} = {
    ["Dragonslayer"] = {
        Damage = 100;
        DeployTime = 2;
        MaxCombo = 2;
        Endlag = 1;
        UsesClientCast = true;
    },
    ["Classic Knife"] = {
        Damage = 25;
        DeployTime = 0;
        MaxCombo = 0;
        Endlag = 0.1;
        UsesClientCast = false;
        HitboxSize = Vector3.new(3, 5, 3.5);
        _calculateDamage = function(self, humanoid: Humanoid)
            local baseDamage = self.Damage
            local ownerLookVector: Vector3 = self.Equipment.Owner.Character.HumanoidRootPart.CFrame.LookVector
            local victimLookVector: Vector3 = humanoid.RootPart.CFrame.LookVector
            local backstab = ownerLookVector:Dot(victimLookVector) > BACKSTAB_THRESHOLD
            return if backstab then baseDamage * 4 else baseDamage
        end;
    },
    ["Buster"] = {
        Damage = 75;
        DeployTime = 1;
        MaxCombo = 2;
        Endlag = 1;
        UsesClientCast = true;
    },
    ["Classic Sword"] = {
        Damage = 34;
        DeployTime = 0;
        MaxCombo = 1;
        Endlag = 0.5;
        UsesClientCast = false;
        HitboxSize = Vector3.one * 3
    }
}

return MeleeStats
