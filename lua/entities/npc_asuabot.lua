AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "Asuabot"
ENT.Category = "Nextbot"
ENT.Spawnable = true

-- state transitions
ENT.StateEnter = {}
ENT.StateUpdate = {}
ENT.StateExit = {}

-- bucket transitions
ENT.BucketEnter = {}
ENT.BucketUpdate = {}
ENT.BucketExit = {}

-- state scores
ENT.UtilityScores = {}

-- persistent memory
ENT.GlobalContext = {}

-- bucket-level scores
ENT.UtilityBuckets = {}

-- which state belong to which bucket
ENT.BucketStates = {}

-- state memory
ENT.StateContext = {}

if CLIENT then
	local botMaterial = Material("vgui/entities/npc_asuabot")

	function ENT:Draw()
		render.SetMaterial(botMaterial)
		render.DrawSprite(self:GetPos() + Vector(0, 0, 50), 100, 100, color_white)
	end

	CreateClientConVar("asuabot_debug_hud", "1", true, false, "Show Asuabot UtilityAI Debug HUD")

	hook.Add("PopulateToolMenu", "AsuabotOptionsMenu", function()
		spawnmenu.AddToolMenuOption(
			"Options",
			"Asuabot",
			"AsuabotControlPanel",
			"Control Panel",
			"",
			"",
			function(panel)
				panel:ClearControls()
				panel:CheckBox("Show Utility AI Debug HUD", "asuabot_debug_hud")
			end
		)
	end)

	-- debug data
	local debugData = {}
	net.Receive("AsuabotDebug", function()
		local ent = net.ReadEntity()
		if not IsValid(ent) then
			return
		end

		debugData[ent] = {
			bucketScores = net.ReadTable(),
			bucketTraces = net.ReadTable(),
			bestBucket = net.ReadString(),
			scores = net.ReadTable(),
			traces = net.ReadTable(),
			best = net.ReadString(),
			cooldown = net.ReadTable(),
			bucketCooldown = net.ReadTable(),
			time = CurTime(),
		}
	end)

	hook.Add("HUDPaint", "TestHUD", function()
		if not GetConVar("asuabot_debug_hud"):GetBool() then
			return
		end

		local y = 100
		for ent, data in pairs(debugData) do
			if not IsValid(ent) or CurTime() - data.time > 1 then
				debugData[ent] = nil
				continue
			end

			draw.SimpleText("BUCKETS", "DermaDefaultBold", 20, y, Color(255, 255, 255), TEXT_ALIGN_LEFT)
			y = y + 16

			for name, score in pairs(data.bucketScores) do
				local color = (name == data.bestBucket) and Color(255, 220, 80) or color_white
				draw.SimpleText(
					name .. ": " .. string.format("%.2f", score),
					"DermaDefault",
					30,
					y,
					color,
					TEXT_ALIGN_LEFT
				)
				y = y + 16

				local cdUntil = data.bucketCooldown[name]
				if cdUntil and cdUntil > CurTime() then
					local remaining = cdUntil - CurTime()
					draw.SimpleText(
						"  CD: " .. string.format("%.1f", remaining) .. "s",
						"DermaDefault",
						40,
						y,
						Color(255, 100, 100),
						TEXT_ALIGN_LEFT
					)
					y = y + 16
				end

				for key, val in pairs(data.bucketTraces[name] or {}) do
					draw.SimpleText(
						"  " .. key .. ": " .. string.format("%.2f", val),
						"DermaDefault",
						40,
						y,
						Color(180, 180, 180),
						TEXT_ALIGN_LEFT
					)
					y = y + 16
				end
			end

			y = y + 16

			draw.SimpleText(
				"STATES (" .. data.bestBucket .. ")",
				"DermaDefaultBold",
				20,
				y,
				Color(255, 255, 255),
				TEXT_ALIGN_LEFT
			)
			y = y + 16

			for name, score in pairs(data.scores) do
				local color = (name == data.best) and Color(255, 220, 80) or color_white
				draw.SimpleText(
					name .. ": " .. string.format("%.2f", score),
					"DermaDefault",
					30,
					y,
					color,
					TEXT_ALIGN_LEFT
				)
				y = y + 16

				local cdUntil = data.cooldown[name]
				if cdUntil and cdUntil > CurTime() then
					local remaining = cdUntil - CurTime()
					draw.SimpleText(
						"  CD: " .. string.format("%.1f", remaining) .. "s",
						"DermaDefault",
						40,
						y,
						Color(255, 100, 100),
						TEXT_ALIGN_LEFT
					)
					y = y + 16
				end

				for key, val in pairs(data.traces[name] or {}) do
					draw.SimpleText(
						"  " .. key .. ": " .. string.format("%.2f", val),
						"DermaDefault",
						40,
						y,
						Color(180, 180, 180),
						TEXT_ALIGN_LEFT
					)
					y = y + 16
				end
			end

			y = y + 16
		end
	end)
	-- debug data
