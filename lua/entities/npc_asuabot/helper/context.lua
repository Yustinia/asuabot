--- returns the global & state context for quick variable assignment
--- @return table global context
--- @return table state context
function ENT:ReturnContext()
	return self.GlobalContext, self.StateContext
end
