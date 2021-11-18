
function init()
	_,self.damageGivenUpdate = status.inflictedDamageSince()
  effect.addStatModifierGroup({
    {stat = "grit", amount = 1},
    {stat = "maxHealth", effectiveMultiplier = 0.8},
    {stat = "maxEnergy", effectiveMultiplier = 0.8}
  })
end

function update(dt)
  local healthRatio = status.resource("health") / status.resourceMax("health")
  status.setPersistentEffects("ivrpgberserkstatus", {
    {stat = "powerMultiplier", amount = (3 - healthRatio * 3)},
    {stat = "protection", amount = healthRatio < 0.5 and 30 or 0}
  })

  mcontroller.controlModifiers({
    speedModifier = healthRatio < 0.5 and 1.2 or 1
  })
end

function uninit()
  status.clearPersistentEffects("ivrpgberserkstatus")
end