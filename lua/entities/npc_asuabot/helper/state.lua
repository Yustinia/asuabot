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
