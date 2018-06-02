function init()
  --Power
  self.damageModifier = config.getParameter("powerModifier")
  self.damageBonusId = effect.addStatModifierGroup({})
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  self.active = false
end


function update(dt)
  self.energy = status.resource("energy")
  self.maxEnergy = status.stat("maxEnergy")
  if self.energy == self.maxEnergy and not self.active then
    effect.setStatModifierGroup(self.damageBonusId, {
      {stat = "powerMultiplier", effectiveMultiplier = self.damageModifier}
    })
    animator.setParticleEmitterActive("embers", true)
    self.active = true
  elseif self.energy < self.maxEnergy*3/4 and self.active then
    effect.setStatModifierGroup(self.damageBonusId, {})
    animator.setParticleEmitterActive("embers", false)
    self.active = false
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
