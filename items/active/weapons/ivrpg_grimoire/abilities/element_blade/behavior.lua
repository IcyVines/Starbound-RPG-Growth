require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.controlMovement = config.getParameter("controlMovement")
  self.controlRotation = config.getParameter("controlRotation")
  self.rotationSpeed = 0
  self.timedActions = config.getParameter("timedActions", {})
  self.delay = true
  self.aimPosition = mcontroller.position()
  self.wiggleTimer = 0
  self.direction = 0
  self.hitTimer = 0
  self.originPosition = mcontroller.position()
  self.originVelocity = mcontroller.velocity()
  self.perpendicularVelocity = {0,0}

  self.maxSpeed = projectile.getParameter("speed", 20)

  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)

  message.setHandler("trigger", function(_, _, behaviorType)
      self.originVelocity = mcontroller.velocity()
      self.perpendicularVelocity[1] = -mcontroller.yVelocity()
      self.perpendicularVelocity[2] = mcontroller.xVelocity()
      self.perpendicularVelocity = vec2.norm(self.perpendicularVelocity)
      mcontroller.setVelocity({0,0})
      self[behaviorType] = true
      self.originPosition = mcontroller.position()
      self.wiggleTimer = 0
      self.direction = math.random(0,1) * 2 - 1
    end)

  message.setHandler("kill", function()
      projectile.die()
    end)
end

function update(dt)

  if vec2.mag(mcontroller.velocity()) > self.maxSpeed then
    mcontroller.setVelocity(vec2.mul(vec2.norm(mcontroller.velocity()), self.maxSpeed))
  end

  if self.follow and not self.target then
    mcontroller.setPosition(vec2.add(self.originPosition, vec2.mul(self.perpendicularVelocity, self.wiggleTimer)))
    if self.wiggleTimer <= -0.25 then
      self.direction = -1
    elseif self.wiggleTimer >= 0.25 then
      self.direction = 1
    end
    self.wiggleTimer = self.wiggleTimer - dt * self.direction
  
    local targetIds = enemyQuery(mcontroller.position(), 15, {}, projectile.sourceEntity())
    if targetIds then
      for _, id in ipairs(targetIds) do
        if world.entityExists(id) then
          self.target = id
          self.delay = false
        end
      end
    end
  end

  self.hitTimer = math.max(self.hitTimer - dt, 0)

  if self.target and world.entityExists(self.target) then
    local distanceFrom = world.distance(world.entityPosition(self.target), mcontroller.position())
    local distanceMax = vec2.mag(distanceFrom)
    if distanceMax > 0 and distanceMax <= 1.5 then
      self.hitTimer = 0.35
    end
    self.originVelocity = vec2.lerp(dt*10, self.originVelocity, distanceFrom)
    local controlForce = (self.hitTimer > 0) and 0 or 200
    mcontroller.approachVelocity(vec2.mul(vec2.norm(self.originVelocity), 40), controlForce)
  elseif not self.delay then
    self.target = false
    self.originVelocity = mcontroller.velocity()
    self.perpendicularVelocity[1] = -mcontroller.yVelocity()
    self.perpendicularVelocity[2] = mcontroller.xVelocity()
    self.perpendicularVelocity = vec2.norm(self.perpendicularVelocity)
    mcontroller.setVelocity({0,0})
    self.wiggleTimer = 0
    self.direction = math.random(0,1) * 2 - 1
    self.originPosition = mcontroller.position()
    self.delay = true
  end



end

function processTimedAction(action, dt)
  if action.complete then
    return
  elseif action.delayTime then
    action.delayTime = action.delayTime - dt
    if action.delayTime <= 0 then
      action.delayTime = nil
    end
  elseif action.loopTime then
    action.loopTimer = action.loopTimer or 0
    action.loopTimer = math.max(0, action.loopTimer - dt)
    if action.loopTimer == 0 then
      projectile.processAction(action)
      action.loopTimer = action.loopTime
      if action.loopTimeVariance then
        action.loopTimer = action.loopTimer + (2 * math.random() - 1) * action.loopTimeVariance
      end
    end
  else
    projectile.processAction(action)
    action.complete = true
  end
end
