
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
	RootJoint: {
		C0: {
			Holstered: CFrame,
			Equipped: CFrame
		},
		C1: CFrame?
	},
	Components: {string}
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
		RootJoint = {
			C0 = {
				Holstered = CFrame.new(-0.3, 0.3, 0.6) * fromOrientationDeg(0, 180, 50),
				Equipped = {
					World = CFrame.new(0, -1, -0.6) * fromOrientationDeg(0, -90, 90),
					Viewmodel = CFrame.new(0, -1.5, -0.55) * fromOrientationDeg(0, -90, 90)
				}
			},
			C1 = nil
		},
		Components = {
			"Gun"
		}
	},
	["Classic Sword"] = {
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
		RootJoint = {
			C0 = {
				Holstered = CFrame.new(-1.1, -1.393, 0.148) * fromOrientationDeg(30, 0, 90),
				Equipped = {
					World = CFrame.new(0, -0.8, -1.456) * fromOrientationDeg(0, 180, 90),
					-- Viewmodel = CFrame.new(0, -1.2, -1.4) * fromOrientationDeg(0, 180, 90)
				}
			},
			C1 = nil
		},
		Components = {
			"Melee"
		}
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
		RootJoint = {
			C0 = {
				Holstered = CFrame.new(1.5, 1.731, 0.623) * fromOrientationDeg(48.744, -90, -90),
				Equipped = {
					World = CFrame.new(0, -0.807, 0) * fromOrientationDeg(0, 180, 90),
					-- Viewmodel = CFrame.new(0, -0.807, 0) * fromOrientationDeg(0, 180, 90)
				}
			},
			C1 = nil,
		},
		Components = {
			"Melee"
		}
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
		RootJoint = {
			C0 = {
				Holstered = CFrame.new(0.6, 0.8, 0.2) * fromOrientationDeg(-80, 0, 0),
				Equipped = {
					World = CFrame.new(0, -0.6, -0.3) * fromOrientationDeg(-90, 0, 0),
					Viewmodel = CFrame.new(0, -1.113, -0.218) * fromOrientationDeg(-90, 0, 0)
				}
			},
			C1 = CFrame.new(0, -0.132, 0.437)
		},
		Components = {
			"Gun"
		}
	},
	["Classic Knife"] = {
		SlotType = "Secondary",
		HolsterLimb = "Right Leg",
		AllowFirstPerson = true,
		RootJoint = {
			C0 = {
				Holstered = CFrame.new(0.6, 1.634, -0.5) * fromOrientationDeg(15, 180, 180),
				Equipped = {
					World = CFrame.new(0, -0.7, 0) * fromOrientationDeg(-90, 0, 0),
					Viewmodel = CFrame.new(0, -1.1, 0) * fromOrientationDeg(-90, 0, 0)
				}
			},
			C1 = CFrame.new(0, -1, 0),
		},
		Viewport = {
			ElementPosition = UDim2.fromScale(1.5, 0.5),
			ElementSize = UDim2.fromScale(8, 2),
			ModelCFrame = CFrame.new(0, 0, -2) * fromOrientationDeg(-90, 90, 0),
		},
		Components = {
			"Melee"
		}
	};
	["Buster"] = {
		SlotType = "Primary",
		HolsterLimb = "Torso",
		AllowFirstPerson = false,
		RootJoint = {
			C0 = {
				Holstered = CFrame.new(2.3, 2, 0.6) * fromOrientationDeg(-40, 90, -90),
				Equipped = {
					World = CFrame.new(0, -0.8, 0) * fromOrientationDeg(0, 0, 90)
				},
			};
			C1 = CFrame.new(0, 0, 3.1)
		},
		Viewport = {
			-- ElementPosition = nil,
			ModelCFrame = CFrame.new(0, 0, -2) * fromOrientationDeg(0, 90, 90),
		},
		Components = {
			"Melee"
		}
	};
	["Tommy"] = {
		SlotType = "Primary",
		HolsterLimb = "Torso",
		AllowFirstPerson = false,
		RootJoint = {
			C0 = {
				Holstered = CFrame.new(-0.1, 0.072, 0.622) * fromOrientationDeg(34.18, -90, 90),
				Equipped = {
					World = CFrame.new(0, -0.611, -0.28) * fromOrientationDeg(0, 0, 90),
					Viewmodel = CFrame.new(0, -1.1, -0.2) * fromOrientationDeg(0, 0, 90)
				},
			};
			C1 = CFrame.new(0.1, 0, 0.3)
		},
		Viewport = {
			-- ElementPosition = nil,
			ModelCFrame = CFrame.new(0, 0, -2) * fromOrientationDeg(0, 90, 90),
		},
		Components = {
			"Gun"
		}
	}
}

return EquipmentConfig
