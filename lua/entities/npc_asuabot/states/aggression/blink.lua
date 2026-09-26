local BLINK_SPD = 2600
local BLINK_ACCEL = 1600
-- local BLINK_LIFETIME_DUR = 12
local BLINK_PATH_AGE = 0.4
-- local BLINK_STARE_LIFETIME_DUR = 4
local BLINK_AHEAD_DIST = 100
local BLINK_GOAL_THRESH = 0
local BLINK_DMG = 20

ENT.UtilityScores.Blink = function(self, ctx)
	return 0.00
end

ENT.StateEnter.Blink = function(self)
	self:HandleSpeed(BLINK_SPD, BLINK_ACCEL)
	self.GlobalContext.TargetLastSeenTime = CurTime()
	self:ComputeRoutingPath(self.GlobalContext.Target, BLINK_AHEAD_DIST, BLINK_GOAL_THRESH, "Chase")

	self.StateContext.Blink = {
		ObservedStartTime = 0,
		BlinkStartTime = CurTime(),
		IsCurrentlyObserved = false,
	}
end

ENT.StateUpdate.Blink = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, BLINK_DMG)
	end

	if ctx.Visible then
		self.GlobalContext.TargetLastSeenTime = CurTime()
		self.GlobalContext.TargetLastSeenPos = ctx.Target:GetPos()
		self:RecordLastSeenPosition(ctx.Target:GetPos())
	end

	local wasObserved = self.StateContext.Blink.IsCurrentlyObserved
	self.StateContext.Blink.IsCurrentlyObserved = self:IsObservedBy(ctx.Target)

	if self.StateContext.Blink.IsCurrentlyObserved then
		self:HandleSpeed(0, 0)

		if not wasObserved then
			self.StateContext.Blink.ObservedStartTime = CurTime()
		end
	else
		self:HandleSpeed(BLINK_SPD, BLINK_ACCEL)

		self:RefreshPathIfStale(BLINK_PATH_AGE, ctx.Target, "Chase")
		self.GlobalContext.Path:Update(self)
		self:ClearObstacles()
	end
end
