local STALK_SPD = 200
local STALK_ACCEL = 300
local STALK_GOAL_THRESH = 20
local STALK_AHEAD_DIST = 20
local STALK_PATH_AGE = 0.2
local STALK_HALF_ANGLE = 60
local STALK_DIRECT_DOT = math.cos(math.rad(STALK_HALF_ANGLE))

function ENT:StateStalk()
	self.Target = self:FindClosestPlayer()
	if not IsValid(self.Target) then
		self:SetState("Wander")
		return
	end

	self:HandleSpeed(STALK_SPD, STALK_ACCEL)
	self:ComputeRoutingPath(self.Target, STALK_AHEAD_DIST, STALK_GOAL_THRESH, "Chase")

	while IsValid(self.Target) and self.Target:Alive() do
		if self:IsObservedBy(self.Target, STALK_DIRECT_DOT) then
			if math.random(1, 2) == 1 then
				self:SetState("Retreat")
			else
				self:SetState("Chase")
			end
			return
		end

		self:RefreshPathIfStale(STALK_PATH_AGE, self.Target, "Chase")
		self.Path:Update(self)
		self:ClearObstacles()

		coroutine.yield()
	end
end
