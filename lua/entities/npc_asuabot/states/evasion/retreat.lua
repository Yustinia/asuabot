local RETREAT_SPD = 1200
local RETREAT_ACCEL = 2400
local RETREAT_GOAL_THRESH = 0
local RETREAT_PATH_AGE = 0.1
local RETREAT_AHEAD_DIST = 20
local RETREAT_DIST = 3000

function ENT:StateRetreat()
	self:HandleSpeed(RETREAT_SPD, RETREAT_ACCEL)
	self.Target = self:FindClosestPlayer()

	local targetPos = self:FindClosestHideSpot(RETREAT_DIST)

	if not self:ComputeRoutingPath(targetPos, RETREAT_AHEAD_DIST, RETREAT_GOAL_THRESH, "Follow") then
		return
	end

	while self.Path:IsValid() do
		if self:IsAtPosition(targetPos, RETREAT_GOAL_THRESH) then
			-- DO SOMETHING
		end

		self:RefreshPathIfStale(RETREAT_PATH_AGE, targetPos, "Follow")
		self.Path:Update(self)
		self:ClearObstacles()

		coroutine.yield()
	end
end
