
export type StatBlock = {
    Damage: number,
    DeployTime: number,
    HeadshotMultiplier: number,
    FullAuto: boolean,
}

local GunConfig = {
    ["AK-47"] = {
        Damage = 34;
        DeployTime = 0.5;
        HeadshotMultiplier = 2;
        FullAuto = true;
    },
    ["Deagle"] = {
        Damage = 40;
        DeployTime = 0.7;
        HeadshotMultiplier = 3;
        FullAuto = false;
    }
}

return GunConfig
