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

CreateConVar("asuabot_debug_hud", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Show Asuabot debug HUD")

if CLIENT then
	local botMaterial = Material("vgui/entities/npc_asuabot")

	function ENT:Draw()
		render.SetMaterial(botMaterial)
		render.DrawSprite(self:GetPos() + Vector(0, 0, 50), 100, 100, color_white)
	end

	local debugData = {}

	net.Receive("AsuabotDebug", function()
		local ent = net.ReadEntity()
		if not IsValid(ent) then
			return
		end

		debugData[ent] = {
			state = net.ReadString(),
			stateTime = net.ReadFloat(),
			min = net.ReadFloat(),
			max = net.ReadFloat(),
			locked = net.ReadBool(),
			scores = net.ReadTable(),
			traces = net.ReadTable(),
			cooldown = net.ReadTable(),
			time = CurTime(),
		}
	end)

	hook.Add("HUDPaint", "AsuabotHUD", function()
		if not GetConVar("asuabot_debug_hud"):GetBool() then
			return
		end

		local y = 100
		local function line(text, x, col)
			draw.SimpleText(text, "DermaDefault", x, y, col or color_white)
			y = y + 16
		end

		for ent, d in pairs(debugData) do
			if not IsValid(ent) or CurTime() - d.time > 1 then
				debugData[ent] = nil
				continue
			end

			line(
				string.format("STATE: %s  %.1fs  (min %.0f / max %.0f)", d.state, d.stateTime, d.min, d.max),
				20,
				Color(255, 220, 80)
			)
			line(d.locked and "LOCKED" or "open", 20, d.locked and Color(255, 100, 100) or Color(100, 255, 100))

			for name, score in pairs(d.scores) do
				local col = (name == d.state) and Color(255, 220, 80) or color_white
				line(name .. ": " .. string.format("%.2f", score), 30, col)

				local cdUntil = d.cooldown[name]
				if cdUntil and cdUntil > CurTime() then
					line("CD: " .. string.format("%.1f", cdUntil - CurTime()) .. "s", 40, Color(255, 100, 100))
				end

				for key, val in pairs(d.traces[name] or {}) do
					line(key .. ": " .. string.format("%.2f", val), 40, Color(180, 180, 180))
				end
			end

			y = y + 16
		end
	end)

	-- npc_asuabot.lua, inside `if CLIENT then`
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
				panel:CheckBox("Show Debug HUD", "asuabot_debug_hud")
			end
		)
	end)
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
			DebugScores = {},
			DebugTraces = {},
		}

		self.StateContext = {}
	end

	-- Nextbot loop
	function ENT:RunBehaviour()
		while true do
			local ctx = self:SampleContext()
			local glb = self.GlobalContext
			local scores, best = self:ScoreStates(ctx)
			local locked = self:IsLocked(ctx)

			if not glb.CurrentState then
				self:SwitchState("Wander")
			elseif not locked then
				local nextState = self:SelectState(scores, best)

				if nextState ~= glb.CurrentState then
					self:SwitchState(nextState)
				end
			end

			self:SendDebug(ctx, locked)

			local update = self.StateUpdate[glb.CurrentState]
			if update then
				update(self, ctx)
			end

			if GetConVar("asuabot_debug_hud"):GetBool() then
				if glb.Path and glb.Path:IsValid() then
					glb.Path:Draw()
				end
			end

			coroutine.yield()
		end
	end
end
