AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "Asuabot"
ENT.Category = "Nextbot"
ENT.Spawnable = true

ENT.StateEnter = {}
ENT.StateUpdate = {}
ENT.StateExit = {}
ENT.StateRules = {}
ENT.StateContext = {}

ENT.UtilityScores = {}

if CLIENT then
	local botMaterial = Material("vgui/entities/npc_asuabot")

	function ENT:Draw()
		render.SetMaterial(botMaterial)
		render.DrawSprite(self:GetPos() + Vector(0, 0, 50), 100, 100, color_white)
	end
end

if SERVER then
	include("entities/npc_asuabot/init.lua")

	function ENT:Initialize()
		-- Model / appearance
		self:SetModel("models/player/kleiner.mdl")
		self:SetSpawnEffect(false)

		-- Health
		self:SetHealth(99999999)
		self:SetMaxHealth(99999999)

		-- Collision / movement
		self:SetSolid(SOLID_NONE)
		self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		self:SetCollisionBounds(Vector(-1, -1, 0), Vector(1, 1, 1))
		self.loco:SetAvoidAllowed(true)

		-- NextBot vision
		self:SetFOV(360)
		self:SetMaxVisionRange(99999999)

		-- NextBot ability
		self.loco:SetStepHeight(40)
		self.loco:SetJumpHeight(30)
		self.loco:SetDeathDropHeight(800)
		self.loco:SetJumpGapsAllowed(true)

		self.GlobalContext = {
			CurrentState = nil,
			PreviousState = nil,
			StateStartTime = 0,
			CooldownUntil = {},

			CachedNavmesh = navmesh.GetAllNavAreas(),

			Target = nil,
			TargetList = {},
			TargetLastSeenPos = nil,
			TargetLastSeenTime = 0,

			LastSeenTargetPositions = {},
			LastSeenTargetSize = 5,
			LastSeenRecordInterval = 12,
			LastSeenRecordTime = 0,
			LastSeenRecordMinDist = 1000,

			Path = nil,
			PathMode = nil,

			NextPushTime = 0,
			NextDamageTime = 0,
			NextPullTime = 0,
			NextPunchTime = 0,

			StuckTries = 0,
			StuckMaxAttempts = 3,
			LastStuckTime = 0,

			ProgressPosition = nil,
			ProgressTime = 0,
		}

		self.StateContext = {}
	end

	-- Nextbot loop
	function ENT:RunBehaviour()
		while true do
			local ctx = self:SampleContext()
			local glb = self.GlobalContext

			if not glb.CurrentState then
				self:SwitchState("Wander")
			elseif not self:IsLocked() then
				local nextState = self:SelectState(ctx)

				if nextState ~= glb.CurrentState then
					self:SwitchState(nextState)
				end
			end

			local update = self.StateUpdate[glb.CurrentState]
			if update then
				update(self, ctx)
			end

			glb.Path:Draw()

			coroutine.yield()
		end
	end
end
