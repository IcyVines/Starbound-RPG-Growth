function init()
  if "friendly" == entity.damageTeam().type then
     effect.addStatModifierGroup({
      {stat = "invulnerable", amount = 1},
      {stat = "lavaImmunity", amount = 1},
      {stat = "poisonStatusImmunity", amount = 1},
      {stat = "fireStatusImmunity", amount = 1},
      {stat = "tarImmunity", amount = 1},
      {stat = "waterImmunity", amount = 1},
      {stat = "fallDamageMultiplier", effectiveMultiplier = 0}
    })
    effect.setParentDirectives("border=2;34ED2A20;4E1D7000")
  end
end


function update(dt)
  
end

function uninit()
end
