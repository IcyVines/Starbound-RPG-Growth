
function init()
	self.id = effect.sourceEntity()
	self.shieldDecay = config.getParameter("shieldDecay", 0.5)
 	--self.healthStatus = config.getParameter("healthStatus", "regeneration4")
 	self.healthRange = config.getParameter("healthRange", 8)
 	self.damageUpdate = 5
 	effect.addStatModifierGroup({
 		{stat = "shieldHealth", effectiveMultiplier = self.shieldDecay}
 	})
end

function update(dt)
	mcontroller.controlModifiers({
		speedModifier = 0.75
	})

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
	--local sourceDamageTeam = world.entityDamageTeam(self.id)
	local targetIds = world.entityQuery(mcontroller.position(), self.healthRange, {
      withoutEntityId = self.id,
      includedTypes = {"creature"}
    })
    for i,id in ipairs(targetIds) do
		if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(self.id, id)) then
			local healthModifier = 0.07 + (world.entityCurrency(self.id, "strengthpoint") + world.entityCurrency(self.id, "intelligencepoint"))*0.0005
			world.sendEntityMessage(id, "modifyResource", status.stat("maxHealth")*healthModifier)
		end
    end
end

function uninit()

end