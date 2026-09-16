function ENT:HandleSpeed(speed, accel)
	local setSpd = speed or 200
	local setAccel = accel or 400

	self.loco:SetDesiredSpeed(setSpd)
	self.loco:SetAcceleration(setAccel)
end

function ENT:TeleportToDistantNavSpot(minDistance)
	minDistance = minDistance or 1000

	local navAreas = navmesh.GetAllNavAreas()
	if not navAreas or #navAreas == 0 then
		return false
	end

	local validSpots = {}

	for i = 1, #navAreas do
		local area = navAreas[i]
		local spot = area:GetCenter()
		local isFarEnough = true

		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) and ply:Alive() then
				if spot:Distance(ply:GetPos()) < minDistance then
					isFarEnough = false
					break
				end
			end
		end

		if isFarEnough then
			table.insert(validSpots, area)
		end
	end

	local selectedArea = (#validSpots > 0) and validSpots[math.random(#validSpots)] or navAreas[math.random(#navAreas)]

	if IsValid(selectedArea) then
		self:SetPos(selectedArea:GetRandomPoint() + Vector(0, 0, 10))
		if self.loco then
			self.loco:ClearStuck()
		end
		return true
	end

	return false
end
