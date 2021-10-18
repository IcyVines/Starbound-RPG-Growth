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
  self.spawnTimer = 0.25
  self.direction = config.getParameter("direction", 1)

  self.maxSpeed = projectile.getParameter("speed", 20)

  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)

  message.setHandler("trigger", function(_, _, behaviorType)
      self[behaviorType] = true
      self.direction = (mcontroller.velocity()[1] >= 0) and 1 or -1
      mcontroller.setVelocity({0,0})
      self.newDirection = {self.direction, 0}
    end)

  message.setHandler("kill", function()
      projectile.die()
    end)
end

function update(dt)
  if self.release then
    self.spawnTimer = math.max(self.spawnTimer - dt, 0)
    if self.spawnTimer == 0 then
      self.spawnTimer = 0.25
      world.spawnProjectile(config.getParameter("projectileName", "ivrpg_earthscythe") .. "small", mcontroller.position(), projectile.sourceEntity(), self.newDirection, false, {direction = self.direction})
      self.newDirection = vec2.rotate(self.newDirection, self.direction*math.pi / 4)
    end
  end

  if config.getParameter("curve", false) then
    local velocity = mcontroller.velocity()
    local perpendicular = {}
    perpendicular[1] = velocity[2] * self.direction
    perpendicular[2] = -velocity[1] * self.direction
    mcontroller.approachVelocity(vec2.mul(perpendicular, 30), 1000)
  end
end
