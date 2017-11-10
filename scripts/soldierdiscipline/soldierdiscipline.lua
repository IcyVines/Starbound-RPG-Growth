function init()
  --Power
  self.damageModifier = config.getParameter("powerModifier")
  effect.addStatModifierGroup({
    {stat = "powerMultiplier", effectiveMultiplier = self.damageModifier}
  })
  --effect.setParentDirectives("border=1;d8a23c20;63481400")
end


function update(dt)
  if not status.statPositive("ivrpgclassability") then
  	effect.setParentDirectives("border=1;d8a23c20;d8a23c00")
  else
  	effect.setParentDirectives()
  end
end

function uninit()

end
