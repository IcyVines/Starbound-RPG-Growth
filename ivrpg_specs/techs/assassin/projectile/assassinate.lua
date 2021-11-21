require "/scripts/vec2.lua"

function hit(entityId)
  if entityId then
    self.hit = true
    local health = world.entityHealth(entityId)
    local healthRatio = health[1] / health[2]
    local bonusChance = math.floor((1 - healthRatio) * 10) / 10
    if math.random() < (0.1 + bonusChance) then
      local ownerPosition = world.entityPosition(projectile.sourceEntity())
      local targetPosition = world.entityExists(entityId) and world.entityPosition(entityId) or mcontroller.position()
      local xMagnitude = world.distance(targetPosition, ownerPosition)[1]
      world.sendEntityMessage(entityId, "ivrpg_assassinated", xMagnitude)
    end
  end
end

function uninit()
  if not self.hit then
    world.sendEntityMessage(projectile.sourceEntity(), "ivrpg_assassinateFailed")
  end
end