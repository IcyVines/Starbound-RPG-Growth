require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"
require "/scripts/vec2.lua"

function init()
  self.id = projectile.sourceEntity()
  self.attackTime = config.getParameter("attackTime", 1)
  self.attackTimer = self.attackTime
  self.trackingRange = config.getParameter("trackingRange", 10)
  self.projectileParameters = config.getParameter("projectileParameters", {})
  self.target = nil
  self.offset = config.getParameter("randPos", 0)
  if math.abs(self.offset) == 2 then self.offset = self.offset/4 end
  self.moveTimer = 0
  self.moveTo = 1
  self.fired = false
  mcontroller.setRotation(math.pi/2)
  updatePosition(0)

  mcontroller.applyParameters({
    collisionEnabled = false
  })

  script.setUpdateDelta(1)
  message.setHandler("kill", projectile.die)
  message.setHandler("trigger", trigger)
end

function updatePosition(dt)
  local velocity = mcontroller.velocity()
  local basePosition = world.entityPosition(self.id)
  local yLoc = self.offset == 0 and 1 or math.abs(self.offset) == 0.5 and -0.75 or 0
  if self.moveTimer >= 0.5 then self.moveTo = -1
  elseif self.moveTimer <= -0.5 then self.moveTo = 1 end
  self.moveTimer = self.moveTimer + dt * self.moveTo
  mcontroller.setPosition(vec2.add(basePosition, {self.offset * 2, yLoc * 2 + self.moveTimer}))
end

function update(dt)
  
  if not self.fired then updatePosition(dt) end

  if self.target and not world.entityExists(self.target) then self.target = nil end
  if not self.target or not targetAvailable() then
    enemySearch()
  end
  if self.target then
    fire()
  end
end

function trigger(_, _)
  self.attackTimer = 0
end

function targetAvailable()
  return not world.lineTileCollision(mcontroller.position(), world.entityPosition(self.target))
end

function enemySearch()
  local targetIds = enemyQuery(mcontroller.position(), self.trackingRange, {
    withoutEntityId = self.id,
    includedTypes = {"creature"}
  }, self.id)
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
  local directionTo = vec2.norm(world.distance(self.target and world.entityPosition(self.target) or mcontroller.position(), mcontroller.position()))
  local rot = math.atan(directionTo[2], directionTo[1])
  rot = math.pi/2
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
    self.fired = true
  end
end