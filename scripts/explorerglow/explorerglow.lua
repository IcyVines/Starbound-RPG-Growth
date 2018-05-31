function init()
  --effect.setParentDirectives("border=1;f4ed1820;a09b0b00")
end

function update(dt)
	self.health = world.entityHealth(self.id)
    if self.health[1] ~= 0 and self.health[2] ~= 0 and self.health[1]/self.health[2]*100 >= 50 and not status.statPositive("ivrpgclassability") then
      	animator.setLightActive("glow", true)
    else
		animator.setLightActive("glow", false)
    end

    if world.entityCurrency(effect.sourceEntity(), "classtype") ~= 6 then
	    effect.expire()
	end
end

function uninit()

end
