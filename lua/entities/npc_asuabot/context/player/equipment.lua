local meleeWeapons = {
	"weapon_crowbar",
	"weapon_stunstick",
}

local rangedWeapons = {
	"weapon_pistol",
	"weapon_357",
	"weapon_smg1",
	"weapon_ar2",
	"weapon_shotgun",
	"weapon_crossbow",
	"weapon_rpg",
}

function ENT:GetActiveWeapon(target)
	return target:GetActiveWeapon():GetClass()
end

function ENT:GetActiveWeaponType(target)
	return target:GetActiveWeapon():GetHoldType()
end

function ENT:IsPlayerHoldingMelee(target)
	local weap = self:GetActiveWeapon(target)

	if not IsValid(target) then
		return false
	end

	for _, weapon in ipairs(meleeWeapons) do
		if weap == weapon then
			return true
		end
	end

	return false
end

function ENT:IsPlayerHoldingRanged(target)
	local weap = self:GetActiveWeapon(target)

	if not IsValid(target) then
		return false
	end

	for _, weapon in ipairs(rangedWeapons) do
		if weap == weapon then
			return true
		end
	end

	return false
end

function ENT:IsPlayerUsingFlashlight(target)
	return target:FlashlightIsOn()
end
