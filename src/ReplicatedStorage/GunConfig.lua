
local GunConfig = {
    ["AK-47"] = {
		RoundsPerMinute = 600;
		MaxSpreadAngle = 1;
		BulletsPerShot = 1;
		ReserveMagazines = 4;
		-- BulletSpeed = 1000;
		-- BulletGravity = Vector3.new(0, -98.0999984741211, 0);
		-- CanPierce = false;
		BulletMaxDistance = 1000;
		MagazineCapacity = math.huge;
		Damage = 20;
		MinSpreadAngle = 0;
		HasBoltHoldOpen = true;
		FullyAutomatic = true;
    }
}

return GunConfig