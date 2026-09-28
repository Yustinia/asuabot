local SURVEY_SPEED = 600
local SURVEY_ACCEL = 600
local SURVEY_GOAL_THRESH = 120
local SURVEY_SCAN_RAD = 3000
local SURVEY_PATH_AGE = 0.1
local SURVEY_AHEAD_DIST = 40
local SURVEY_LIFETIME_DUR = 40
local SURVEY_COOLDOWN_DUR = 90
local SURVEY_STOP_TIME = 5

ENT.UtilityScores.Survey = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0.0
	end

	local surveyTime = (ctx.CurrentState == "Survey") and ctx.StateTime or 0
	local stamina = Consider(surveyTime, 0, SURVEY_LIFETIME_DUR, Curves.LinearInverse)

	if trace then
		trace.Stamina = stamina
	end

	local score = WeightedGeoMean({
		{ score = stamina, weight = 1.4 },
	})

	return score
end

ENT.StateEnter.Survey = function(self)
	self:HandleSpeed(SURVEY_SPEED, SURVEY_ACCEL)

	self.StateContext.Survey = {
		TargetPosition = self:FindNearbyNavArea(SURVEY_SCAN_RAD),
		WaitUntil = 0,
	}

	local ctxSurvey = self.StateContext.Survey
	self:ComputeRoutingPath(ctxSurvey.TargetPosition, SURVEY_AHEAD_DIST, SURVEY_GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Survey = function(self, ctx)
	local ctxSurvey = self.StateContext.Survey

	if not self.GlobalContext.Path or not self.GlobalContext.Path:IsValid() then
		return
	end

	if CurTime() < ctxSurvey.WaitUntil then
		return
	end

	if self:IsAtPosition(ctxSurvey.TargetPosition, SURVEY_GOAL_THRESH) then
		if ctxSurvey.WaitUntil == 0 then
			ctxSurvey.WaitUntil = CurTime() + SURVEY_STOP_TIME
			return
		end

		ctxSurvey.TargetPosition = self:FindNearbyNavArea(SURVEY_SCAN_RAD)
		ctxSurvey.WaitUntil = 0
		self:ComputeRoutingPath(ctxSurvey.TargetPosition, SURVEY_AHEAD_DIST, SURVEY_GOAL_THRESH, "Follow")
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(SURVEY_PATH_AGE, ctxSurvey.TargetPosition, "Follow")
	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Survey = function(self)
	self.GlobalContext.CooldownUntil["Survey"] = CurTime() + SURVEY_COOLDOWN_DUR
end
