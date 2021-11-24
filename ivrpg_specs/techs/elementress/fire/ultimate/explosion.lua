require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"
require "/scripts/vec2.lua"

function init()
  self.id = projectile.sourceEntity()
  self.projectileType = config.getParameter("projectileType")
  self.spawnCount = config.getParameter("spawnCount", 1)
  self.projectileParameters = config.getParameter("projectileParameters", {})
  self.projectileParameters.powerMultiplier = projectile.powerMultiplier()
  self.spawnTime = config.getParameter("spawnRate")
  self.spawnTimer = self.spawnTime
end

function update(dt)
  self.spawnTimer = math.max(0, self.spawnTimer - dt)
  if self.spawnTimer == 0 then
    --createEnemyProjectile()
    spitLava()
    self.spawnTimer = self.spawnTime
  end
end

function spitLava()
  local topSpot = vec2.add(mcontroller.position(), {0, 1})
  --local stopSpot = world.lineCollision(mcontroller.position(), topSpot, {"Null", "Slippery", "Dynamic", "Block"})
  for i=1,self.spawnCount do
    world.spawnProjectile(
      "ivrpg_lavabubble",
      topSpot, --stopSpot and vec2.sub(stopSpot, {0, 2}) or topSpot,
      self.id,
      {math.random() * 2 - 1, -math.random()},
      false,
      self.projectileParameters
    )
  end
end

function createEnemyProjectile()
  local targetIds = enemyQuery(mcontroller.position(), 40, {includedTypes = {"creature"}}, self.id, true)
  shuffle(targetIds)
  for i,id in ipairs(targetIds) do
    if world.entityExists(id) and not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
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