AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "Asuabot"
ENT.Category = "Nextbot"
ENT.Spawnable = true

ENT.StateEnter = {}
ENT.StateUpdate = {}
ENT.StateExit = {}
ENT.UtilityScores = {}
ENT.GlobalContext = {}
ENT.StateContext = {}

if CLIENT then
	local botMaterial = Material("vgui/entities/npc_asuabot")

	function ENT:Draw()
		render.SetMaterial(botMaterial)
		render.DrawSprite(self:GetPos() + Vector(0, 0, 50), 100, 100, color_white)
	end

	-- debug data
	local debugData = {}
	net.Receive("AsuabotDebug", function()
		local ent = net.ReadEntity()
		if not IsValid(ent) then
			return
		end

		local time = CurTime()

		debugData[ent] = {
			time = time,
		}
	end)
	hook.Add("HUDPaint", "TestHUD", function()
		local y = 100
		for ent, data in pairs(debugData) do
			if not IsValid(ent) or CurTime() - data.time > 1 then
				debugData[ent] = nil
				continue
			end
		end
	end)
	-- debug data
end

if SERVER then
	util.AddNetworkString("AsuabotDebug")

	include("entities/npc_asuabot/ability/init.lua")
	include("entities/npc_asuabot/helper/init.lua")
	include("entities/npc_asuabot/states/init.lua")
	include("entities/npc_asuabot/player/init.lua")

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
		self.loco:SetJumpHeight(60)
		self.loco:SetDeathDropHeight(200)
		self.loco:SetJumpGapsAllowed(true)

		self.GlobalContext = {
			CurrentState = nil,
			PreviousState = nil,
			StateStartTime = 0,
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

			PushCD = 0.5,
			NextPushTime = 0,

			DamageCD = 0.5,
			NextDamageTime = 0,

			PullCD = 0.5,
			NextPullTime = 0,

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
			local nextState = self:SelectState(ctx)

			if nextState ~= self.GlobalContext.CurrentState then
				local onExit = self.StateExit[self.GlobalContext.CurrentState]
				if onExit then
					onExit(self)
				end

				self.GlobalContext.PreviousState = self.GlobalContext.CurrentState
				self.GlobalContext.CurrentState = nextState
				self.GlobalContext.StateStartTime = CurTime()

				local onEnter = self.StateEnter[self.GlobalContext.CurrentState]
				if onEnter then
					onEnter(self)
				end
			end

			local onUpdate = self.StateUpdate[self.GlobalContext.CurrentState]
			if onUpdate then
				onUpdate(self, ctx)
			end

			self.GlobalContext.Path:Draw()

			coroutine.yield()
		end
	end
end
