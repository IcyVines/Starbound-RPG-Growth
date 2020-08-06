require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.maxSpeed = config.getParameter("speed", 40)
  self.timer = 0
  self.curveDirection = config.getParameter("curveDirection", {0,1})
  self.aimDirection = vec2.mul(config.getParameter("aimDirection", {1,0}),self.maxSpeed)
  script.setUpdateDelta(1)
  self.timeToLive = projectile.timeToLive()
end

function update(dt)
  self.direction = vec2.mul(self.curveDirection, -30 * (self.timer - self.timeToLive / 2))
  self.timer = self.timer + dt
  mcontroller.setVelocity(vec2.add(self.direction,self.aimDirection))
end

