function init()
  --Power
  self.powerModifier = config.getParameter("powerModifier", 0)
  effect.addStatModifierGroup({{stat = "powerMultiplier", baseMultiplier = self.powerModifier}})
  local enableParticles = config.getParameter("particles", true)
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", enableParticles)
  --effect.setParentDirectives("border=1;51b1ba20;05385900")
end


function update(dt)
  if not status.statPositive("ivrpgclassability") then
  	effect.setParentDirectives("border=1;51b1ba20;51b1ba00")
  else
  	effect.setParentDirectives()
  end
end

function uninit()

end
