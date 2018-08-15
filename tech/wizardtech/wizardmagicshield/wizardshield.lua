function init()
  self.sourceId = effect.sourceEntity()
  self.id = entity.id()
  self.statGroup = effect.addStatModifierGroup({})
end


function update(dt)
  if world.entityDamageTeam(self.id).type == "friendly" or (world.entityDamageTeam(self.id).type == "pvp" and not world.entityCanDamage(self.sourceId, self.id)) then
    effect.setStatModifierGroup(self.statGroup, {
      {stat = "invulnerable", amount = 1},
      {stat = "lavaImmunity", amount = 1},
      {stat = "poisonStatusImmunity", amount = 1},
      {stat = "fireStatusImmunity", amount = 1},
      {stat = "tarImmunity", amount = 1},
      {stat = "waterImmunity", amount = 1},
      {stat = "fallDamageMultiplier", effectiveMultiplier = 0}
    })
    --sb.logInfo(world.entityDamageTeam(self.id).type)
    --sb.logInfo(self.id .. " " .. self.sourceId)
    --sb.logInfo("on")
    effect.setParentDirectives("border=2;34ED2A20;4E1D7000")
  else
    --sb.logInfo("off")
    effect.expire()
  end
end

function uninit()
  effect.setParentDirectives()
end
