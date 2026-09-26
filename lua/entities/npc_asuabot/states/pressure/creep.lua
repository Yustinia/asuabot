local CREEP_SPD = 150
local CREEP_ACCEL = 300
local CREEP_CATCHUP_SPD = 2400
local CREEP_CATCHUP_ACCEL = 4000
local CREEP_REAR_SCAN_DIST = 800
local CREEP_GOAL_THRESH = 120
local CREEP_PATH_AGE = 0.08
local CREEP_AHEAD_DIST = 70
-- local CREEP_LIFETIME_DUR = 20
local CREEP_REAR_SAFE_HALF_ANGLE = 80
local CREEP_REAR_SAFE_DOT = math.cos(math.rad(180 - CREEP_REAR_SAFE_HALF_ANGLE))

ENT.UtilityScores.Creep = function(self, ctx)
	return 0.2
end

ENT.StateEnter.Creep = function(self)
	self:HandleSpeed(CREEP_SPD, CREEP_ACCEL)
	self.GlobalContext.TargetLastSeenTime = CurTime()
	self.GlobalContext.TargetLastSeenPos = self.GlobalContext.Target:GetPos()
	self:ComputeRoutingPath(self.GlobalContext.Target, CREEP_AHEAD_DIST, CREEP_GOAL_THRESH, "Chase")

	self.StateContext.Creep = {
		CreepStartTime = CurTime(),
	}
end

ENT.StateUpdate.Creep = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	if ctx.Visible then
		self.GlobalContext.TargetLastSeenTime = CurTime()
		self.GlobalContext.TargetLastSeenPos = ctx.Target:GetPos()
		self:RecordLastSeenPosition(ctx.Target:GetPos())
	end

	local dirToBot = (self:GetPos() - ctx.Target:GetPos()):GetNormalized()
	local targetForward = ctx.Target:GetForward()
	local dot = targetForward:Dot(dirToBot)

	if dot > CREEP_REAR_SAFE_DOT then
		local rearSpot = self:FindRearSpot(CREEP_REAR_SCAN_DIST)
		if rearSpot then
			self:ComputeRoutingPath(rearSpot, CREEP_AHEAD_DIST, CREEP_GOAL_THRESH, "Follow")
		end
		self:HandleSpeed(CREEP_CATCHUP_SPD, CREEP_CATCHUP_ACCEL)
	else
		self:ComputeRoutingPath(ctx.Target, CREEP_AHEAD_DIST, CREEP_GOAL_THRESH, "Chase")
		self:HandleSpeed(CREEP_SPD, CREEP_ACCEL)
	end

	self:RefreshPathIfStale(CREEP_PATH_AGE, ctx.Target, "Chase")
	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

-- function ENT:StateCreep()
-- 	self.Target = self:FindClosestPlayer()
-- 	if not IsValid(self.Target) then
-- 		self:SetState("Wander")
-- 		return
-- 	end

-- 	self:HandleSpeed(CREEP_SPD, CREEP_ACCEL)
-- 	self:ComputeRoutingPath(self.Target, CREEP_AHEAD_DIST, CREEP_GOAL_THRESH, "Chase")

-- 	local creepStartTime = CurTime()

-- 	while IsValid(self.Target) and self.Target:Alive() do
-- 		if self:IsTouchingPlayer(self.Target) then
-- 			-- DO SOMETHING
-- 		end

-- 		if self:IsTargetVisible(self.Target) then
-- 			self.TargetLastSeenTime = CurTime()
-- 			self.TargetLastSeenPos = self.Target:GetPos()
-- 			self:RecordLastSeenPosition(self.Target:GetPos())
-- 		end

-- 		if CurTime() - creepStartTime > CREEP_LIFETIME_DUR then
-- 			self:SetState("Wander")
-- 			return
-- 		end

-- 		local dirToBot = (self:GetPos() - self.Target:GetPos()):GetNormalized()
-- 		local targetForward = self.Target:GetForward()
-- 		local dot = targetForward:Dot(dirToBot)

-- 		if dot > CREEP_REAR_SAFE_DOT then
-- 			local rearSpot = self:FindRearSpot(CREEP_REAR_SCAN_DIST)
-- 			if rearSpot then
-- 				self:ComputeRoutingPath(rearSpot, CREEP_AHEAD_DIST, CREEP_GOAL_THRESH, "Follow")
-- 			end
-- 			self:HandleSpeed(CREEP_CATCHUP_SPD, CREEP_CATCHUP_ACCEL)
-- 		else
-- 			self:ComputeRoutingPath(self.Target, CREEP_AHEAD_DIST, CREEP_GOAL_THRESH, "Chase")
-- 			self:HandleSpeed(CREEP_SPD, CREEP_ACCEL)
-- 		end

-- 		self:RefreshPathIfStale(CREEP_PATH_AGE, self.Target, "Chase")
-- 		self.Path:Update(self)
-- 		self:ClearObstacles()
-- 		coroutine.yield()
-- 	end
-- end
