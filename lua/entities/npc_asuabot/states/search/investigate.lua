local INVESTIGATE_SPD = 400
local INVESTIGATE_ACCEL = 400
local INVESTIGATE_PATH_AGE = 0.1
local INVESTIGATE_GOAL_THRESH = 120
local INVESTIGATE_AHEAD_DIST = 100

ENT.UtilityScores.Investigate = function(self, ctx)
	return 0.2
end

ENT.StateEnter.Investigate = function(self)
	self:HandleSpeed(INVESTIGATE_SPD, INVESTIGATE_ACCEL)
	self:ComputeRoutingPath(
		self.GlobalContext.TargetLastSeenPos,
		INVESTIGATE_AHEAD_DIST,
		INVESTIGATE_GOAL_THRESH,
		"Follow"
	)
end

ENT.StateUpdate.Investigate = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(INVESTIGATE_PATH_AGE, self.GlobalContext.TargetLastSeenPos, "Follow")
	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

-- function ENT:StateInvestigate()
-- 	self:HandleSpeed(INVESTIGATE_SPD, INVESTIGATE_ACCEL)

-- 	local targetPos = self.TargetLastSeenPos
-- 	if not targetPos then
-- 		self:SetState("Wander")
-- 		return
-- 	end

-- 	if not self:ComputeRoutingPath(targetPos, INVESTIGATE_AHEAD_DIST, INVESTIGATE_GOAL_THRESH, "Follow") then
-- 		self:SetState("Wander")
-- 		return
-- 	end

-- 	while self.Path:IsValid() do
-- 		if self:IsAtPosition(targetPos, INVESTIGATE_GOAL_THRESH) then
-- 			self:SetState("Wander")
-- 			return
-- 		end

-- 		if self:IsTargetVisible(self.Target) then
-- 			-- DO SOMETHING
-- 		end

-- 		if self:HandleStuckCheck() then
-- 			return
-- 		end

-- 		self:RefreshPathIfStale(INVESTIGATE_PATH_AGE, targetPos, "Follow")
-- 		self.Path:Update(self)
-- 		self:ClearObstacles()

-- 		coroutine.yield()
-- 	end
-- end
