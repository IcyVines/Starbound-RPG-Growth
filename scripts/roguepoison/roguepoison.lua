function init()
  --Power
  effect.addStatModifierGroup({
    {stat = "poisonResistance", amount = 0.2}
  })
  --effect.setParentDirectives("border=1;2ec62320;10510b00")
end


function update(dt)
  if not status.statPositive("ivrpgclassability") then
  	effect.setParentDirectives("border=1;2ec62320;2ec62300")
  else
  	effect.setParentDirectives()
  end
end

function uninit()

end
