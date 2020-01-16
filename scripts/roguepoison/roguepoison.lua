function init()
  self.resistanceBonusId = effect.addStatModifierGroup({})
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)
  self.foodValue = status.resource("food")
  if self.foodValue >= 34 then
    effect.setStatModifierGroup(self.resistanceBonusId, {
      {stat = "poisonResistance", amount = 0.2}
    })
    animator.setParticleEmitterActive("embers", true)
  else
    effect.setStatModifierGroup(self.resistanceBonusId, {})
    animator.setParticleEmitterActive("embers", false)
  end

  if not status.statPositive("ivrpgclassability") then
    effect.setParentDirectives("border=1;2ec62320;2ec62300")
  else
    effect.setParentDirectives()
  end

  if world.entityCurrency(effect.sourceEntity(), "classtype") ~= 5 then
    effect.expire()
  end
end

function uninit()

end
