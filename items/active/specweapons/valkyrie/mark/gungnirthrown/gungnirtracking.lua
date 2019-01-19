require "/scripts/vec2.lua"

function init()
  self.target = false
  self.ownerId = projectile.sourceEntity()
  self.tracking = projectile.getParameter("tracking")
end

function update(dt)
  if not self.target then
    findTarget()
  else
    trackTarget(dt)
  end
end

function trackTarget(dt)
  local targetPosition = world.entityPosition(self.target)
  if not targetPosition then
    self.target = false
    return
  end

  local acceleration = world.distance(targetPosition, mcontroller.position())
  mcontroller.approachVelocity(vec2.mul(vec2.norm(acceleration), 80), 2000*self.tracking)
end

function findTarget()
  local targetIds = world.entityQuery(mcontroller.position(), 30, {
    withoutEntityId = self.ownerId,
    includedTypes = {"creature"}
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

function uninit()

end