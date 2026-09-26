function ENT:IsPlayerCrouching(target)
	return target:Crouching()
end

function ENT:IsPlayerSwimming(target)
	return target:WaterLevel() >= 2
end

function ENT:IsPlayerInVehicle(target)
	return target:InVehicle()
end

function ENT:GetPlayerVelocity(target)
	return target:GetVelocity()
end

function ENT:GetPlayerSpeed(target)
	return target:GetVelocity():Length()
end
