require "/scripts/vec2.lua"
require "/scripts/poly.lua"

function init()
  self.id = entity.id()
  self.stuckDirection = nil
  self.gasTime = 0.1
  self.gasTimer = 0
  self.charged = config.getParameter("charged", false)
end

function update(dt)

  if self.stuckDirection  and self.stuckDirection ~= "bottom" then
    if self.stuckDirection == "left" then 
      mcontroller.setRotation(-math.pi/2)
      mcontroller.setXVelocity(-10)
    elseif self.stuckDirection == "right" then 
      mcontroller.setRotation(math.pi/2)
      mcontroller.setXVelocity(10)
    elseif self.stuckDirection == "top" then 
      mcontroller.setRotation(math.pi)
      mcontroller.setYVelocity(10)
    end
  elseif mcontroller.onGround() then
    mcontroller.setRotation(0)
    --self.hitGround = true
  end

  for i=-1,1,2 do
    if world.lineTileCollision(mcontroller.position(), {mcontroller.xPosition() + i * 1.5, mcontroller.yPosition()}) then
      self.stuckDirection = i == -1 and "left" or "right"
      break
    elseif world.lineTileCollision(mcontroller.position(), {mcontroller.xPosition() + 0.5, mcontroller.yPosition() + i * 1.2}) or world.lineTileCollision(mcontroller.position(), {mcontroller.xPosition() - 0.5, mcontroller.yPosition() + i * 1.2}) then
      self.stuckDirection = i == 1 and "top" or "bottom"--self.stuckDirection
      break
    end
  end

  if self.gasTimer == 0 then
    self.gasTimer = self.gasTime
    world.spawnProjectile("ivrpgblackoutgas", mcontroller.position(), self.id, {0,0}, false, {})
    if self.charged then
      world.spawnProjectile("ivrpgdemonicblackoutgas", mcontroller.position(), self.id, {0,0}, false, {})
    end
  elseif self.gasTimer > 0 then
    self.gasTimer = math.max(0, self.gasTimer - dt)
  end

end
