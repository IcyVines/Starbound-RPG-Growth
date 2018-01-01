require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = projectile.sourceEntity()
end

function update(dt)
  if mcontroller.isColliding() then
    world.spawnProjectile("roguedisorientingsmoke", mcontroller.position(), self.id, {0,0}, false, {})
	mcontroller.setYVelocity(mcontroller.onGround() and 15 or -5);
	mcontroller.setXVelocity(math.random(-10,10))
  end
end
