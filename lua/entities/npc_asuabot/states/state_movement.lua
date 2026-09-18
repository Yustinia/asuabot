local WANDER_SPD = 500
local WANDER_ACCEL = 500
local WANDER_GOAL_THRESH = 120
local WANDER_SCAN_RAD = 2000
local WANDER_RETRY_WAIT = 1
local WANDER_PATH_AGE = 0.1

function ENT:StateWander()
	self:HandleSpeed(WANDER_SPD, WANDER_ACCEL)

	local target = self:GetClosestPlayer()
	local navs = self.CachedNavAreas

	if #navs == 0 then
		coroutine.wait(1)
		return
	end

	local myPos = self:GetPos()
	local nearbyNavs = {}

	for i = 1, #navs do
		local area = navs[i]

		if area:GetCenter():Distance(myPos) <= WANDER_SCAN_RAD then
			table.insert(nearbyNavs, area)
		end
	end

	local candidateNavs = (#nearbyNavs > 0) and nearbyNavs or navs

	local targetArea = candidateNavs[math.random(1, #candidateNavs)]
	local targetPos = targetArea:GetRandomPoint()

	self.path = Path("Follow")
	self.path:SetMinLookAheadDistance(300)
	self.path:SetGoalTolerance(WANDER_GOAL_THRESH)
	self.path:Compute(self, targetPos)

	if not self.path:IsValid() then
		coroutine.wait(WANDER_RETRY_WAIT)
		return
	end

	self.LastPathRecompute = CurTime()

	while self.path:IsValid() do
		if self:GetPos():Distance(targetPos) <= WANDER_GOAL_THRESH then
			self.CurrentState = "Wander"
			return
		end

		if IsValid(target) and self:IsTouchingPlayer(target) then
			self:DealDmgOnContact(target, 1)
			self:PushOnContact(target)
		end

		-- if IsValid(target) and self:IsLineOfSightClear(target) then
		-- 	-- DO SOMETHING

		-- 	return
		-- end

		if self.path:GetAge() > WANDER_PATH_AGE then
			self.path:Compute(self, targetPos)
		end

		if CurTime() - self.LastPathRecompute >= WANDER_PATH_AGE then
			self.LastPathRecompute = CurTime()
			self.path:Update(self)
		else
			self.path:Update(self)
		end

		self:ClearObstacles()
		coroutine.yield()
	end
end
