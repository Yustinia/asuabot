local RUSH_SPD = 1400
local RUSH_ACCEL = 1200
local RUSH_GOAL_THRESH = 0
local RUSH_AHEAD_DIST = 300
local RUSH_DMG = 40
local RUSH_PATH_AGE = 0.1
local RUSH_MIN_DIST = 2500
local RUSH_MAX_DIST = 5000

ENT.UtilityScores.Rush = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0.0
	end
	if not ctx.Visible then
		return 0.0
	end
	if ctx.Distance < RUSH_MIN_DIST then
		return 0.0
	end
	if ctx.Distance > RUSH_MAX_DIST then
		return 0.0
	end

	local urgency = Consider(ctx.Distance, RUSH_MIN_DIST, RUSH_MAX_DIST, Curves.LinearIn)

	if trace then
		trace.Urgency = urgency
	end

	return urgency
end

ENT.StateEnter.Rush = function(self)
	self:HandleSpeed(RUSH_SPD, RUSH_ACCEL)
	self.GlobalContext.TargetLastSeenTime = CurTime()
	self.GlobalContext.InterceptLastRecompute = 0
	self:ComputeRoutingPath(self.GlobalContext.Target, RUSH_AHEAD_DIST, RUSH_GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Rush = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, RUSH_DMG)
		return
	end

	if ctx.Visible then
		self.GlobalContext.TargetLastSeenTime = CurTime()
		self.GlobalContext.TargetLastSeenPos = ctx.Target:GetPos()
		self:RecordLastSeenPosition(ctx.Target:GetPos())
	end

	self:RefreshPathIfStale(RUSH_PATH_AGE, ctx.Target, "Chase")
	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

-- function ENT:StateRush()
-- 	self:HandleSpeed(RUSH_SPD, RUSH_ACCEL)

-- 	self.Target = self:FindClosestPlayer()
-- 	if not IsValid(self.Target) then
-- 		self:SetState("Wander")
-- 		return
-- 	end

-- 	self:ComputeRoutingPath(self.Target, RUSH_AHEAD_DIST, RUSH_GOAL_THRESH, "Chase")

-- 	local chaseStartTime = CurTime()

-- 	while IsValid(self.Target) and self.Target:Alive() do
-- 		if self:IsTouchingPlayer(self.Target) then
-- 			self:DamageEntity(self.Target, RUSH_DMG)

-- 			if math.random(1, 2) == 1 then
-- 				self:TeleportToDistantNavSpot()
-- 			end

-- 			self:SetState("Wander")
-- 			return
-- 		end

-- 		if self:IsTargetVisible(self.Target) then
-- 			self.TargetLastSeenTime = CurTime()
-- 			self.TargetLastSeenPos = self.Target:GetPos()
-- 			self:RecordLastSeenPosition(self.Target:GetPos())
-- 		end

-- 		if CurTime() - chaseStartTime > RUSH_LIFETIME_DUR then
-- 			self:SetState("Wander")
-- 			return
-- 		end

-- 		self:RefreshPathIfStale(RUSH_PATH_AGE, self.Target, "Chase")

-- 		self.Path:Update(self)
-- 		self:ClearObstacles()
-- 		coroutine.yield()
-- 	end
-- end
