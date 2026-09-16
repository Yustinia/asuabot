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

function ENT:CustomHandleStuck()
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
