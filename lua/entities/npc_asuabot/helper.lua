function ENT:FindFleeSpot(target)
	local radiusDist = 2000

	local hideSpots = navmesh.Find(self:GetPos(), radiusDist, 100, 20)
	local bestSpot = nil
	local maxDist = 0

	for _, area in ipairs(hideSpots) do
		local dist = area:GetCenter():DistToSqr(target:GetPos())
		if dist > maxDist then
			maxDist = dist
			bestSpot = area:GetCenter()
		end
	end

	return bestSpot
end

function ENT:FindHidingSpot(target)
	local areas = navmesh.Find(target:GetPos(), 1500, 100, 20)
	local targetEye = target:EyePos()

	table.Shuffle(areas)

	for _, area in ipairs(areas) do
		local center = area:GetCenter()
		local tr = util.TraceLine({
			start = center + Vector(0, 0, 64),
			endpos = targetEye,
			mask = MASK_OPAQUE,
		})

		if tr.Hit and tr.Fraction < 1.0 then
			return center
		end
	end
	return nil
end

function ENT:FindClosestHidingSpot(target)
	local areas = navmesh.Find(target:GetPos(), 1500, 100, 20)
	local targetEye = target:EyePos()

	local closestSpot = nil
	local closestDist = math.huge

	for _, area in ipairs(areas) do
		local center = area:GetCenter()

		local tr = util.TraceLine({
			start = center + Vector(0, 0, 64),
			endpos = targetEye,
			mask = MASK_OPAQUE,
		})

		if tr.Hit and tr.Fraction < 1.0 then
			local dist = center:Distance(target:GetPos())

			if dist < closestDist then
				closestDist = dist
				closestSpot = center
			end
		end
	end

	return closestSpot
end

function ENT:IsTouchingPlayer(target, distanceThreshold)
	if not IsValid(target) or not target:IsPlayer() or not target:Alive() then
		return false
	end

	distanceThreshold = distanceThreshold or 60

	local dist = self:GetPos():Distance(target:GetPos())
	if dist <= distanceThreshold then
		return true
	end

	local botTorso = self:GetPos() + Vector(0, 0, 36)
	local plyTorso = target:GetPos() + Vector(0, 0, 36)

	local tr = util.TraceHull({
		start = botTorso,
		endpos = plyTorso,
		mins = Vector(-10, -10, -10),
		maxs = Vector(10, 10, 10),
		filter = self,
	})

	return tr.Hit and tr.Entity == target and botTorso:Distance(plyTorso) <= (distanceThreshold + 20)
end

function ENT:TeleportToDistantNavSpot(minDistance)
	minDistance = minDistance or 1000
	local minDistSqr = minDistance * minDistance

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
				if spot:DistToSqr(ply:GetPos()) < minDistSqr then
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

function ENT:PushOnContact(ent)
	local pushIntensity = 2500

	if IsValid(ent) and ent:IsPlayer() then
		local pushVec = ent:GetPos() - self:GetPos()
		pushVec.z = 0
		pushVec:Normalize()

		ent:SetVelocity(pushVec * pushIntensity)
	end
end

function ENT:GetClosestPlayer()
	local closest = nil
	local minDist = math.huge
	local myPos = self:GetPos()

	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE then
			local distSq = myPos:DistToSqr(ply:GetPos())
			if distSq < minDist then
				minDist = distSq
				closest = ply
			end
		end
	end
	return closest
end

function ENT:ClearObstacles()
	local myPos = self:GetPos() + Vector(0, 0, 40)
	local forwardVec = self:GetForward()

	local tr = util.TraceHull({
		start = myPos,
		endpos = myPos + (forwardVec * 60),
		mins = Vector(-16, -16, -16),
		maxs = Vector(16, 16, 16),
		filter = self,
	})

	if tr.Hit and IsValid(tr.Entity) then
		local ent = tr.Entity
		local class = ent:GetClass()

		if string.find(class, "door") then
			ent:Fire("Open")
			ent:Fire("Unlock")

			timer.Simple(0.1, function()
				if IsValid(ent) then
					ent:SetNotSolid(true)
					timer.Simple(2.0, function()
						if IsValid(ent) then
							ent:SetNotSolid(false)
						end
					end)
				end
			end)
		elseif class == "prop_physics" or class == "func_breakable" then
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				phys:ApplyForceCenter(forwardVec * 50000)
			end

			ent:TakeDamage(100, self, self)
		end
	end
end

function ENT:HandleStuck()
	self:ClearObstacles()

	self.loco:ClearStuck()

	local currentNav = navmesh.GetNearestNavArea(self:GetPos())
	if IsValid(currentNav) then
		local randomPoint = currentNav:GetRandomPoint()
		self:SetPos(randomPoint + Vector(0, 0, 5))
	else
		self:SetPos(self:GetPos() - (self:GetForward() * 40) + Vector(0, 0, 10))
	end

	coroutine.yield()
end

function ENT:HandleSpeed(speed, accel)
	local setSpd = speed or 200
	local setAccel = accel or 400

	self.loco:SetDesiredSpeed(setSpd)
	self.loco:SetAcceleration(setAccel)
end

function ENT:IsObservedBy(ply)
	if not IsValid(ply) then
		return false
	end
	if not ply:IsLineOfSightClear(self) then
		return false
	end

	local dirToBot = (self:GetPos() - ply:GetPos()):GetNormalized()
	local plyAim = ply:GetAimVector()
	return plyAim:Dot(dirToBot) > 0.5
end
