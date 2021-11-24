require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = projectile.sourceEntity()
  self.stick = nil
  self.distance = {0,0}
  self.messageSent = false
end

function update(args)
  if self.stick then
    if world.entityExists(self.stick) then
      mcontroller.setPosition(vec2.sub(world.entityPosition(self.stick), self.distance))
      if not self.messageSent then
        world.sendEntityMessage(self.id, "ivrpgElementressIcicleRush")
        self.messageSent = true
      end
    else
      -- Shatter
    end
  end
end

function hit(entityId)
  if entityId and world.entityExists(entityId) and not self.stick then
    self.stick = entityId
    local myPos = mcontroller.position()
    local stickPos = world.entityPosition(self.stick)
    self.distance = world.distance(stickPos, myPos)
  end
end
