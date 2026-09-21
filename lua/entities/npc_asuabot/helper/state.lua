function ENT:SetState(newState)
	local onExit = self.StateExit and self.StateExit[self.CurrentState]
	if onExit then
		onExit(self)
	end

	self.CurrentState = newState

	local onEnter = self.StateEnter and self.StateEnter[newState]
	if onEnter then
		onEnter(self)
	end
end

--- rolls a weighted chance
--- @param choices table array of { chance = number, value = string }
--- @return nil
function ENT:WeightedRoll(choices)
	local roll = math.random()
	local cumulative = 0

	for _, choice in ipairs(choices) do
		cumulative = cumulative + choice.chance
		if roll < cumulative then
			return choice.value
		end
	end

	return nil
end
