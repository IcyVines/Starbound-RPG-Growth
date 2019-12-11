require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"
require "/scripts/vec2.lua"

function init()
  self.id = projectile.sourceEntity()
  self.attackTime = config.getParameter("attackTime", 1)
  self.attackTimer = self.attackTime
  self.projectileParameters = config.getParameter("projectileParameters", {})
  self.target = nil
  self.aimPosition = mcontroller.position()
  script.setUpdateDelta(1)

  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)

  message.setHandler("kill", projectile.die)
  message.setHandler("trigger", trigger)
end

function update(dt)
  if self.target and not world.entityExists(self.target) then self.target = nil end
  if self.attackTimer > 0 then
    self.attackTimer = math.max(0, self.attackTimer - dt)
    if not self.target or not targetAvailable() then
      enemySearch()
    end
    rotate()
  elseif self.attackTimer == 0 then
    fire()
    self.attackTimer = -1
  end
end

function trigger(_, _)
  self.attackTimer = 0
end

function targetAvailable()
  return not world.lineTileCollision(mcontroller.position(), world.entityPosition(self.target))
end

function enemySearch()
  local targetIds = enemyQuery(mcontroller.position(), 20, {
    withoutEntityId = self.id,
    includedTypes = {"creature"}
  }, self.id, false)
  shuffle(targetIds)
  for i,id in ipairs(targetIds) do
    self.target = id
    if targetAvailable() then
      return
    end
  end
  self.target = nil
end

function rotate()
  local directionTo = vec2.norm(world.distance(self.target and world.entityPosition(self.target) or self.aimPosition, mcontroller.position()))
  local rot = math.atan(directionTo[2], directionTo[1])
  mcontroller.setRotation(rot)
end

function fire()
  if not self.target then
    mcontroller.setVelocity(vec2.mul({math.cos(mcontroller.rotation()), math.sin(mcontroller.rotation())}, self.projectileParameters.speed))
  else
    local directionTo = vec2.mul(vec2.norm(world.distance(world.entityPosition(self.target), mcontroller.position())), self.projectileParameters.speed)
    local velocity = world.entityVelocity(self.target)
    directionTo[1] = directionTo[1] + velocity[1]
    directionTo[2] = directionTo[2] + velocity[2]/2
    mcontroller.setVelocity(directionTo)
  end
end