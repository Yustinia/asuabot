local UNSTUCK_LIFT = Vector(0, 0, 10)
local UNSTUCK_DIST = 40
local UNSTUCK_RESET_WINDOW = 2

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

	if CurTime() - (self.LastStuck or 0) >= UNSTUCK_RESET_WINDOW then
		self.StuckTries = 0
	end
	self.LastStuck = CurTime()

	if self.path and self.path:IsValid() then
		local jumpDist = UNSTUCK_DIST * math.pow(2, self.StuckTries or 0)
		local newPos = self.path:GetPositionOnPath(self.path:GetCursorPosition() + jumpDist)
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
