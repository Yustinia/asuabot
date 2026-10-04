ENT.BucketStates.Pressure = {
	"Creep",
	"Encroach",
	"Feint",
	"Herd",
	"Loom",
}

ENT.UtilityBuckets.Pressure = function(self, ctx, trace)
	return 0.0
end

ENT.BucketExit.Pressure = function(self) end
