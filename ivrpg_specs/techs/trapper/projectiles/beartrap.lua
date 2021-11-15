require "/scripts/util.lua"
require "/scripts/companions/util.lua"
require "/scripts/messageutil.lua"
require "/scripts/vec2.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.target = false
  self.entityId = nil
  self.ownerId = projectile.sourceEntity()
  mcontroller.setRotation(0)

  message.setHandler("explode", function(_, _, power, powerMultiplier)
    world.spawnProjectile("regularexplosionspawner", mcontroller.position(), self.ownerId, {0,0}, false, {
      power = power, powerMultiplier = powerMultiplier, onlyHitTerrain = true, damageTeam = {type = "friendly"}
    })
    projectile.die()
  end)
end

function update(dt)
  promises:update()
  mcontroller.setRotation(0)
end

function hit(entityId)
  if self.hit then return end
  if world.isMonster(entityId) then
    self.hit = true
    -- If a monster doesn't implement pet.attemptCapture or its response is nil
    -- then it isn't caught.
    promises:add(world.sendEntityMessage(entityId, "pet.attemptCapture", projectile.sourceEntity()), function (pet)
      self.pet = pet
      self.entityId = entityId
    end)
    world.sendEntityMessage(entityId, "monster.setDropPool", nil)
    projectile.setTimeToLive(0.5)
  end
end

function destroy()
  if self.pet then
    world.sendEntityMessage(self.ownerId, "beartrapCapture", self.pet, self.entityId)
  end
end