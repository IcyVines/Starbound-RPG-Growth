function init()
  --Power
  self.damageModifier = config.getParameter("powerModifier")
end


function update(dt)
  self.energy = status.resource("energy")
  self.maxEnergy = status.stat("maxEnergy")
  if self.energy == self.maxEnergy then
    effect.setStatModifierGroup("soldierdiscipline", {
      {stat = "powerMultiplier", effectiveMultiplier = self.damageModifier}
    })
  elseif self.energy < self.maxEnergy*3/4 then
    status.removeStatModifierGroup("soldierdiscipline")
  end

  if not status.statPositive("ivrpgclassability") then
  	effect.setParentDirectives("border=1;d8a23c20;d8a23c00")
  else
  	effect.setParentDirectives()
  end

  if world.entityCurrency(effect.sourceEntity(), "classtype") ~= 4 then
    effect.expire()
  end
end

function uninit()

end
