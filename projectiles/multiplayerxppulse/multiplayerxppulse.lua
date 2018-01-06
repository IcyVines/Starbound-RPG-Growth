function init()
  if entity.damageTeam().type == "friendly" and entity.entityType() == "player" then
  	--sb.logInfo("Status: " .. effect.duration())
  	status.addPersistentEffect("ivrpgmultiplayerxp", {stat = "ivrpgmultiplayerxp", amount = 1})
  	local ent = world.spawnItem("experienceorb", mcontroller.position(), math.floor(effect.duration()))
  	if ent then
  		world.takeItemDrop(ent, entity.id())
  	end
  end
  effect.expire()
end

function update(dt)
  
end

function uninit()
end