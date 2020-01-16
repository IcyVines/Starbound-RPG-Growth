require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = projectile.sourceEntity()
  self.gasTimer = 1
  self.gasTime = 0
  self.canGas = false
end

function update(dt)
  if mcontroller.isColliding() then
    self.canGas = true
  mcontroller.setYVelocity(mcontroller.onGround() and 15 or -5);
  mcontroller.setXVelocity(math.random(-10,10))
  end

  if self.gasTime == 0 and self.canGas then
  self.gasTime = self.gasTimer
  world.spawnProjectile("roguedisorientingsmoke", mcontroller.position(), self.id, {0,0}, false, {})
  elseif self.gasTime > 0 then
    self.gasTime = math.max(0, self.gasTime - dt)
  end

end
