-- function ENT:IsPlayerReloading() end
-- function ENT:IsPlayerAttacking() end
-- function ENT:IsPlayerAbleToDamageBot() end
-- function ENT:GetPlayerCombatCapability()
-- function ENT:GetPlayerThreatLevel()
-- function ENT:GetPlayerAmmoStatus()

function ENT:GetPlayerHealth(target)
	if not IsValid(target) then
		return
	end

	return target:Health()
end
