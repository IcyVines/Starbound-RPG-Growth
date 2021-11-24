require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = projectile.sourceEntity()
  self.chainLimit = config.getParameter("chainLimit", 2)
  self.chaos = config.getParameter("chaos", false)
  self.currentChain = 0
  self.startSeeking = false
  self.nearbyEntities = {}
  math.random()
end

function update(args)

  if self.currentChain > self.chainLimit then
    projectile.die()
  end

  if self.newTarget and world.entityExists(self.newTarget) then
    local distance = world.distance(world.entityPosition(self.newTarget), mcontroller.position())
    mcontroller.setVelocity(vec2.mul(vec2.norm(distance), projectile.getParameter("speed", 1)))
    if self.chaos and self.newTarget == self.id and vec2.mag(distance) <= 2 then
      world.sendEntityMessage(self.newTarget, "modifyResource", "energy", 4)
      world.sendEntityMessage(self.newTarget, "ivrpgElementressOvercharge")
      hit(self.newTarget)
    end
  else
    self.newTarget = nil
  end
end

function hit(entityId)
  local nearbyEntities = {}
  local targets = enemyQuery(mcontroller.position(), 30, {includedTypes = {"creature"}, withoutEntityId = entityId}, self.id, true)
  if targets then
    for _,id in ipairs(targets) do
      if world.entityExists(id) then
        local pos = world.entityPosition(id)
        local distance = vec2.mag(world.distance(mcontroller.position(), pos))
        if not world.lineTileCollision(mcontroller.position(), pos, {"Block", "Slippery", "Null", "Dynamic"}) then
          table.insert(nearbyEntities, id)
        end
      end
    end
  end

  -- Chaos Variant
  if entityId ~= self.id and self.chaos then
    local playerPos = world.entityPosition(self.id)
    local distance = world.distance(mcontroller.position(), playerPos)
    if vec2.mag(distance) <= 30 and not world.lineTileCollision(mcontroller.position(), playerPos, {"Block", "Slippery", "Null", "Dynamic"}) then
      table.insert(nearbyEntities, self.id)
    end
  end

  if nearbyEntities and #nearbyEntities > 0 then
    self.newTarget = nearbyEntities[math.random(#nearbyEntities)]
    projectile.setPower(projectile.power() / 2)
    self.currentChain = self.currentChain + 1
  else
    self.newTarget = nil
  end
end

function startSeeking()
  local randIndex = math.random(#self.nearbyEntities)
  local newId = self.nearbyEntities[randIndex]
  if newId and newId ~= self.startSeeking then
    self.newTarget = newId
    self.currentChain = self.currentChain + 1
  end
end
