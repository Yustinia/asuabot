local PEEK_SPD = 350
local PEEK_ACCEL = 350
local PEEK_GOAL_THRESH = 0
local PEEK_AHEAD_DIST = 20
local PEEK_PATH_AGE = 0.3
local PEEK_HIDE_SCAN_RADIUS = 6000
local PEEK_DIRECT_THRESHOLD = math.cos(math.rad(30))
local PEEK_HOLD_MAX_DUR = 20

function ENT:StatePeek()
	self.Target = self:FindClosestPlayer()
	if not IsValid(self.Target) then
		self:SetState("Wander")
		return
	end

	local hideSpot = self:FindClosestHideSpot(PEEK_HIDE_SCAN_RADIUS)
	if not hideSpot then
		self:SetState("Wander")
		return
	end
	self:SetPos(hideSpot)

	self:HandleSpeed(PEEK_SPD, PEEK_ACCEL)
	self:ComputeRoutingPath(self.Target, PEEK_AHEAD_DIST, PEEK_GOAL_THRESH, "Chase")

	local exposed = false
	while self.Path:IsValid() and IsValid(self.Target) and self.Target:Alive() do
		if self:CanSee(self.Target) then
			exposed = true
			-- DO SOMETHING
			break
		end

		if self:HandleStuckCheck() then
			return
		end

		self:RefreshPathIfStale(PEEK_PATH_AGE, self.Target, "Chase")
		self.Path:Update(self)
		self:ClearObstacles()

		coroutine.yield()
	end

	if not exposed then
		self:SetState("Wander")
		return
	end

	self:HandleSpeed(0, 0)
	local holdStartTime = CurTime()
	while IsValid(self.Target) and self.Target:Alive() do
		if self:CanSee(self.Target) then
			self.TargetLastSeenPos = self.Target:GetPos()
			self.TargetLastSeenTime = CurTime()
			self:RecordLastSeenPosition(self.Target:GetPos())
		end

		if self:IsObservedBy(self.Target, PEEK_DIRECT_THRESHOLD) then
			self:SetState("Wander")
			return
		end

		if CurTime() - holdStartTime > PEEK_HOLD_MAX_DUR then
			-- DO SOMETHING
			break
		end

		coroutine.yield()
	end

	self:HandleSpeed(PEEK_SPD, PEEK_ACCEL)
	self:ComputeRoutingPath(hideSpot, PEEK_AHEAD_DIST, PEEK_GOAL_THRESH, "Follow")

	while self.Path:IsValid() do
		if self:IsAtPosition(hideSpot, PEEK_GOAL_THRESH) then
			self:SetState("Wander")
			return
		end

		self:RefreshPathIfStale(PEEK_PATH_AGE, hideSpot, "Follow")
		self.Path:Update(self)
		self:ClearObstacles()

		coroutine.yield()
	end
end
