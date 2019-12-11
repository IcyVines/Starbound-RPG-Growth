require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = projectile.sourceEntity()
  self.gasTime = projectile.getParameter("smokeTime", 1)
  self.gasTimer = self.gasTime
  self.canGas = false
  self.smoke = projectile.getParameter("smokeType", nil)
  self.ignoreId = projectile.getParameter("friendlySmoke", false)
  self.noBounce = projectile.getParameter("noBounce", false)
  self.damageClampRange = {2,20}
  self.timeAfterCollision = projectile.getParameter("timeAfterCollision", 5)
  self.queryDelta = 10
  self.queryStep = self.queryDelta
  self.smokeBlocked = projectile.getParameter("explodeNearTargets", false)

  if projectile.getParameter("orientationLocked", false) then mcontroller.setRotation(0) end

  self.tickTime = config.getParameter("boltInterval", 1.0)
  self.tickTimer = self.tickTime
end

function update(dt)
  if mcontroller.isColliding() then
  	self.canGas = true
    if not self.noBounce then
    	mcontroller.setYVelocity(mcontroller.onGround() and 15 or -5);
    	mcontroller.setXVelocity(math.random(-10,10))
    end
    if projectile.timeToLive() > self.timeAfterCollision then projectile.setTimeToLive(self.timeAfterCollision) end
  end

  if self.gasTimer == 0 and self.canGas then
  	self.gasTimer = self.gasTime
  	if self.smoke and (not self.smokeBlocked) then world.spawnProjectile(self.smoke, mcontroller.position(), (not self.ignoreId) and self.id or nil, {0,0}, false, {}) end
  elseif self.gasTimer > 0 then
  	self.gasTimer = math.max(0, self.gasTimer - dt)
  end

  if projectile.getParameter("shockTargets", false) then updateShocks(dt) end
  if projectile.getParameter("explodeNearTargets", false) and mcontroller.stickingDirection() then updateSearch(dt) end

end

function updateShocks(dt)
  self.tickTimer = self.tickTimer - dt
  local boltPower = util.clamp(10, self.damageClampRange[1], self.damageClampRange[2])
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    local targetIds = enemyQuery(mcontroller.position(), config.getParameter("jumpDistance", 8), {
      withoutEntityId = self.id,
      includedTypes = {"creature"}
    }, self.id)

    shuffle(targetIds)

    for i,id in ipairs(targetIds) do
      local sourceEntityId = self.id
      if not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
        local sourceDamageTeam = world.entityDamageTeam(sourceEntityId)
        local directionTo = world.distance(world.entityPosition(id), mcontroller.position())
        world.spawnProjectile(
          "teslaboltsmall",
          mcontroller.position(),
          self.id,
          directionTo,
          false,
          {
            power = boltPower,
            damageTeam = sourceDamageTeam,
            statusEffects = {"ivrpgoverload"}
          }
        )
        --animator.playSound("bolt")
        return
      end
    end
  end

end

function updateSearch(dt)

  self.queryStep = math.max(0, self.queryStep - 1)
  if self.queryStep == 0 then
    local near = enemyQuery(mcontroller.position(), 4, { includedTypes = {"creature"} }, self.id)
    if near and #near > 0 then
      self.smokeBlocked = false
    else
      self.smokeBlocked = true
    end
    self.queryStep = self.queryDelta
  end

end
