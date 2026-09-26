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

		local scores = net.ReadTable()
		local traces = net.ReadTable()
		local best = net.ReadString()
		local cooldowns = net.ReadTable()
		local sweepIndex = net.ReadUInt(8)
		local sweepTotal = net.ReadUInt(8)

		local posCount = net.ReadUInt(8)
		local positions = {}
		for i = 1, posCount do
			positions[i] = net.ReadVector()
		end

		debugData[ent] = {
			scores = scores,
			traces = traces,
			best = best,
			cooldowns = cooldowns,
			sweepIndex = sweepIndex,
			sweepTotal = sweepTotal,
			positions = positions,
			time = CurTime(),
		}
	end)
	hook.Add("HUDPaint", "TestHUD", function()
		local y = 100
		for ent, data in pairs(debugData) do
			if not IsValid(ent) or CurTime() - data.time > 1 then
				debugData[ent] = nil
				continue
			end

			for name, score in pairs(data.scores) do
				local color = (name == data.best) and Color(225, 220, 80) or color_white
				draw.SimpleText(
					name .. " : " .. string.format("%.2f", score),
					"DermaDefault",
					20,
					y,
					color,
					TEXT_ALIGN_LEFT
				)
				y = y + 16

				if name == "Sweep" and data.sweepTotal > 0 then
					draw.SimpleText(
						"  Point " .. data.sweepIndex .. "/" .. data.sweepTotal,
						"DermaDefault",
						40,
						y,
						Color(150, 200, 255),
						TEXT_ALIGN_LEFT
					)
					y = y + 16
				end

				if name == "Patrol" and #data.positions > 0 then
					for i, pos in ipairs(data.positions) do
						draw.SimpleText(
							"  [" .. i .. "] " .. tostring(pos),
							"DermaDefault",
							40,
							y,
							Color(150, 255, 180),
							TEXT_ALIGN_LEFT
						)
						y = y + 16
					end
				end

				for key, val in pairs(data.traces[name] or {}) do
					draw.SimpleText(
						"  " .. key .. " : " .. string.format("%.2f", val),
						"DermaDefault",
						40,
						y,
						Color(180, 180, 180),
						TEXT_ALIGN_LEFT
					)
					y = y + 16
				end

				local cdUntil = data.cooldowns[name]
				if cdUntil and cdUntil > CurTime() then
					local remaining = cdUntil - CurTime()
					draw.SimpleText(
						"  CD: " .. string.format("%.2f", remaining) .. "s",
						"DermaDefault",
						40,
						y,
						Color(255, 100, 100),
						TEXT_ALIGN_LEFT
					)
					y = y + 16
				end
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

		-- Navmesh cache
		-- self.Doors = self:FindAllDoors()

		-- Spawn Initialization
		-- self:TeleportToDistantNavSpot()

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

			InterceptLastRecompute = 0,
			PatrolIndex = 0,

			-- debug
			DebugScores = nil,
			DebugBest = nil,
			DebugTraces = nil,
			DebugCD = {},
		}

		self.StateContext = {}
	end

	-- Nextbot loop
	function ENT:RunBehaviour()
		while true do
			local ctx = self:SampleContext()
			local nextState = self:SelectState(ctx)

			-- debug data
			if self.GlobalContext.DebugScores and CurTime() - (self.NextDebugSent or 0) > 0.2 then
				self.NextDebugSent = CurTime()

				net.Start("AsuabotDebug")
				net.WriteEntity(self)
				net.WriteTable(self.GlobalContext.DebugScores)
				net.WriteTable(self.GlobalContext.DebugTraces)
				net.WriteString(self.GlobalContext.DebugBest or "")
				net.WriteTable(self.GlobalContext.DebugCD or {})
				net.WriteUInt(self.GlobalContext.DebugSweepIndex, 8)
				net.WriteUInt(self.GlobalContext.DebugSweepTotal, 8)

				local positions = self.GlobalContext.DebugLastSeenPositions or {}
				net.WriteUInt(#positions, 8)
				for i = 1, #positions do
					net.WriteVector(positions[i])
				end

				net.Broadcast()
			end
			-- debug data

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
