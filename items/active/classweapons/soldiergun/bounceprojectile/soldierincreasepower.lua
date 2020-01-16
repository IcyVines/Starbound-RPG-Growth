require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  --sb.logInfo("proj")
  self.hardLight = config.getParameter("hardLight", false)
  self.playerId = projectile.sourceEntity()
end

function update(dt)
  --sb.logInfo("update")
  if mcontroller.isColliding() then
    --sb.logInfo("updateC" .. projectile.power())
    if self.hardLight then
      projectile.setPower(projectile.power()*1.025)
      trackTarget()
    else
      projectile.setPower(projectile.power()*1.1)
    end
  end
end

function trackTarget()
  local entityPos = nil
  local pos = mcontroller.position()
  local distance = -1
  local entities = world.entityQuery(pos, 25, {withoutEntityId = self.playerId, includedTypes = {"creature"}})
  for _, e in ipairs(entities) do
    epos = world.entityPosition(e)
    local targetDamageTeam = world.entityDamageTeam(e)
    targetDamageTeam = targetDamageTeam.type and targetDamageTeam.type == "enemy"
    if targetDamageTeam and world.entityCanDamage(self.playerId, e) and not world.lineTileCollision(pos, epos) then
      local newDistance = world.magnitude(pos, epos)
      if (newDistance < distance or distance < 0) then
        distance = newDistance
        entityPos = epos
      end
    end
  end

  if distance > 0 then
    local toTarget = world.distance(entityPos, pos)
    toTarget = vec2.norm(toTarget)
    mcontroller.approachVelocity(vec2.mul(toTarget, 150), 2500)
  end
end