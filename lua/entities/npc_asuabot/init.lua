AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

include("ability/location.lua")
include("ability/maneuver.lua")
include("ability/movement.lua")
include("ability/perception.lua")
include("ability/physical.lua")

include("helper/movement.lua")
include("helper/state.lua")

include("states/state_movement.lua")
include("states/state_aggresion.lua")

ENT.States = {
	Wander = ENT.StateWander,
	Chase = ENT.StateChase,
	Rush = ENT.StateRush,
}

ENT.StateEnter = {
	Wander = function(self)
		self.ProgressPos = self:GetPos()
		self.ProgressTime = CurTime()
	end,
}

function ENT:Initialize()
	-- Model / appearance
	self:SetModel("models/player/kleiner.mdl")
	self:SetSpawnEffect(false)

	-- Health
	self:SetHealth(99999999)
	self:SetMaxHealth(99999999)

	-- Collision / movement
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_NPC)
	self:SetCollisionBounds(Vector(-1, -1, 0), Vector(1, 1, 1))

	-- NextBot vision
	self:SetFOV(360)
	self:SetMaxVisionRange(99999999)

	-- NextBot Status
	self.loco:SetStepHeight(18)
	self.loco:SetJumpHeight(58)
	self.loco:SetDeathDropHeight(200)

	-- Navmesh cache
	self.CachedNavAreas = navmesh.GetAllNavAreas()

	-- AI State
	self.CurrentState = "Wander"

	self.Target = nil
	self.TargetLastSeenPos = nil
	self.TargetLastSeenTime = 0

	self.LastSeenTargetPositions = {}
	self.LastSeenTargetSize = 5
	self.LastSeenRecordInterval = 12
	self.LastSeenRecordTime = 0

	self.PlayerList = {}

	self.Path = nil

	-- Timing
	self.PushCD = 0.5
	self.NextPushTime = 0

	self.DamageCD = 0.5
	self.NextDamageTime = 0

	self.PullCD = 15
	self.NextPullTime = 0

	-- Movement
	self.StuckTries = 0
	self.StuckMax = 3
	self.LastStuck = 0

	self.ProgressPos = nil
	self.ProgressTime = 0

	self.PatrolIndex = 0

	-- Spawn Initialization
	-- self:TeleportToDistantNavSpot()
end

-- Nextbot loop
function ENT:RunBehaviour()
	while true do
		local stateFunc = self.States[self.CurrentState]

		if not stateFunc then
			self.CurrentState = "Wander"
			stateFunc = self.States.Wander
		end

		stateFunc(self)
		coroutine.yield()
	end
end
