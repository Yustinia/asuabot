local FLEE_SPD = 800
local FLEE_ACCEL = 800
local FLEE_PATH_AGE = 0.2
local FLEE_AHEAD_DIST = 100
local FLEE_GOAL_THRESH = 40
local FLEE_SCAN_RAD = 8000

function ENT:StateFlee()
	self:HandleSpeed(FLEE_SPD, FLEE_ACCEL)

	self.Target = self:FindClosestPlayer()
	local targetPos = self:FindFleeSpot(FLEE_SCAN_RAD)

	if not self:ComputeRoutingPath(targetPos, FLEE_AHEAD_DIST, FLEE_GOAL_THRESH, "Follow") then
		return
	end

	while self.Path:IsValid() do
		if self:IsAtPosition(targetPos, FLEE_GOAL_THRESH) then
			return
		end

		self:RefreshPathIfStale(FLEE_PATH_AGE, targetPos, "Follow")
		self.Path:Update(self)
		self:ClearObstacles()

		coroutine.yield()
	end
end
