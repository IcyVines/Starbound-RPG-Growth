require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.ownerId = projectile.sourceEntity()
  self.id = entity.id()
  self.stuckDirection = nil

  self.boltPower = config.getParameter("boltPower", 10)

  self.tickTime = config.getParameter("boltInterval", 1.0)
  self.tickTimer = self.tickTime
end

function update(dt)

  if self.stuckDirection  and self.stuckDirection ~= "bottom" then
    if self.stuckDirection == "left" then 
      mcontroller.setRotation(-math.pi/2)
      mcontroller.setXVelocity(-10)
    elseif self.stuckDirection == "right" then 
      mcontroller.setRotation(math.pi/2)
      mcontroller.setXVelocity(10)
    elseif self.stuckDirection == "top" then 
      mcontroller.setRotation(math.pi)
      mcontroller.setYVelocity(10)
    end
  elseif mcontroller.onGround() then
    mcontroller.setRotation(0)
    --self.hitGround = true
  end

  for i=-1,1,2 do
    if world.lineTileCollision(mcontroller.position(), {mcontroller.xPosition() + i*0.4, mcontroller.yPosition()}) then
      self.stuckDirection = i == -1 and "left" or "right"
      break
    elseif world.lineTileCollision(mcontroller.position(), {mcontroller.xPosition(), mcontroller.yPosition() + i*0.5}) then
      self.stuckDirection = i == 1 and "top" or "bottom"--self.stuckDirection
      break
    end
  end

  --self.queryStep = math.max(0, self.queryStep - 1)
  if self.stuckDirection then
    local near = friendlyQuery(mcontroller.position(), 10, {}, self.ownerId, true)
    for _,entityId in pairs(near) do
      world.sendEntityMessage(entityId, "addEphemeralEffect", "energyregen", 0.5, self.ownerId)
    end

    self.tickTimer = self.tickTimer - dt
    if self.tickTimer <= 0 then
      self.tickTimer = self.tickTime
      local projectiles = world.entityQuery(mcontroller.position(), 10, {withoutEntityId = self.id, includedTypes = {"projectile"}})
      if projectiles then
        for _,id in ipairs(projectiles) do
          if world.entityName(id) == "ivrpgoperativebeacon" then
            local sourceDamageTeam = world.entityDamageTeam(self.ownerId)
            if not world.lineTileCollision(world.entityPosition(id), mcontroller.position()) then
              local directionTo = world.distance(world.entityPosition(id), mcontroller.position())
              local magnitude = vec2.mag(directionTo)
              world.spawnProjectile(
                "teslaboltsmall",
                mcontroller.position(),
                self.ownerId,
                directionTo,
                false,
                {
                  power = self.boltPower,
                  damageTeam = sourceDamageTeam,
                  speed = 80,
                  timeToLive = magnitude / 80,
                  periodicActions = {
                    {
                      time = 0.0,
                      ["repeat"] = false,
                      action = "sound",
                      options = {"/sfx/projectiles/electric_barrier_shock1.ogg"}
                    }
                  }
                }
              )
            end
          end
        end
      end
    end
  end

end

    