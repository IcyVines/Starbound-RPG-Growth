function init()
  if entity.damageTeam().type == "friendly" and entity.entityType() == "player" then
  	--sb.logInfo("Status: " .. effect.duration())
  	status.addPersistentEffect("ivrpgmultiplayerxp", {stat = "ivrpgmultiplayerxp", amount = 1})
  	world.spawnItem("experienceorb", mcontroller.position(), math.floor(effect.duration()))
  end
  effect.expire()
end

function update(dt)
  
end

function uninit()
end