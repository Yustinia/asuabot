local CHASE_SPD = 600
local CHASE_ACCEL = 300
local CHASE_GOAL_THRESH = 0
local CHASE_AHEAD_DIST = 140
local CHASE_DMG = 20
local CHASE_LIFETIME_DUR = 12
local CHASE_PATH_AGE = 0.1
local CHASE_LOST_TARGET_DUR = 5

local RUSH_SPD = 1200
local RUSH_ACCEL = 1200
local RUSH_GOAL_THRESH = 0
local RUSH_AHEAD_DIST = 300
local RUSH_DMG = 40
local RUSH_LIFETIME_DUR = 20
local RUSH_PATH_AGE = 0.1

function ENT:StateChase()
	self:HandleSpeed(CHASE_SPD, CHASE_ACCEL)

	self.Target = self:GetClosestPlayer()
	if not IsValid(self.Target) then
		self.CurrentState = "Wander"
		return
	end

	self.Path = Path("Chase")
	self:ConfigFollowPath(CHASE_AHEAD_DIST, CHASE_GOAL_THRESH)
	self.Path:Chase(self, self.Target)

	local chaseStartTime = CurTime()
	self.TargetLastSeenTime = CurTime()

	while IsValid(self.Target) and self.Target:Alive() do
		if self:IsTouchingPlayer(self.Target) then
			self:DealDmgOnContact(self.Target, CHASE_DMG)

			if math.random(1, 2) == 1 then
				self:TeleportToDistantNavSpot()
			end

			self.CurrentState = "Wander"
			return
		end

		if self:IsLineOfSightClear(self.Target) then
			self.TargetLastSeenTime = CurTime()
			self.TargetLastSeenPos = self.Target:GetPos()
			self:RecordLastSeenPosition(self.Target:GetPos())
		elseif CurTime() - self.TargetLastSeenTime > CHASE_LOST_TARGET_DUR then
			self.CurrentState = "Wander"
			return
		end

		if CurTime() - chaseStartTime > CHASE_LIFETIME_DUR then
			self.CurrentState = "Wander"
			return
		end

		if self.Path:GetAge() >= CHASE_PATH_AGE then
			self.Path:Chase(self, self.Target)
		end

		self.Path:Update(self)
		self:ClearObstacles()
		coroutine.yield()
	end
end

function ENT:StateRush()
	self:HandleSpeed(RUSH_SPD, RUSH_ACCEL)

	self.Target = self:GetClosestPlayer()
	if not IsValid(self.Target) then
		self.CurrentState = "Wander"
		return
	end

	self.Path = Path("Chase")
	self:ConfigFollowPath(RUSH_AHEAD_DIST, RUSH_GOAL_THRESH)
	self.Path:Chase(self, self.Target)

	local chaseStartTime = CurTime()
	self.TargetLastSeenTime = CurTime()

	while IsValid(self.Target) and self.Target:Alive() do
		if self:IsTouchingPlayer(self.Target) then
			self:DealDmgOnContact(self.Target, RUSH_DMG)

			if math.random(1, 2) == 1 then
				self:TeleportToDistantNavSpot()
			end

			self.CurrentState = "Wander"
			return
		end

		if self:IsLineOfSightClear(self.Target) then
			self.TargetLastSeenTime = CurTime()
			self.TargetLastSeenPos = self.Target:GetPos()
			self:RecordLastSeenPosition(self.Target:GetPos())
		end

		if CurTime() - chaseStartTime > RUSH_LIFETIME_DUR then
			self.CurrentState = "Wander"
			return
		end

		if self.Path:GetAge() >= RUSH_PATH_AGE then
			self.Path:Chase(self, self.Target)
		end

		self.Path:Update(self)
		self:ClearObstacles()
		coroutine.yield()
	end
end
