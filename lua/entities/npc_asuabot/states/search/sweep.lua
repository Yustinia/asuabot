local SWEEP_SPD = 350
local SWEEP_ACCEL = 400
local SWEEP_GOAL_THRESH = 80
local SWEEP_AHEAD_DIST = 300
local SWEEP_PATH_AGE = 0.1
local SWEEP_WAYPOINT_WAIT = 2

function ENT:StateSweep()
	self:HandleSpeed(SWEEP_SPD, SWEEP_ACCEL)

	local anchorPos = self.TargetLastSeenPos
	if not anchorPos then
		self:SetState("Wander")
		return
	end

	local anchorArea = navmesh.GetNearestNavArea(anchorPos)
	if not IsValid(anchorArea) then
		self:SetState("Wander")
		return
	end

	local sweepPoints = { anchorArea:GetCenter() }
	local adjacent = anchorArea:GetAdjacentAreas()
	for _, area in pairs(adjacent) do
		table.insert(sweepPoints, area:GetCenter())
	end

	for i = 1, #sweepPoints do
		local targetPos = sweepPoints[i]

		if not self:ComputeRoutingPath(targetPos, SWEEP_AHEAD_DIST, SWEEP_GOAL_THRESH, "Follow") then
			self:SetState("Wander")
			return
		end

		while self.Path:IsValid() do
			if self:IsAtPosition(targetPos, SWEEP_GOAL_THRESH) then
				break
			end

			if self:IsTargetVisible(self.Target) then
				self.TargetLastSeenPos = self.Target:GetPos()
				self:RecordLastSeenPosition(self.Target:GetPos())
				self.TargetLastSeenTime = CurTime()

				-- DO SOMETHING
				return
			end

			self:RefreshPathIfStale(SWEEP_PATH_AGE, targetPos, "Follow")
			self.Path:Update(self)
			self:ClearObstacles()

			coroutine.yield()
		end

		if i < #sweepPoints then
			coroutine.wait(SWEEP_WAYPOINT_WAIT)
		end
	end
end
