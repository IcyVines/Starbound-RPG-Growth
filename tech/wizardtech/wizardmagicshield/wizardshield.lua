function init()
  --Power
  effect.addStatModifierGroup({
    {stat = "invulnerable", amount = 1},
    {stat = "lavaImmunity", amount = 1},
    {stat = "poisonStatusImmunity", amount = 1},
    {stat = "tarImmunity", amount = 1},
    {stat = "waterImmunity", amount = 1},
    {stat = "fallDamageMultiplier", amount = 0}
  })
  effect.setParentDirectives("border=2;34ED2A20;4E1D7000")
end


function update(dt)
  status.setResourcePercentage("energyRegenBlock", 1.0)
end

function uninit()

end
