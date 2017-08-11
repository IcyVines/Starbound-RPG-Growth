function init()
  self.damageProjectileType = config.getParameter("damageProjectileType") or "armorthornburst"

  self.cooldown = config.getParameter("cooldown") or 5

  resetThorns()
  self.cooldownTimer = 0

  self.queryDamageSince = 0
end

function resetThorns()
  self.cooldownTimer = self.cooldown
end

function update(dt)
  self.id = entity.id()
  self.strength = world.entityCurrency(self.id,"strengthpoint")
  self.strength = self.strength == 0 and 1 or self.strength
  if self.cooldownTimer <= 0 then
    local entities = world.entityQuery(entity.position(), 1.5, {withoutEntityId = self.id})
    for _, e in ipairs(entities) do
      if world.entityAggressive(e) then
        triggerThorns(self.strength^1.15)
        self.cooldownTimer = self.cooldown
      end
    end
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = self.cooldownTimer - dt
  end

end

function triggerThorns(damage)
  if status.stat("shieldHealth") > 0 then
    damage = damage*2
  end
  local damageConfig = {
    power = damage*2,
    speed = 0,
    physics = "default"
  }
  world.spawnProjectile(self.damageProjectileType, mcontroller.position(), entity.id(), {0, 0}, true, damageConfig)
end
