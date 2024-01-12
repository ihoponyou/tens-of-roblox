-- melee sound pitches can be bounded by attributes on the pitchshiftsoundeffect on their attacksound

export type GunConfig = {
	Damage: number,
	RoundsPerMinute: number,
	FullyAutomatic: boolean,
	MinSpreadAngle: number,
	MaxSpreadAngle: number,
	BulletMaxDistance: number,
	BulletsPerShot: number,
	ReserveMagazines: number,
	MagazineCapacity: number,
	HasBoltHoldOpen: boolean,
}

export type MeleeConfig = {
	Damage: number,
	MaxCombo: number,
}

export type Equipment = {
	Type: "Gun" | "Melee",
	SlotType: "Primary" | "Secondary",
	ThirdPersonOnly: boolean,
	Viewport: {
		ElementPosition: UDim2,
		ModelCFrame: CFrame,
	},
	Scales: {
		World: number,
		Viewmodel: number,
	},
	HolsterLimb: string,
	TypeDependent: GunConfig | MeleeConfig,
}

local EquipmentConfig: { [string]: Equipment } = {
	["AK-47"] = {
		Type = "Gun",
		SlotType = "Primary",
		ThirdPersonOnly = false,
		Viewport = {
			ElementPosition = UDim2.fromScale(1.05, 0),
			ModelCFrame = CFrame.new(1, 0, -2) * CFrame.Angles(0, 0, 0),
		},
		Scales = {
			World = 0.762,
			Viewmodel = 1,
		},
		HolsterLimb = "Torso",
		TypeDependent = {
			Damage = 20,
			RoundsPerMinute = 600,
			MaxSpreadAngle = 1,
			BulletsPerShot = 1,
			ReserveMagazines = 4,
			BulletMaxDistance = 1000,
			MagazineCapacity = 30,
			MinSpreadAngle = 0,
			HasBoltHoldOpen = true,
			FullyAutomatic = true,
		},
	},
	["ClassicSword"] = {
		Type = "Melee",
		SlotType = "Secondary",
		ThirdPersonOnly = false,
		Viewport = {
			ElementPosition = nil,
			ModelCFrame = CFrame.new(0.6, 0, -2) * CFrame.Angles(0, math.rad(-90), math.rad(90)),
		},
		Scales = {
			World = 1,
			Viewmodel = 1,
		},
		HolsterLimb = "Torso",
		TypeDependent = {
			Damage = 33,
			MaxCombo = 2,
		},
	},
	["Dragonslayer"] = {
		Type = "Melee",
		SlotType = "Primary",
		ThirdPersonOnly = true,
		Viewport = {
			ElementPosition = nil,
			ModelCFrame = CFrame.new(2, 0, -2) * CFrame.Angles(0, math.rad(-90), math.rad(90)),
		},
		Scales = {
			World = 0.59,
			Viewmodel = -1,
		},
		HolsterLimb = "Torso",
		TypeDependent = {
			Damage = 100,
			MaxCombo = 3,
		},
	},
	["Deagle"] = {
		Type = "Gun",
		SlotType = "Secondary",
		ThirdPersonOnly = true,
		Viewport = {
			ElementPosition = UDim2.fromScale(2, 0.2),
			ModelCFrame = CFrame.new(0, 0, -2) * CFrame.Angles(0, math.rad(90), 0),
		},
		Scales = {
			World = 0.689,
			Viewmodel = 0.762,
		},
		HolsterLimb = "Right Leg",
		TypeDependent = {
			Damage = 35,
			FullyAutomatic = false,
			HasBoltHoldOpen = true,
			BulletsPerShot = 1,
			BulletMaxDistance = 1000,
			MinSpreadAngle = 0,
			MaxSpreadAngle = 3,
			MagazineCapacity = 7,
			ReserveMagazines = 7,
			RoundsPerMinute = 200,
		},
	},
}

return EquipmentConfig
