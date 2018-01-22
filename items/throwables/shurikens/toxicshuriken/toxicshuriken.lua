require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.timer = 0.4
  self.time = math.random()*0.4
end

function update(dt)
  if self.time == 0 then
    world.spawnProjectile("roguedisorientingsmoke", mcontroller.position(), self.playerId, {0,0}, false)
    self.time = self.timer
  else
    self.time = math.max(0, self.time - dt)
  end
end