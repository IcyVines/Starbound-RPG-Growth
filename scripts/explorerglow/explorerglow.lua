function init()
  self.id = effect.sourceEntity()
  self.brightLight = config.getParameter("brightLight")
  self.dullLight = config.getParameter("dullLight")
end

function update(dt)
	self.health = world.entityHealth(self.id)
  if self.health[1] ~= 0 and self.health[2] ~= 0 and self.health[1]/self.health[2]*100 >= 50 then
    animator.setLightActive("glow", true)
  else
	  animator.setLightActive("glow", false)
    effect.setParentDirectives()
  end

  if status.statPositive("ivrpgclassability") then
    effect.setParentDirectives()
    animator.setLightColor("glow", self.dullLight)
  else
    effect.setParentDirectives("border=1;f4ed1820;a09b0b00")
    animator.setLightColor("glow", self.brightLight)
  end

  if world.entityCurrency(effect.sourceEntity(), "classtype") ~= 6 then
    effect.expire()
  end
end

function uninit()

end
