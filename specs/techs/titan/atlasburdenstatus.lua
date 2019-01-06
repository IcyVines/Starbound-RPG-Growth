
function init()
	self.id = effect.sourceEntity()
	self.shieldDecay = config.getParameter("shieldDecay", 0.5)
	self.jumpModifier = config.getParameter("jumpModifier", 0.5)
 	self.allyStatus = config.getParameter("status", "ivrpgatlasrelief")
 	self.allyStatusRange = config.getParameter("allyStatusRange", 15)
 	self.allyStatusLength = config.getParameter("allyStatusLength", 5)
 	self.enemyStatus = config.getParameter("enemyStatus", "soldierstun")
 	self.enemyStatusRange = config.getParameter("enemyStatusRange", 10)
 	self.enemyStatusLength = config.getParameter("enemyStatusLength", 2)
 	self.random = config.getParameter("randomStun", 0.25)
 	self.damageUpdate = 5
 	effect.addStatModifierGroup({
 		{stat = "shieldHealth", effectiveMultiplier = self.shieldDecay}
 	})
end

function update(dt)

	mcontroller.controlModifiers({
		airJumpModifier = self.jumpModifier
	})

	self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
	if self.notifications then
	for _,notification in pairs(self.notifications) do
	  if notification.hitType == "ShieldHit" then
	    if math.random() < self.random then world.sendEntityMessage(notification.sourceEntityId, "addEphemeralEffect", self.enemyStatus, 0.5, self.id) end
	    if status.resourcePositive("perfectBlock") then
	      stunPulse()
	      atlasRelief()
	    end
	  end
	end
	end
end

function stunPulse()
	local targetIds = world.entityQuery(mcontroller.position(), self.enemyStatusRange, {
      withoutEntityId = self.id,
      includedTypes = {"creature"}
    })
    for i,id in ipairs(targetIds) do
		if world.entityDamageTeam(id).type == "enemy" or (world.entityDamageTeam(id).type == "pvp" and world.entityCanDamage(self.id, id)) then
			world.sendEntityMessage(id, "addEphemeralEffect", self.enemyStatus, self.enemyStatusLength, self.id)
		end
    end
end

function atlasRelief()
	local targetIds = world.entityQuery(mcontroller.position(), self.allyStatusRange, {
      includedTypes = {"creature"}
    })
    for i,id in ipairs(targetIds) do
		if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(self.id, id)) then
			world.sendEntityMessage(id, "addEphemeralEffect", self.allyStatus, self.allyStatusLength, self.id)
		end
    end
end

function uninit()

end