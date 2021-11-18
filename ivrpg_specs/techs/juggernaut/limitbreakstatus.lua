
function init()
	_,self.damageGivenUpdate = status.inflictedDamageSince()
	self.cooldownBonus = 0
  self.cooldownTime = 60
  effect.addStatModifierGroup({
    {stat = "physicalResistance", amount = 1},
    {stat = "grit", amount = 3}
  })
end

function update(dt)
  status.modifyResourcePercentage("energy", 1)
  status.setResourceLocked("energy", false)
  updateDamageGiven()
end

function uninit()
	status.addEphemeralEffect("ivrpglimitbreakcooldown", self.cooldownTime - self.cooldownBonus)
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageDealt > notification.healthLost and notification.healthLost > 0 then
        effect.modifyDuration(2)
        self.cooldownBonus = math.min(self.cooldownBonus + 5, 30)
      end
    end
  end
end