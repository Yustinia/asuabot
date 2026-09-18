local WANDER_SPD = 500
local WANDER_ACCEL = 500
local WANDER_GOAL_THRESH = 120
local WANDER_SCAN_RAD = 2000
local WANDER_RETRY_WAIT = 1
local WANDER_PATH_AGE = 0.8
local WANDER_AHEAD_DIST = 150

function ENT:StateWander()
	self:HandleSpeed(WANDER_SPD, WANDER_ACCEL)

	self.Target = self:GetClosestPlayer()
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

	self.Path = Path("Follow")
	self:ConfigFollowPath(WANDER_AHEAD_DIST, WANDER_GOAL_THRESH)
	self.Path:Compute(self, targetPos)

	if not self.Path:IsValid() then
		coroutine.wait(WANDER_RETRY_WAIT)
		return
	end

	self.ProgressPos = self:GetPos()
	self.ProgressTime = CurTime()

	while self.Path:IsValid() do
		if self:GetPos():Distance(targetPos) <= WANDER_GOAL_THRESH then
			self.CurrentState = "Wander"
			return
		end

		if IsValid(self.Target) and self:IsTouchingPlayer(self.Target) then
			self:DealDmgOnContact(self.Target, 1)
		end

		if IsValid(target) and self:IsLineOfSightClear(self.Target) then
			self.TargetLastSeenPos = self.Target:GetPos()
		end

		if self:CheckProgress() then
			self:HandleStuck()

			if self.StuckTries >= self.StuckMax then
				self.CurrentState = "Wander"
				return
			end
		end

		if self.Path:GetAge() >= WANDER_PATH_AGE then
			self.Path:Compute(self, targetPos)
		end

		self.Path:Update(self)

		self:ClearObstacles()
		coroutine.yield()
	end
end
