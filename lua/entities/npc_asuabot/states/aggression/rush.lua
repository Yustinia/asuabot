local RUSH_SPD = 1400
local RUSH_ACCEL = 1200
local RUSH_GOAL_THRESH = 0
local RUSH_AHEAD_DIST = 300
local RUSH_DMG = 40
local RUSH_LIFETIME_DUR = 20
local RUSH_PATH_AGE = 0.1

function ENT:StateRush()
	self:HandleSpeed(RUSH_SPD, RUSH_ACCEL)

	self.Target = self:FindClosestPlayer()
	if not IsValid(self.Target) then
		self:SetState("Wander")
		return
	end

	self:ComputeRoutingPath(self.Target, RUSH_AHEAD_DIST, RUSH_GOAL_THRESH, "Chase")

	local chaseStartTime = CurTime()

	while IsValid(self.Target) and self.Target:Alive() do
		if self:IsTouchingPlayer(self.Target) then
			self:DamageEntity(self.Target, RUSH_DMG)

			if math.random(1, 2) == 1 then
				self:TeleportToDistantNavSpot()
			end

			self:SetState("Wander")
			return
		end

		if self:IsTargetVisible(self.Target) then
			self.TargetLastSeenTime = CurTime()
			self.TargetLastSeenPos = self.Target:GetPos()
			self:RecordLastSeenPosition(self.Target:GetPos())
		end

		if CurTime() - chaseStartTime > RUSH_LIFETIME_DUR then
			self:SetState("Wander")
			return
		end

		self:RefreshPathIfStale(RUSH_PATH_AGE, self.Target, "Chase")

		self.Path:Update(self)
		self:ClearObstacles()
		coroutine.yield()
	end
end
