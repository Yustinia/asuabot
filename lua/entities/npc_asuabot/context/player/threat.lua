-- function ENT:IsPlayerReloading() end
-- function ENT:IsPlayerAttacking() end
-- function ENT:IsPlayerAbleToDamageBot() end
-- function ENT:IsPlayerVulnerable()
-- function ENT:IsPlayerHealthy()
-- function ENT:IsPlayerWounded()
-- function ENT:IsPlayerCritical()
-- function ENT:IsPlayerNearDeath()
-- function ENT:GetPlayerHealth()
-- function ENT:GetPlayerCombatCapability()
-- function ENT:GetPlayerThreatLevel()
-- function ENT:GetPlayerAmmoStatus()

function ENT:GetPlayerHealth(target)
	if not IsValid(target) then
		return
	end

	return target:Health()
end

function ENT:IsPlayerHealthy(target)
	return self:GetPlayerHealth(target) >= 65
end

function ENT:IsPlayerWounded(target)
	return self:GetPlayerHealth(target) < 65
end

function ENT:IsPlayerCritical(target)
	return self:GetPlayerHealth(target) <= 25
end

function ENT:IsPlayerNearDeath(target)
	return self:GetPlayerHealth(target) <= 10
end
