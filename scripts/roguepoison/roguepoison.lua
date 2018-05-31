function init()
end


function update(dt)

  self.foodValue = status.resource("food")
  if self.foodValue >= 34 then
    effect.setStatModifierGroup("roguepoison", {
      {stat = "poisonResistance", amount = 0.2}
    })
  else
    effect.addStatModifierGroup("roguepoison")
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
