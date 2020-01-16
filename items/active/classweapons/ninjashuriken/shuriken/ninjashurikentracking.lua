require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.controlForce = config.getParameter("controlForce")
  self.maxSpeed = config.getParameter("speed", 60)
  self.hitTimer = config.getParameter("hitTimer")
  self.cooldown = 0

  self.message = world.sendEntityMessage(self.playerId, "hasStat", "ivrpgucbloodseeker")

  if world.isMonster(self.playerId) or world.isNpc(self.playerId) then
    self.agility = 10
  else
    self.agility = world.entityCurrency(self.playerId, "dexteritypoint")
  end

  projectile.setTimeToLive(2+self.agility/25)
  self.hitTimer = 1.3 - math.min(self.agility/100, 0.75)

  mcontroller.applyParameters(
    {
      collisionEnabled = false
    }
  )
end

function update(dt)

  if self.cooldown > 0 then
    mcontroller.accelerate({mcontroller.yVelocity()*8,-mcontroller.xVelocity()*8})
    self.cooldown = math.max(0, self.cooldown - dt)
    return
  end

  local maxDistance = (self.message:result()) and 30 or 20
  local entityPos = nil
  local pos = mcontroller.position()
  local distance = -1
  local entities = world.entityQuery(pos, maxDistance, {withoutEntityId = self.playerId, includedTypes = {"creature"}})
  for _, e in ipairs(entities) do
    if world.entityCanDamage(self.playerId, e) then
      epos = world.entityPosition(e)
      local newDistance = world.magnitude(pos, epos)
      if (newDistance < distance or distance < 0) then
        distance = newDistance
        entityPos = epos
      end
    end
  end

  if distance > 0 then
    if distance < 1 then
      self.cooldown = self.hitTimer
      return
    end
    --sb.logInfo("tracking")
    local toTarget = world.distance(entityPos, pos)
    toTarget = vec2.norm(toTarget)
    --local angle = math.atan(entityPos[2]-pos[2],entityPos[1]-pos[1])
    --mcontroller.approachVelocityAlongAngle(angle, self.maxSpeed, self.controlForce/2, false)
    mcontroller.approachVelocity(vec2.mul(toTarget, self.maxSpeed), self.controlForce)
    --mcontroller.approachVelocityAlongAngle(angle, self.maxSpeed, self.controlForce/2, false)
  end
  mcontroller.setRotation(math.atan(mcontroller.velocity()[2], mcontroller.velocity()[1]))
end