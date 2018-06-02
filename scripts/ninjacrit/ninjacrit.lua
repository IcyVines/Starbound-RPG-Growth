function init()
  self.critBonusId = effect.addStatModifierGroup({})
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)

  if nighttimeCheck() or undergroundCheck() then
  	effect.setStatModifierGroup(self.critBonusId, {
    	{stat = "ivrpgBleedChance", amount = 0.1},
      {stat = "ivrpgBleedLength", amount = 0.5}
  	})
    animator.setParticleEmitterActive("embers", true)
  else
  	effect.setStatModifierGroup(self.critBonusId, {})
    animator.setParticleEmitterActive("embers", false)
  end

  if not status.statPositive("ivrpgclassability") then
  	effect.setParentDirectives("border=1;d8111120;59050500")
  else
  	effect.setParentDirectives()
  end

  if world.entityCurrency(effect.sourceEntity(), "classtype") ~= 3 then
    effect.expire()
  end
end

function uninit()

end

function nighttimeCheck()
  return world.timeOfDay() > 0.5 -- true if night
end

function undergroundCheck()
  return world.underground(mcontroller.position()) 
end