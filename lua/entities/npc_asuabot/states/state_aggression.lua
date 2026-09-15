local SPEED_CHASE = 300
local SPEED_RUSH = 700
local SPEED_FLICKER = 800

function ENT:StateChase()
	self.loco:SetDesiredSpeed(SPEED_CHASE)
	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(20)

	local stateStartTime = CurTime()
	local lastSeenTime = CurTime()

	while IsValid(target) and target:Alive() do
		-- 1b: Loss of Interest (10 seconds limit)
		if CurTime() - stateStartTime >= 10 then
			self.CurrentState = "Wander"
			return
		end

		-- 1a: Loss of Sight (3 seconds hidden)
		if target:IsLineOfSightClear(self) then
			lastSeenTime = CurTime()
		elseif CurTime() - lastSeenTime >= 3 then
			self.CurrentState = "Wander"
			return
		end

		-- Path update logic
		if path:GetAge() > 0.5 then
			path:Compute(self, target:GetPos())
		end
		path:Update(self)

		if self.loco:IsStuck() then
			self:HandleStuck()
			return
		end
		coroutine.yield()
	end
end

function ENT:StateRushing()
	self.loco:SetDesiredSpeed(SPEED_RUSH)
	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(20)

	local stateStartTime = CurTime()

	while IsValid(target) and target:Alive() do
		-- 2b: Loss of Interest (8 seconds limit)
		if CurTime() - stateStartTime >= 8 then
			self.CurrentState = "Wander"
			return
		end

		-- 2a: Path Collision / Stuck
		if self.loco:IsStuck() or (self:GetVelocity():LengthSqr() < 400 and path:GetAge() > 1) then
			-- Pretending to choose "another sequence" per instructions
			self.CurrentState = "Wander"
			return
		end

		if path:GetAge() > 0.2 then -- Faster recalculation for high speeds
			path:Compute(self, target:GetPos())
		end
		path:Update(self)

		coroutine.yield()
	end
end

function ENT:StateFlickering()
	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(20)

	local observedStartTime = 0
	local isCurrentlyObserved = false

	while IsValid(target) and target:Alive() do
		local wasObserved = isCurrentlyObserved
		isCurrentlyObserved = self:IsObservedBy(target)

		if isCurrentlyObserved then
			self.loco:SetDesiredSpeed(0) -- Freeze

			if not wasObserved then
				observedStartTime = CurTime()
			end

			-- 18b: Timeout (Stared at for 8 seconds)
			if CurTime() - observedStartTime >= 8 then
				-- [Placeholder] Fade away opacity logic goes here
				self.CurrentState = "Wander"
				return
			end
		else
			self.loco:SetDesiredSpeed(SPEED_FLICKER)

			-- 18a: Reach Target while unobserved (Distance check ~50 HU)
			if self:GetPos():DistToSqr(target:GetPos()) <= 2500 then
				-- [Placeholder] Display Jumpscare Trigger goes here
				self.CurrentState = "Wander"
				return
			end

			if path:GetAge() > 0.5 then
				path:Compute(self, target:GetPos())
			end
			path:Update(self)

			if self.loco:IsStuck() then
				self:HandleStuck()
				return
			end
		end

		coroutine.yield()
	end
end
