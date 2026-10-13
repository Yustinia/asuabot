local MELEE_HOLD = {
	melee = true,
	melee2 = true,
	knife = true,
	fist = true,
}

local RANGED_HOLD = {
	pistol = true,
	revolver = true,
	smg = true,
	ar2 = true,
	shotgun = true,
	crossbow = true,
	rpg = true,
	duel = true,
}

function ENT:GetActiveWeaponType(target)
	local w = IsValid(target) and target:GetActiveWeapon()
	if not IsValid(w) then
		return nil
	end
	return w:GetHoldType()
end

function ENT:IsPlayerHoldingMelee(target)
	return MELEE_HOLD[self:GetActiveWeaponType(target)] == true
end

function ENT:IsPlayerHoldingRanged(target)
	return RANGED_HOLD[self:GetActiveWeaponType(target)] == true
end
