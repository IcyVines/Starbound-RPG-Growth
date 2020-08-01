require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = projectile.sourceEntity()
end

function update(dt)
  local targetIds = friendlyQuery(mcontroller.position(), 15, {}, self.id, true)
  local target = nil
  if targetIds then
    local healthRatio = 1
    for _,id in ipairs(targetIds) do
      local newHealth = world.entityHealth(id)
      if newHealth and newHealth[1] / newHealth[2] < healthRatio then
        healthRatio = newHealth[1] / newHealth[2]
        target = id
      end 
    end
  end

  if target then
    mcontroller.approachVelocity(world.distance(world.entityPosition(target), mcontroller.position()), 50)
  else
    mcontroller.approachVelocity({0,0}, 10)
  end
end