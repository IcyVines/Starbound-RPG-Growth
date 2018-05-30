
function init()
	self.id = effect.sourceEntity()
	self.shieldDecay = config.getParameter("shieldDecay", 0.5)
 	self.healthStatus = config.getParameter("healthStatus", "regeneration4")
 	self.healthRange = config.getParameter("healthRange", 8)
 	self.damageUpdate = 5
 	effect.addStatModifierGroup({
 		{stat = "shieldHealth", effectiveMultiplier = self.shieldDecay}
 	})
end

function update(dt)
	self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
	if self.notifications then
	for _,notification in pairs(self.notifications) do
	  if notification.hitType == "ShieldHit" then
	    world.sendEntityMessage(notification.sourceEntityId, "addEphemeralEffect", "ivrpgjudgement", 3, self.id)
	    if status.resourcePositive("perfectBlock") then
	      healPulse()
	    end
	  end
	end
	end
end

function healPulse()
	status.addEphemeralEffect(self.healthStatus, 3)
	--local sourceDamageTeam = world.entityDamageTeam(self.id)
	local targetIds = world.entityQuery(mcontroller.position(), self.healthRange, {
      withoutEntityId = self.id,
      includedTypes = {"creature"}
    })
    for i,id in ipairs(targetIds) do
		if world.entityDamageTeam(id).type == "friendly" then
			world.sendEntityMessage(id, "addEphemeralEffect", self.healthStatus, 3, self.id)
		end
    end
end

function uninit()

end