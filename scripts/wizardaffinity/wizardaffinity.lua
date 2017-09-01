function init()
  --Power
  effect.addStatModifierGroup({
    {stat = "iceResistance", amount = .1},
    {stat = "fireResistance", amount = .1},
    {stat = "electricResistance", amount = .1}
  })
  --effect.setParentDirectives("border=1;c132bf20;38093700")
end


function update(dt)
  if not status.statPositive("ivrpgclassability") then
  	effect.setParentDirectives("border=1;c132bf20;c132bf00")
  else
  	effect.setParentDirectives()
  end
end

function uninit()

end
