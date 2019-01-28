require "/scripts/util.lua"
require "/scripts/companions/util.lua"
require "/scripts/messageutil.lua"
require "/scripts/vec2.lua"

function init()
  self.target = false
  self.ownerId = projectile.sourceEntity()
end

function update(dt)
  promises:update()

  if not self.target and not self.hit then
    findTarget()
  elseif not self.hit then
    trackTarget(dt)
  end
end

function hit(entityId)
  if self.hit then return end
  if world.isMonster(entityId) then
    self.hit = true
    mcontroller.setVelocity({0,0})

    -- If a monster doesn't implement pet.attemptCapture or its response is nil
    -- then it isn't caught.
    promises:add(world.sendEntityMessage(entityId, "pet.attemptCapture", projectile.sourceEntity()), function (pet)
        self.pet = pet
      end)
  end
end

function shouldDestroy()
  return projectile.timeToLive() <= 0 and promises:empty()
end

function destroy()
  if self.pet then
    spawnFilledPod(self.pet)
  else
    spawnEmptyPod()
  end
end

function spawnEmptyPod()
  world.spawnItem("ivrpgadvancedcapturepod", mcontroller.position(), 1)
end

function spawnFilledPod(pet)
  local pod = createFilledPod(pet)
  world.spawnItem(pod.name, mcontroller.position(), pod.count, pod.parameters)
end

function trackTarget(dt)
  local targetPosition = world.entityPosition(self.target)
  if not targetPosition then
    self.target = false
    return
  end

  local acceleration = world.distance(targetPosition, mcontroller.position())
  mcontroller.approachVelocity(vec2.mul(vec2.norm(acceleration), 80), 2000)
end

function findTarget()
  local targetIds = world.entityQuery(mcontroller.position(), 30, {
    withoutEntityId = self.ownerId,
    includedTypes = {"monster"}
  })

  local magnitude = 31
  if targetIds then
    for _,id in ipairs(targetIds) do
      if world.entityAggressive(id) and world.entityCanDamage(self.ownerId, id) then
        local position = world.entityPosition(id)
        if not world.lineTileCollision(mcontroller.position(), position) then
          local newMagnitude = position and world.magnitude(position, mcontroller.position()) or 31
          if newMagnitude < magnitude then
            self.target = id
            magnitude = newMagnitude
          end
        end
      end
    end
  end
end

function createFilledPod(pet)
  return {
      name = "filledcapturepod",
      count = 1,
      parameters = {
          description = pet.description,
          tooltipFields = {
              subtitle = pet.name or "Unknown",
              objectImage = pet.portrait
            },
          inventoryIcon = "/professions/tamer/items/capturepod/filledadvancedcapturepodicon.png",
          animationParts = {filledcapturepod = "/professions/tamer/items/capturepod/filledadvancedcapturepod.png"},
          icons = {healthy = "/professions/tamer/items/capturepod/filledadvancedcapturepodicon.png", dead = "/professions/tamer/items/capturepod/filledadvancedcapturepodicondead.png"},
          projectileType = "ivrpgfilledadvancedcapturepod",
          podUuid = sb.makeUuid(),
          collectablesOnPickup = pet.collectables,
          pets = {pet}
        }
    }
end