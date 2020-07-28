
function init()
  self.id = effect.sourceEntity()
  self.damageGivenUpdate = 5
  local alpha = math.floor(config.getParameter("alpha", 0.5) * 255)
  effect.setParentDirectives(string.format("?multiply=ffffff%02x", alpha))
  effect.addStatModifierGroup({
    {stat = "ivrpgstealth", amount = 1},
    {stat = "invulnerable", amount = 1}
  })
end

function update(dt)
  if status.overConsumeResource("energy", 5 * dt) then
    updateDamageGiven()
  else
    weaken()
    effect.expire()
  end
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        burst(notification.targetEntityId)
        effect.expire()
      end
    end
  end
end

function burst(entity)
  if not world.entityExists(entity) then return end
  local energy = status.resource("energy")
  status.overConsumeResource("energy", energy + 1)
  world.spawnProjectile("ivrpgquasarcollapse", world.entityPosition(entity), self.id, {0,0}, false, {power = energy, powerMultiplier = status.stat("powerMultiplier")})
end

function weaken()

end