-- function ENT:IsPlayerAimingAtBot()
-- function ENT:IsPlayerLookingTowardBotLastPosition()
-- function ENT:GetPlayerViewTurnRate()
-- function ENT:IsPlayerCameraErratic()

function ENT:GetPlayerViewDirection(target)
	return target:EyeAngles():Forward()
end

function ENT:IsPlayerUsingFlashlight(target)
	return target:FlashlightIsOn()
end

function ENT:CanBotSeeTarget(target)
	if not IsValid(target) then
		return false
	end

	local dist = self:GetPos():Distance(target:GetPos())
	if dist > self:GetMaxVisionRange() then
		return false
	end

	return self:IsLineOfSightClear(target)
end

function ENT:IsTargetVisibleFromBot(target)
	if not IsValid(target) then
		return false
	end

	return self:IsLineOfSightClear(target)
end

function ENT:IsPlayerLookingAtBot(target, threshold)
	threshold = threshold or 0.5

	if not IsValid(target) then
		return false
	end

	if not target:IsLineOfSightClear(self) then
		return false
	end

	local dirToBot = (self:GetPos() - target:GetPos()):GetNormalized()
	local entityForward = target:GetForward()

	return entityForward:Dot(dirToBot) > threshold
end
