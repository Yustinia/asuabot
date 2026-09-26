local LIFT_VECTOR = Vector(0, 0, 10)

function ENT:SetAccel(accel)
	self.loco:SetAcceleration(accel)
end

function ENT:SetSpeed(speed)
	self.loco:SetDesiredSpeed(speed)
end

function ENT:HandleSpeed(speed, accel)
	speed = speed or 200
	accel = accel or 400

	self:SetSpeed(speed)
	self:SetAccel(accel)
end

function ENT:TeleportToDistantNavSpot(minDistance)
	minDistance = minDistance or 1000

	local navAreas = self.GlobalContext.CachedNavmesh
	if not navAreas or #navAreas == 0 then
		return
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
		self:SetPos(selectedArea:GetRandomPoint() + LIFT_VECTOR)
	end
end
