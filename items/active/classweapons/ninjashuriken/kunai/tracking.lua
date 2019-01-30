require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.controlForce = config.getParameter("controlForce")
  self.maxSpeed = config.getParameter("speed", 60)
  self.hitTimer = config.getParameter("hitTimer")
  self.beginningCooldown = config.getParameter("beginningCooldown", 0.2)
  self.cooldown = 0
  self.firstWallDeduction = config.getParameter("initialWallDeduction", 0.25)

  self.subterfuge = config.getParameter("subterfuge", false)
  self.timer = 0.2
  self.time = math.random()*0.2

  mcontroller.applyParameters({
    collisionEnabled = false
  })

end

function update(dt)

  if self.subterfuge and self.time == 0 then
    world.spawnProjectile("roguedisorientingsmoke", mcontroller.position(), self.playerId, {0,0}, false)
    self.time = self.timer
  else
    self.time = math.max(0, self.time - dt)
  end

  local pos = mcontroller.position()
  local timeToLive = projectile.timeToLive()
  if world.pointTileCollision(pos, {"Block"}) then
    projectile.setTimeToLive(timeToLive - self.firstWallDeduction - dt/2)
    self.firstWallDeduction = 0
  end

  if self.beginningCooldown > 0 then
    self.beginningCooldown = math.max(self.beginningCooldown - dt, 0)
    return
  end

  if self.cooldown > 0 then
    mcontroller.accelerate({mcontroller.yVelocity()*15,-mcontroller.xVelocity()*15})
  	self.cooldown = math.max(0, self.cooldown - dt)
  	return
  end

  local maxDistance = self.bloodSeeker and 30 or 20
  local entityPos = nil
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
  	if distance < 0.5 then
  		self.cooldown = self.hitTimer / 2
  		return
  	end
  	local toTarget = world.distance(entityPos, pos)
    toTarget = vec2.norm(toTarget)
    mcontroller.approachVelocity(vec2.mul(toTarget, self.maxSpeed), self.controlForce)
  end
end