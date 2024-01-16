
export type StatBlock = {
    Damage: number,
    DeployTime: number,
    MaxCombo: number,
    Endlag: number,
    UsesClientCast: boolean
}

-- max combo is the amount of possible successive m1s; a weapon with 1 m1 would have a maxcombo of 0

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
    }
}

return MeleeStats
