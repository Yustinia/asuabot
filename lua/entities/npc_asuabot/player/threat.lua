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

function ENT:GetPlayerHealth()
	if not IsValid(self.Target) then
		return
	end

	return self.Target:Health()
end

function ENT:IsPlayerHealthy()
	return self:GetPlayerHealth() >= 65
end

function ENT:IsPlayerWounded()
	return self:GetPlayerHealth() < 65
end

function ENT:IsPlayerCritical()
	return self:GetPlayerHealth() <= 25
end

function ENT:IsPlayerNearDeath()
	return self:GetPlayerHealth() <= 10
end
