function Consider(raw, lo, hi, curveFn)
	local x = math.Clamp((raw - lo) / (hi - lo), 0, 1)
	return curveFn(x)
end

function WeightedGeoMean(entries)
	local acc, sumW = 0, 0

	for _, e in pairs(entries) do
		if e.score <= 0 then
			return 0
		end

		acc = acc + e.weight * math.log(e.score)
		sumW = sumW + e.weight
	end

	return math.exp(acc / sumW)
end

local STATE_MARGIN = 0.8

function ENT:SampleContext()
	local g, c = self.GlobalContext, {}

	if not IsValid(g.Target) then
		g.Target = self:FindNearestPlayer()
	end

	c.Target = g.Target
	c.TargetValid = IsValid(c.Target) and c.Target:Alive()

	c.Distance = math.huge
	c.Touching = false
	c.Visible = false
	c.Observe = false
	c.PlayerSpeed = 0

	if c.TargetValid then
		c.Distance = self:GetPos():Distance(c.Target:GetPos())
		c.Touching = self:IsTouchingPlayer(c.Target)
		c.Visible = self:IsTargetVisibleFromBot(c.Target)
		c.Observe = self:IsPlayerLookingAtBot(c.Target)
		c.PlayerSpeed = c.Target:GetVelocity():Length2D()

		if c.Visible then
			g.TargetLastSeenTime = CurTime()
			g.TargetLastSeenPos = c.Target:GetPos()
			self:RecordLastSeenPosition(c.Target:GetPos())
		end
	end

	c.LastSeenAge = CurTime() - g.TargetLastSeenTime
	c.StateTime = CurTime() - g.StateStartTime
	c.CurrentState = g.CurrentState

	return c
end

function ENT:IsLocked(ctx)
	local g = self.GlobalContext
	local rules = self.StateRules[g.CurrentState]

	if not rules then
		return false
	end

	if rules.needsTarget and not ctx.TargetValid then
		return false
	end

	local t = CurTime() - g.StateStartTime
	if t < (rules.min or 0) then
		return true
	end

	if self.StateContext.InSequence then
		return true
	end

	return false
end

function ENT:SelectState(ctx)
	local glb = self.GlobalContext
	local rules = self.StateRules
	local cur = rules[glb.CurrentState]
	local exp = cur and cur.max and ctx.StateTime >= cur.max

	local scores, traces, best = {}, {}, 0
	for name, scoreFn in pairs(self.UtilityScores) do
		local onCD = CurTime() < (glb.CooldownUntil[name] or 0)
		local blocked = exp and name == glb.CurrentState

		traces[name] = {}
		scores[name] = 0

		if not onCD and not blocked then
			local s = scoreFn(self, ctx, traces[name])
			scores[name] = s
			best = math.max(best, s)
		end
	end

	local candidates = {}
	for name, s in pairs(scores) do
		if s > 0 and s >= best * STATE_MARGIN then
			candidates[#candidates + 1] = name
		end
	end

	glb.DebugScores = scores
	glb.DebugTraces = traces

	if #candidates == 0 then
		return glb.CurrentState
	end

	return candidates[math.random(#candidates)]
end

function ENT:SendDebug(ctx, locked)
	if not GetConVar("asuabot_debug_hud"):GetBool() then
		return
	end
	if CurTime() < (self.NextDebugSend or 0) then
		return
	end
	self.NextDebugSend = CurTime() + 0.2

	local glb = self.GlobalContext
	local rules = self.StateRules[glb.CurrentState] or {}

	net.Start("AsuabotDebug")
	net.WriteEntity(self)
	net.WriteString(glb.CurrentState or "")
	net.WriteFloat(ctx.StateTime)
	net.WriteFloat(rules.min or 0)
	net.WriteFloat(rules.max or 0)
	net.WriteBool(locked)
	net.WriteTable(glb.DebugScores or {})
	net.WriteTable(glb.DebugTraces or {})
	net.WriteTable(glb.CooldownUntil)
	net.Broadcast()
end

function ENT:SwitchState(name)
	local glb = self.GlobalContext
	local old = glb.CurrentState

	if old then
		if self.StateExit[old] then
			self.StateExit[old](self)
		end

		local rules = self.StateRules[old]
		if rules and rules.cd then
			glb.CooldownUntil[old] = CurTime() + rules.cd
		end
	end

	glb.PreviousState, glb.CurrentState, glb.StateStartTime = old, name, CurTime()

	self.StateContext.InSequence = false
	if self.StateEnter[name] then
		self.StateEnter[name](self)
	end
end
