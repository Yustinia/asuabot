AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

include("entities/npc_asuabot/ability/init.lua")
include("entities/npc_asuabot/helper/init.lua")
include("entities/npc_asuabot/states/init.lua")
include("entities/npc_asuabot/player/init.lua")

ENT.States = {
	Wander = ENT.StateWander,
	Chase = ENT.StateChase,
	Rush = ENT.StateRush,
	Blink = ENT.StateBlink,
	Flee = ENT.StateFlee,
	Hide = ENT.StateHide,
	Retreat = ENT.StateRetreat,
	Creep = ENT.StateCreep,
	Pounce = ENT.StatePounce,
	AmbushApproach = ENT.StateAmbushApproach,
	AmbushTP = ENT.StateAmbushTP,
	Investigate = ENT.StateInvestigate,
	Patrol = ENT.StatePatrol,
	Peek = ENT.StatePeek,
	Stare = ENT.StateStare,
	-- Stalk = ENT.StateStalk,
	-- Rage = ENT.StateRage,
	Sweep = ENT.StateSweep,
}

ENT.StateEnter = {
	Wander = function(self)
		self.ProgressPos = self:GetPos()
		self.ProgressTime = CurTime()
	end,
	Chase = function(self)
		self.TargetLastSeenTime = CurTime()
	end,
	Rush = function(self)
		self.TargetLastSeenTime = CurTime()
	end,
	Blink = function(self)
		self.TargetLastSeenTime = CurTime()
	end,
	Flee = function(self)
		self.ProgressPos = self:GetPos()
		self.ProgressTime = CurTime()
	end,
	Hide = function(self)
		self.TargetLastSeenTime = CurTime()
	end,
	Creep = function(self)
		self.TargetLastSeenTime = CurTime()
	end,
	Pounce = function(self)
		self.TargetLastSeenTime = CurTime()
	end,
	AmbushApproach = function(self)
		self.TargetLastSeenTime = CurTime()
	end,
	Investigate = function(self)
		self.ProgressPos = self:GetPos()
		self.ProgressTime = CurTime()
	end,
	Patrol = function(self)
		self.ProgressPos = self:GetPos()
		self.ProgressTime = CurTime()
	end,
	Peek = function(self)
		self.ProgressPos = self:GetPos()
		self.ProgressTime = CurTime()
	end,
}

ENT.StateExit = {
	Stare = function(self)
		self.Path = nil
		self.PathMode = nil
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
	self:SetSolid(0)
	self:SetCollisionGroup(10)
	self:SetCollisionBounds(Vector(-1, -1, 0), Vector(1, 1, 1))
	self.loco:SetAvoidAllowed(true)

	-- NextBot vision
	self:SetFOV(360)
	self:SetMaxVisionRange(99999999)

	-- NextBot ability
	self.loco:SetStepHeight(40)
	self.loco:SetJumpHeight(80)
	self.loco:SetDeathDropHeight(200)
	self.loco:SetJumpGapsAllowed(true)

	-- Navmesh cache
	self.CachedNavAreas = navmesh.GetAllNavAreas()
	-- self.Doors = self:FindAllDoors()

	-- AI State
	self.CurrentState = "Stare"

	self.Target = nil
	self.TargetLastSeenPos = nil
	self.TargetLastSeenTime = 0

	self.LastSeenTargetPositions = {}
	self.LastSeenTargetSize = 5
	self.LastSeenRecordInterval = 12
	self.LastSeenRecordTime = 0
	self.LastSeenRecordMinDist = 1000

	self.PlayerList = {}

	self.Path = nil
	self.PathMode = nil

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
