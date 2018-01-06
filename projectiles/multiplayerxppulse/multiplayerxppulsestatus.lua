function init()
  --effect.setParentDirectives("border=3;e8981900;a36809")
  --self.damageProjectileType = config.getParameter("damageProjectileType") or "armorthornburst"
  if entity.damageTeam().type == "friendly" and entity.entityType() == "player" then
  	sb.logInfo("Status: " .. effect.duration())
  	status.addPersistentEffect("ivrpgmultiplayerxp", {stat = "ivrpgmultiplayerxp", amount = 1})
  	world.spawnItem("experienceorb", mcontroller.position(), math.floor(effect.duration()))
  end
end

function update(dt)
  
end

function uninit()
	--deactivateZone()
end