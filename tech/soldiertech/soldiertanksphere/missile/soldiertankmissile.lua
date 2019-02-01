require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.controlForce = config.getParameter("controlForce")
  self.startTimer = config.getParameter("startTimer", 0.1)
  self.maxSpeed = config.getParameter("maxSpeed", 50)
end

function update(dt)

  if self.startTimer > 0 then
    self.startTimer = math.max(0, self.startTimer - dt)
    return
  end

  local maxDistance = 20
  local entityPos = nil
  local pos = mcontroller.position()
  local distance = -1
  local entities = world.entityQuery(pos, maxDistance, {withoutEntityId = self.playerId, includedTypes = {"monster", "npc"}})
  for _, e in ipairs(entities) do
    local targetDamageTeam = world.entityDamageTeam(e)
    targetDamageTeam = targetDamageTeam.type and targetDamageTeam.type == "enemy"
  	if targetDamageTeam and world.entityCanDamage(self.playerId, e) then
  		epos = world.entityPosition(e)
  		local newDistance = world.magnitude(pos, epos)
  		if (newDistance < distance or distance < 0) then
  			distance = newDistance
  			entityPos = epos
  		end
  	end
  end

  if distance > 0 and not world.lineTileCollision(entityPos, pos, {"Block"}) then
  	--sb.logInfo("tracking")
  	local toTarget = world.distance(entityPos, pos)
    toTarget = vec2.norm(toTarget)
    --local angle = math.atan(entityPos[2]-pos[2],entityPos[1]-pos[1])
    mcontroller.approachVelocity(vec2.mul(toTarget, self.maxSpeed), self.controlForce)
  end
  mcontroller.setRotation(math.atan(mcontroller.velocity()[2], mcontroller.velocity()[1]))
end