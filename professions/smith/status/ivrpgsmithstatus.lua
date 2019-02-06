function init()
  script.setUpdateDelta(5)

  self.hungerThreshold = config.getParameter("hungerThreshold", 0.5)
  self.armorStatus = config.getParameter("armorStatus", "ivrpgsmithstatusarmor")
  self.id = entity.id()
end

function update(dt)
  targetIds = world.entityQuery(mcontroller.position(), 10, {
  	includedTypes = {"player", "npc"}
  })

  if targetIds and (status.resource("food") or 70) / 70 > self.hungerThreshold then
  	for _,id in ipairs(targetIds) do
  		if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(self.id, id)) then
  			world.sendEntityMessage(id, "applyStatusEffect", self.armorStatus, 2, self.id)
  		end
  	end
  end
end

function uninit()

end
