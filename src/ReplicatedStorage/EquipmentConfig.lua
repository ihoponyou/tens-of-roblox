
export type SlotType = "Primary" | "Secondary"

export type Equipment = {
	SlotType: SlotType,
	HolsterLimb: string,
	AllowFirstPerson: boolean,
	Viewport: {
		ElementPosition: UDim2?,
		ModelCFrame: CFrame?,
	},
	Scales: {
		World: number,
		Viewmodel: number,
	},
	RootJointC0: {
		Holstered: CFrame,
		Equipped: CFrame
	},
}

local function fromOrientationDeg(x: number, y: number, z: number): CFrame
	return CFrame.fromOrientation(math.rad(x), math.rad(y), math.rad(z))
end

local EquipmentConfig: { [string]: Equipment } = {
	["AK-47"] = {
		SlotType = "Primary",
		HolsterLimb = "Torso",
		AllowFirstPerson = true,
		Viewport = {
			ElementPosition = UDim2.fromScale(1.05, 0),
			ModelCFrame = CFrame.new(1, 0, -2),
		},
		Scales = {
			World = 0.762,
			Viewmodel = 1,
		},
		RootJointC0 = {
			Holstered = CFrame.new(-0.3, 0.3, 0.6) * fromOrientationDeg(0, 180, 50),
			Equipped = {
				World = CFrame.new(0, -1, -0.6) * fromOrientationDeg(0, -90, 90),
				Viewmodel = CFrame.new(0, -1.5, -0.55) * fromOrientationDeg(0, -90, 90)
			}
		},
	},
	["ClassicSword"] = {
		SlotType = "Secondary",
		HolsterLimb = "Torso",
		AllowFirstPerson = false,
		Viewport = {
			ElementPosition = nil,
			ModelCFrame = CFrame.new(0.6, 0, -2) * fromOrientationDeg(0, -90, 90),
		},
		Scales = {
			World = 1,
			Viewmodel = 1,
		},
		RootJointC0 = {
			Holstered = CFrame.new(-1.1, -1.393, 0.148) * fromOrientationDeg(30, 0, 90),
			Equipped = {
				World = CFrame.new(0, -0.8, -1.456) * fromOrientationDeg(0, 180, 90),
				-- Viewmodel = CFrame.new(0, -1.2, -1.4) * fromOrientationDeg(0, 180, 90)
			}
		},
	},
	["Dragonslayer"] = {
		SlotType = "Primary",
		HolsterLimb = "Torso",
		AllowFirstPerson = false,
		Viewport = {
			ElementPosition = nil,
			ModelCFrame = CFrame.new(2, 0, -2) * fromOrientationDeg(0, -90, 90),
		},
		Scales = {
			World = 0.59,
			-- Viewmodel = -1,
		},
		RootJointC0 = {
			Holstered = CFrame.new(1.5, 1.731, 0.623) * fromOrientationDeg(48.744, -90, -90),
			Equipped = {
				World = CFrame.new(0, -0.807, 0) * fromOrientationDeg(0, 180, 90),
				-- Viewmodel = CFrame.new(0, -0.807, 0) * fromOrientationDeg(0, 180, 90)
			}
		},
	},
	["Deagle"] = {
		SlotType = "Secondary",
		HolsterLimb = "Right Leg",
		AllowFirstPerson = true,
		Viewport = {
			ElementPosition = UDim2.fromScale(2, 0.2),
			ModelCFrame = CFrame.new(0, 0, -2) * fromOrientationDeg(0, 90, 0),
		},
		Scales = {
			World = 0.689,
			Viewmodel = 0.762,
		},
		RootJointC0 = {
			Holstered = CFrame.new(0.6, 0.5, 0) * fromOrientationDeg(-80, 0, 0),
			Equipped = {
				World = CFrame.new(0, -1.043, -0.435) * fromOrientationDeg(-90, 0, 0),
				Viewmodel = CFrame.new(0, -1.5, -0.35) * fromOrientationDeg(-90, 0, 0)
			}
		},
	},
	ClassicKnife = {
		SlotType = "Secondary",
		HolsterLimb = "Torso",
		AllowFirstPerson = true,
		RootJointC0 = {
			Holstered = CFrame.new(1.1, -1.35, -0.3) * fromOrientationDeg(-15, 180, 180),
			Equipped = {
				World = CFrame.new(0, -0.7, 1.01) * fromOrientationDeg(90, 0, 0),
				Viewmodel = CFrame.new(0, -1.2, 1.01) * fromOrientationDeg(90, 0, 0)
			}
		},
		Viewport = {
			ElementPosition = nil,
			-- ModelCFrame = CFrame.new(0.6, 0, -2) * CFrame.Angles(0, math.rad(-90), math.rad(90)),
		},
	};
	Buster = {
		SlotType = "Primary",
		HolsterLimb = "Torso",
		AllowFirstPerson = false,
		RootJointC0 = {
			Holstered = CFrame.new(0.216, -0.147, 0.542) * fromOrientationDeg(-40, 90, -90),
			Equipped = {
				World = CFrame.new(0, -0.8, -3.1) * fromOrientationDeg(0, 0, 90)
			}
		},
		Viewport = {
			-- ElementPosition = nil,
			-- ModelCFrame = CFrame.new(0.6, 0, -2) * CFrame.Angles(0, math.rad(-90), math.rad(90)),
		},
	}
}

return EquipmentConfig
