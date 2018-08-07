
function init()
	self.id = effect.sourceEntity()
	self.energyConsumed = 0
	status.modifyResourcePercentage("energy", 1)
  	self.currentEnergy = status.resource("energy")
 	effect.addStatModifierGroup({
 		{stat = "energyRegenBlockTime", amount = -100},
 		{stat = "energyRegenPercentageRate", amount = 1}
 	})
end

function update(dt)
	self.energyConsumed = self.energyConsumed + (self.currentEnergy > status.resource("energy") and self.currentEnergy - status.resource("energy") or 0)
	self.currentEnergy = status.resource("energy")
	status.setResourcePercentage("energyRegenBlock", 0)
	status.setPersistentEffects("ivrpgdesperado", {
		{stat = "powerMultiplier", baseMultiplier = math.min(1 + (self.energyConsumed / 200), 2.5)}
	})
end


function uninit()
	status.clearPersistentEffects("ivrpgdesperado")
	status.addEphemeralEffect("ivrpgdesperadocooldown", 30)
end