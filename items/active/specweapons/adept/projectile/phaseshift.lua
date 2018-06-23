require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.id = projectile.sourceEntity()
  self.projectileType = config.getParameter("projectileType")
  self.friendlyProjectileType = config.getParameter("friendlyProjectileType")
  self.projectileParameters = config.getParameter("projectileParameters", {})
  self.friendlyProjectileParameters = config.getParameter("friendlyProjectileParameters", {})
  self.projectileParameters.power = config.getParameter("power")
  self.projectileParameters.speed = config.getParameter("projectileSpeed")
  self.friendlyProjectileParameters.speed = config.getParameter("friendlyProjectileSpeed")
  self.projectileParameters.powerMultiplier = projectile.powerMultiplier()

  self.spawnTime = config.getParameter("spawnRate")
  self.friendlySpawnTime = config.getParameter("friendlySpawnRate")
  self.spawnTimer = self.spawnTime
  self.friendlySpawnTimer = self.friendlySpawnTime
end

function update(dt)
  self.spawnTimer = math.max(0, self.spawnTimer - dt)
  self.friendlySpawnTimer = math.max(0, self.friendlySpawnTimer - dt)
  if self.spawnTimer == 0 then
    createEnemyProjectile()
    self.spawnTimer = self.spawnTime
  end
  if self.friendlySpawnTimer == 0 then
    createFriendlyProjectile()
    self.friendlySpawnTimer = self.friendlySpawnTime
  end
end

function createEnemyProjectile()
  local targetIds = world.entityQuery(mcontroller.position(), 15, {
    withoutEntityId = self.id,
    includedTypes = {"creature"}
  })
  shuffle(targetIds)
  for i,id in ipairs(targetIds) do
    if world.entityCanDamage(self.id, id) and not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
      local sourceDamageTeam = world.entityDamageTeam(self.id)
      local directionTo = vec2.mul(vec2.norm(world.distance(world.entityPosition(id), mcontroller.position())), self.projectileParameters.speed)
      local velocity = world.entityVelocity(id)
      directionTo[1] = directionTo[1] + velocity[1]
      directionTo[2] = directionTo[2] + velocity[2]/2
      world.spawnProjectile(
        self.projectileType,
        mcontroller.position(),
        self.id,
        directionTo,
        false,
        self.projectileParameters
      )
      return
    end
  end
end

function createFriendlyProjectile()
  local targetIds = world.entityQuery(mcontroller.position(), 15, {
    includedTypes = {"creature"}
  })
  shuffle(targetIds)
  for i,id in ipairs(targetIds) do
    if world.entityDamageTeam(id).type == "friendly" then
      local sourceDamageTeam = world.entityDamageTeam(self.id)
      local directionTo = world.distance(world.entityPosition(id), mcontroller.position())
      world.spawnProjectile(
        self.friendlyProjectileType,
        mcontroller.position(),
        0,
        directionTo,
        false,
        self.friendlyProjectileParameters
      )
      return
    end
  end
end