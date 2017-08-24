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
  
end

function uninit()

end
