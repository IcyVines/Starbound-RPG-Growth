require "/scripts/vec2.lua"

function init()
  script.setUpdateDelta(30)
  --message.setHandler("kill", projectile.die)

  math.randomseed(os.time())
  self.owner = projectile.sourceEntity()
  if not self.owner then projectile.die() end 
  self.home = world.entityPosition(self.owner)
  mcontroller.applyParameters({
    collisionEnabled = false
  })
end

function update()
  self.home = world.entityPosition(self.owner)

  if math.random() < 0.33 then
    mcontroller.setVelocity({math.random() * 2 - 1, math.random() * 0.2 - 0.1})
  end

  local distanceFrom = world.distance(self.home, mcontroller.position())
  if vec2.mag(distanceFrom) > 10 then
    mcontroller.setVelocity(distanceFrom)
  end
end