end

if SERVER then
	util.AddNetworkString("AsuabotDebug")

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

			CurrentBucket = nil,
			PreviousBucket = nil,
			BucketStartTime = 0,
			BucketCooldownUntil = {},

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

			-- debug
			DebugBucketScores = nil,
			DebugBucketTraces = nil,
			DebugBestBucket = nil,
			DebugScores = nil,
			DebugTraces = nil,
			DebugBest = nil,
			DebugCooldown = nil,
		}

		self.StateContext = {}
	end

	-- Nextbot loop
	function ENT:RunBehaviour()
		while true do
			local ctx = self:SampleContext()
			local nextState = self:SelectState(ctx)

			if self.GlobalContext.DebugBestBucket ~= self.GlobalContext.CurrentBucket then
				local onBucketExit = self.BucketExit[self.GlobalContext.CurrentBucket]
				if onBucketExit then
					onBucketExit(self)
				end

				self.GlobalContext.PreviousBucket = self.GlobalContext.CurrentBucket
				self.GlobalContext.CurrentBucket = self.GlobalContext.DebugBestBucket
				self.GlobalContext.BucketStartTime = CurTime()

				local onBucketEnter = self.BucketEnter[self.GlobalContext.CurrentBucket]
				if onBucketEnter then
					onBucketEnter(self)
				end
			end

			if self.GlobalContext.DebugScores and CurTime() - (self.NextDebugSend or 0) > 0.2 then
				self.NextDebugSend = CurTime()

				net.Start("AsuabotDebug")
				net.WriteEntity(self)
				net.WriteTable(self.GlobalContext.DebugBucketScores or {})
				net.WriteTable(self.GlobalContext.DebugBucketTraces or {})
				net.WriteString(self.GlobalContext.DebugBestBucket or "")
				net.WriteTable(self.GlobalContext.DebugScores or {})
				net.WriteTable(self.GlobalContext.DebugTraces or {})
				net.WriteString(self.GlobalContext.DebugBest or "")
				net.WriteTable(self.GlobalContext.DebugCooldown or {})
				net.WriteTable(self.GlobalContext.DebugBucketCooldown or {})
				net.Broadcast()
			end

			if nextState ~= self.GlobalContext.CurrentState then
				local onExit = self.StateExit[self.GlobalContext.CurrentState]
				if onExit then
					onExit(self)
				end

				self.GlobalContext.PreviousState = self.GlobalContext.CurrentState
				self.GlobalContext.CurrentState = nextState
				self.GlobalContext.StateStartTime = CurTime()

				-- reset stuck baseline for all state enter
				self.GlobalContext.ProgressPosition = self:GetPos()
				self.GlobalContext.ProgressTime = CurTime()

				local onEnter = self.StateEnter[self.GlobalContext.CurrentState]
				if onEnter then
					onEnter(self)
				end
			end

			local onUpdate = self.StateUpdate[self.GlobalContext.CurrentState]
			if onUpdate then
				onUpdate(self, ctx)
			end

			if GetConVar("asuabot_debug_hud"):GetBool() then
				self.GlobalContext.Path:Draw()
			end

			coroutine.yield()
		end
	end
end
