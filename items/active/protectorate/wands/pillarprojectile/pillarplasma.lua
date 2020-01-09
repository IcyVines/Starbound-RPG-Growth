require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.projectileCount = config.getParameter("projectileCount", 10)
  self.damageRepeatTimeout = config.getParameter("damageRepeatTimeout", 0.5)
  self.controlRotation = config.getParameter("controlRotation")
  self.rotationSpeed = 0
  self.aimPosition = mcontroller.position()
  self.projectileType = config.getParameter("pillarType")

  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)

  message.setHandler("kill", projectile.die)
  message.setHandler("trigger", trigger)
end

function update(dt)
  if projectile.timeToLive() > 0 and not self.readyToDie then
    projectile.setTimeToLive(0.5)
  end

  if self.aimPosition then
    if self.controlRotation then
      rotateTo(self.aimPosition, dt)
    end
  end

  if self.delayTimer then
    self.delayTimer = self.delayTimer - dt
    if self.delayTimer <= 0 then
      activate()
      --projectile.die()
      self.delayTimer = nil
    end
  end
end

function trigger(_, _, delayTime, positionTo)
  self.delayTimer = delayTime
  self.positionTo = positionTo
end

function activate()

  if not self.positionTo then return end

  local distance = world.distance(self.positionTo, mcontroller.position())
  local rotation = vec2.angle(distance) * 180 / math.pi
  local projectileCount = math.min(math.floor(vec2.mag(distance)), 30)

  local rotMod = (rotation / 90) % 1
  local addMod = 1
  if rotMod > 0.4 and rotMod < 0.6 then addMod = 0.8
  elseif rotMod > 0.3 and rotMod < 0.7 then addMod = 0.9
  elseif rotMod > 0.2 and rotMod < 0.8 then addMod = 1
  else addMod = 1.1 end

  local projectileParameters = {}
  projectileParameters.powerMultiplier = projectile.powerMultiplier()
  projectileParameters.power = projectile.power()
  projectileParameters.knockback = 10
  projectileParameters.actionOnTimeout = {
    {
      action = "projectile",
      inheritDamageFactor = 1,
      type = self.projectileType,
      config = { rotation = rotation - 90, damageRepeatTimeout = self.damageRepeatTimeout }
    }
  }

  local pillarDuration = 1
  local chainStarted = false

  for i = 0,(projectileCount - 1),addMod do
    projectileParameters.timeToLive = i * 0.02
    projectileParameters.actionOnTimeout[1].config.timeToLive = pillarDuration - (2 * projectileParameters.timeToLive)
    if not self.readyToDie then
      projectile.setTimeToLive(pillarDuration - (2 * projectileParameters.timeToLive))
      self.readyToDie = true
    end
    local newPosition = vec2.approach(mcontroller.position(), self.positionTo, i)
    local isEmpty = not world.pointTileCollision(newPosition, {"Null", "Block", "Dynamic"})
    if isEmpty then
      world.spawnProjectile("pillarspawner", newPosition, projectile.sourceEntity(), distance, false, projectileParameters)
      if not chainStarted then self.delayTimer = projectileParameters.actionOnTimeout[1].config.timeToLive end
      chainStarted = true
    else
      return
    end
  end

  self.readyToDie = true

  --projectile.processAction(projectile.getParameter("explosionAction"))
end

function rotateTo(position, dt)
  local vectorTo = world.distance(position, mcontroller.position())
  local angleTo = vec2.angle(vectorTo)
  if self.controlRotation.maxSpeed then
    local currentRotation = mcontroller.rotation()
    local angleDiff = util.angleDiff(currentRotation, angleTo)
    local diffSign = angleDiff > 0 and 1 or -1

    local targetSpeed = math.max(0.1, math.min(1, math.abs(angleDiff) / 0.5)) * self.controlRotation.maxSpeed
    local acceleration = diffSign * self.controlRotation.controlForce * dt
    self.rotationSpeed = math.max(-targetSpeed, math.min(targetSpeed, self.rotationSpeed + acceleration))
    self.rotationSpeed = self.rotationSpeed - self.rotationSpeed * self.controlRotation.friction * dt

    mcontroller.setRotation(currentRotation + self.rotationSpeed * dt)
  else
    mcontroller.setRotation(angleTo)
  end
end

