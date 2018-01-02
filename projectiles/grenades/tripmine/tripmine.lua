require "/scripts/vec2.lua"
require "/scripts/poly.lua"

function init()
  self.queryDelta = 10
  self.queryStep = self.queryDelta
  self.id = entity.id()
  self.stuckDirection = nil
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
    if world.lineTileCollision(mcontroller.position(), {mcontroller.xPosition() + i*0.4, mcontroller.yPosition()}) then
      self.stuckDirection = i == -1 and "left" or "right"
      break
    elseif world.lineTileCollision(mcontroller.position(), {mcontroller.xPosition(), mcontroller.yPosition() + i*0.5}) then
      self.stuckDirection = i == 1 and "top" or "bottom"--self.stuckDirection
      break
    end
  end

  self.queryStep = math.max(0, self.queryStep - 1)
  if self.queryStep == 0 then
    local near = world.entityQuery(mcontroller.position(), 4, { includedTypes = {"monster", "npc"} })
    for _,entityId in pairs(near) do
      if entity.isValidTarget(entityId) then
        projectile.die()
      end
    end
    self.queryStep = self.queryDelta
  end

end
