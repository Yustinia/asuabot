local UNSTUCK_LIFT = Vector(0, 0, 10)
local UNSTUCK_DIST = 40
local UNSTUCK_RESET_WINDOW = 4

local PROGRESS_CHECK_INTERVAL = 2
local PROGRESS_MIN_DIST = 60

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

function ENT:CheckProgress()
	local now = CurTime()

	if not self.ProgressPos then
		self.ProgressPos = self:GetPos()
		self.ProgressTime = now
		return false
	end

	if now - self.ProgressTime < PROGRESS_CHECK_INTERVAL then
		return false
	end

	local moved = self:GetPos():Distance(self.ProgressPos)

	self.ProgressPos = self:GetPos()
	self.ProgressTime = now

	if moved < PROGRESS_MIN_DIST then
		return true
	end

	return false
end

function ENT:HandleStuck()
	self:ClearObstacles()

	if CurTime() - (self.LastStuck or 0) >= UNSTUCK_RESET_WINDOW then
		self.StuckTries = 0
	end
	self.LastStuck = CurTime()

	if self.Path and self.Path:IsValid() then
		local jumpDist = UNSTUCK_DIST * math.pow(2, self.StuckTries or 0)
		local newPos = self.Path:GetPositionOnPath(self.Path:GetCursorPosition() + jumpDist)
		self:SetPos(newPos + UNSTUCK_LIFT)
		self.StuckTries = (self.StuckTries or 0) + 1
	else
		local currentNav = navmesh.GetNearestNavArea(self:GetPos())
		if IsValid(currentNav) then
			local randomPoint = currentNav:GetRandomPoint()
			self:SetPos(randomPoint + UNSTUCK_LIFT)
		else
			self:SetPos(self:GetPos() - (self:GetForward() * UNSTUCK_DIST) + UNSTUCK_LIFT)
		end
	end

	self.loco:ClearStuck()
	coroutine.yield()
end

function ENT:ConfigRoutingPath(minLookAheadDist, goalTolerance)
	self.Path:SetMinLookAheadDistance(minLookAheadDist)
	self.Path:SetGoalTolerance(goalTolerance)
end

function ENT:ComputeRoutingPath(target, minLookAheadDist, goalTolerance, mode)
	if not self.Path or self.PathMode ~= mode then
		if mode == "Follow" then
			self.Path = Path("Follow")
		elseif mode == "Chase" then
			self.Path = Path("Chase")
		end

		self.PathMode = mode
	end

	self:ConfigRoutingPath(minLookAheadDist, goalTolerance)

	if mode == "Follow" then
		self.Path:Compute(self, target)
	elseif mode == "Chase" then
		self.Path:Chase(self, target)
	end

	if self.Path:IsValid() then
		return self.Path
	end

	return false
end

function ENT:RefreshPathIfStale(maxAge, target, mode)
	if self.Path:GetAge() < maxAge then
		return
	end

	if mode == "Follow" then
		self.Path:Compute(self, target)
	elseif mode == "Chase" then
		self.Path:Chase(self, target)
	end
end
