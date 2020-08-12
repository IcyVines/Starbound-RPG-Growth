require "/scripts/vec2.lua"
require "/scripts/poly.lua"

function init()
  self.id = entity.id()
end

function update(dt)

  local near = world.entityQuery(mcontroller.position(), 3, { includedTypes = {"monster", "npc"} })
  for _,entityId in pairs(near) do
    if entity.isValidTarget(entityId) then
      projectile.die()
    end
  end

end
