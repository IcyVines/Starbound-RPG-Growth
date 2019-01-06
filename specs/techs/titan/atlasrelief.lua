
function init()
	self.id = effect.sourceEntity()
	self.power = config.getParameter("power", 1.1)
	self.grit = config.getParameter("grit", 1)
 	self.armor = config.getParameter("armor", 1.2)
 	effect.addStatModifierGroup({
 		{stat = "powerMultiplier", baseMultiplier = self.power},
 		{stat = "grit", amount = self.grit},
 		{stat = "protection", effectiveMultiplier = self.armor},
 	})
end

function update(dt)

end


function uninit()

end