function init()
  --Crit
  effect.addStatModifierGroup({
    {stat = "ninjaBleed", amount = 10}
  })
  
end


function update(dt)
  if not status.statPositive("ivrpgclassability") then
  	effect.setParentDirectives("border=1;d8111120;59050500")
  else
  	effect.setParentDirectives()
  end
end

function uninit()

end
