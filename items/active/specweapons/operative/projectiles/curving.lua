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
  self.lastPosition = vec2.add(mcontroller.position(), vec2.mul(self.aimDirection, self.timeToLive * 1.1))
  self.cullPosition = world.lineCollision(mcontroller.position(), self.lastPosition, {"Block", "Dynamic", "Slippery"})
  self.xImportant = math.abs(self.aimDirection[1]) > math.abs(self.aimDirection[2])
  self.xDirection = self.aimDirection[1] < 0 and -1 or (self.aimDirection[1] > 0 and 1 or 0)
  self.yDirection = self.aimDirection[2] < 0 and -1 or (self.aimDirection[2] > 0 and 1 or 0)
end

function update(dt)
  self.direction = vec2.mul(self.curveDirection, -30 * (self.timer - self.timeToLive / 2))
  self.timer = self.timer + dt
  mcontroller.setVelocity(vec2.add(self.direction,self.aimDirection))

  if self.cullPosition then
    local position = mcontroller.position()
    local nextPosition = vec2.add(position, vec2.mul(self.aimDirection, dt * 2))
    local distance = world.distance(position, self.cullPosition)
    local nextDistance = world.distance(nextPosition, self.cullPosition)
    if (self.xImportant and (self.xDirection * distance[1] >= 0 or self.xDirection * nextDistance[1] >= 0 )) or (not self.xImportant and (self.yDirection * distance[2] >= 0 or self.yDirection * nextDistance[2] >= 0 )) then
      projectile.die()
    end
  end
end

function uninit()
  world.spawnProjectile("ivrpgbreathlessconvergence", mcontroller.position(), self.playerId, vec2.rotate(self.aimDirection, math.pi / 4), false, {timeToLive = 0.1})
end

