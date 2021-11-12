require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.maxSpeed = config.getParameter("speed", 40)
  self.timer = 0
  self.curveDirection = config.getParameter("curveDirection", {0,1})
  self.aimDirection = vec2.mul(config.getParameter("aimDirection", {1,0}), self.maxSpeed)
  script.setUpdateDelta(1)
  self.timeToLive = projectile.timeToLive()
  self.lastPosition = mcontroller.position()
end

function update(dt)
  local angleDirection = world.distance(mcontroller.position(), self.lastPosition)
  if mcontroller.position() ~= self.lastPosition then
    mcontroller.setRotation(vec2.angle(angleDirection))
  end
  self.lastPosition = mcontroller.position()
end

function die()
  projectile.die()
end

