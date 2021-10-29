require "/scripts/vec2.lua"
require "/scripts/ivrpgutil.lua"

function init()

end

function update(dt)
  local targets = enemyQuery(mcontroller.position(), 10, {}, projectile.sourceEntity(), true)
  if targets then
    for _,id in ipairs(targets) do
      if world.entityExists(id) then
        world.sendEntityMessage(id, "setVelocity", vec2.mul(world.distance(mcontroller.position(), world.entityPosition(id)), 5))
      end
    end
  end
end
