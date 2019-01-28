function init()
  script.setUpdateDelta(5)
  self.healingStatus = config.getParameter("healingStatus", "ivrpgtamermonsterstatus")
  self.id = entity.id()
end

function update(dt)
  targetIds = world.monsterQuery(mcontroller.position(), 20)
  local healthRatio = status.resource("health") / status.stat("maxHealth")
  if targetIds then
  	for _,id in ipairs(targetIds) do
  		if world.entityDamageTeam(id).type == "friendly" then
  			world.sendEntityMessage(id, "applyStatusEffect", self.healingStatus, 3 - healthRatio, self.id)
  		end
  	end
  end
end

function uninit()
  
end
