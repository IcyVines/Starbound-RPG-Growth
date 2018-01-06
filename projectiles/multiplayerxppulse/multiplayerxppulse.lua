function init()
  if entity.damageTeam().type == "friendly" and entity.entityType() == "player" then
  	status.addPersistentEffect("ivrpgmultiplayerxp", {stat = "ivrpgmultiplayerxp", amount = math.floor(effect.duration())})
  end
  effect.expire()
end

function update(dt)
  
end

function uninit()
end