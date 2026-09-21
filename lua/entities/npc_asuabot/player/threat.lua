-- function ENT:IsPlayerHoldingMeleeWeapon() end
-- function ENT:IsPlayerHoldingRangedWeapon() end
-- function ENT:IsPlayerReloading() end
-- function ENT:IsPlayerAttacking() end
-- function ENT:IsPlayerStunned() end
-- function ENT:IsPlayerImmobilized() end
-- function ENT:IsPlayerInvulnerable() end
-- function ENT:IsPlayerAbleToDamageBot() end
-- function ENT:GetPlayerEffectiveAttackRange() end
-- function ENT:GetPlayerThreatLevel() end

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
