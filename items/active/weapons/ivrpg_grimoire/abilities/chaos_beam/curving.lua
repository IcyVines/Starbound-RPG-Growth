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
  self.direction = self.curveDirection * -30 * (self.timer - self.timeToLive / 2)
  self.timer = self.timer + dt
  mcontroller.setYVelocity(self.direction)
end
