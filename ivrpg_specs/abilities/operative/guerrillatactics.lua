require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  _,self.damageGivenUpdate = status.inflictedDamageSince()
  self.powerTimer = 0
  self.powerTime = config.getParameter("powerTime")
  self.health = status.resource("health")

  message.setHandler("ivrpgguerrillatactics", function(_, _, damage, position, facingDirection)
    if damage > 0 and facingDirection == (world.distance(mcontroller.position(), position)[1] > 0 and 1 or -1) then
      self.powerTimer = 0
    end
  end)
  animator.setParticleEmitterOffsetRegion("powerEmbers", mcontroller.boundBox())
end


function update(dt)
  self.powerTimer = math.min(self.powerTimer + dt, 10)

  local newHealth = status.resource("health")
  if newHealth < self.health then
    self.powerTimer = 0
  end
  self.health = newHealth

  if self.powerTimer >= 10 then
    status.setPersistentEffects("ivrpgguerrillatactics", {
      {stat = "powerMultiplier", baseMultiplier = 1.5}
    })
  else
    status.clearPersistentEffects("ivrpgguerrillatactics")
  end

  animator.setParticleEmitterActive("powerEmbers", self.powerTimer >= 10)

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 6 or not (world.entityCurrency(self.id, "classtype") == 3 or world.entityCurrency(self.id, "classtype") == 4) then
    effect.expire()
  end
end

function reset()
  status.setPrimaryDirectives()
end

function uninit()
  animator.setParticleEmitterActive("powerEmbers", false)
  status.clearPersistentEffects("ivrpgguerrillatactics")
  reset()
end