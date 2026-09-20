local PATROL_SPD = 400
local PATROL_ACCEL = 400
local PATROL_PATH_AGE = 0.1
local PATROL_GOAL_THRESH = 120
local PATROL_AHEAD_DIST = 100
local PATROL_WAYPOINT_WAIT = 3

function ENT:StatePatrol()
	self:HandleSpeed(PATROL_SPD, PATROL_ACCEL)

	local targetPos = self:GetNextPatrolSpot()
	if not targetPos then
		self:SetState("Wander")
		return
	end

	if not self:ComputeRoutingPath(targetPos, PATROL_AHEAD_DIST, PATROL_GOAL_THRESH, "Follow") then
		self:SetState("Wander")
		return
	end

	while self.Path:IsValid() do
		if self:IsAtPosition(targetPos, PATROL_GOAL_THRESH) then
			-- advances to the next patrol spot
			coroutine.wait(PATROL_WAYPOINT_WAIT)
			return
		end

		if self:IsTargetVisible(self.Target) then
			-- DO SOMETHING
		end

		self:RefreshPathIfStale(PATROL_PATH_AGE, targetPos, "Follow")
		self.Path:Update(self)
		self:ClearObstacles()

		coroutine.yield()
	end
end
