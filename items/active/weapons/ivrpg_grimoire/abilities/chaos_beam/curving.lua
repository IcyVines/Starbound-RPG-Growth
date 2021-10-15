require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.maxSpeed = config.getParameter("speed", 40)
  self.timer = 0
  self.curveDirection = config.getParameter("curveDirection", 0)
  script.setUpdateDelta(1)
  self.timeToLive = projectile.timeToLive()
end

function update(dt)
  if not self.perpendicular then
    self.initialVelocity = mcontroller.velocity()
    self.perpendicular = {}
    self.perpendicular[1] = -self.initialVelocity[2]
    self.perpendicular[2] = self.initialVelocity[1]
  end
  self.direction = self.curveDirection * -30 * (self.timer - self.timeToLive / 2)
  self.timer = self.timer + dt
  local newDirection = vec2.mul(self.perpendicular, self.direction / 7.5)
  mcontroller.setVelocity(vec2.add(self.initialVelocity, newDirection))
end
