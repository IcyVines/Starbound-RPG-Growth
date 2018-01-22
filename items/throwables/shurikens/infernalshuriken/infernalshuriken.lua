require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.timer = 0.1
  self.time = math.random()*0.1
end

function update(dt)
  if self.time == 0 then
    local xVel = mcontroller.xVelocity()
    local yVel = mcontroller.yVelocity()
    world.spawnProjectile("molotovflame", mcontroller.position(), self.playerId, {xVel,yVel}, false, {power = 3, speed = 4, timeToLive = 5, damageTeam = {type = "friendly"}})
    self.time = self.timer
  else
    self.time = math.max(0, self.time - dt)
  end
end