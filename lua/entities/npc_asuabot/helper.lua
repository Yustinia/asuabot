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

function ENT:OnContact(ent)
	local pushIntensity = 1500

	if self.CurrentState == "Avoid" and IsValid(ent) and ent:IsPlayer() then
		ent:TakeDamage(15, self, self)

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
