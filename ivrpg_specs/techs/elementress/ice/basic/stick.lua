require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = projectile.sourceEntity()
  self.stick = nil
end

function update(args)
  if self.stick then
    if world.entityExists(self.stick) then
      mcontroller.setPosition(world.entityPosition(self.stick))
      world.sendEntityMessage(self.id, "ivrpgElementressIcicleRush")
    else
      -- Shatter
    end
  end
end

function hit(entityId)
  if entityId and world.entityExists(entityId) and not self.stick then
    self.stick = entityId
  end
end
