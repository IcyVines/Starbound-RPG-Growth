function init()
  --Crit
  effect.addStatModifierGroup({
    {stat = "critChance", amount = 20},
    {stat = "critBonus", effectiveMultiplier = 1.2}
  })
  effect.setParentDirectives("border=2;d8111120;59050500")
end


function update(dt)
  
end

function uninit()

end
