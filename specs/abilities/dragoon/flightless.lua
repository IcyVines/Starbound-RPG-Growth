require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.timer = 0
  self.beganFall = false
  self.position = false
  self.regenTime = config.getParameter("regenTime", 5)
  self.movementParams = mcontroller.baseParameters()
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)

  if mcontroller.falling() and not self.beganFall then
    self.beganFall = true
    self.position = mcontroller.position()
  end

  if self.position and mcontroller.onGround() then
    local distance = world.distance(self.position, mcontroller.position())[2]
    animator.setParticleEmitterEmissionRate("embers", distance/2)
    if distance > 15 then
      animator.playSound("thud")
      animator.setParticleEmitterActive("embers", true)
      self.timer = math.min(6, distance / 8)
      status.setPersistentEffects("ivrpgflightless", {
        {stat = "protection", amount = distance/2},
        {stat = "powerMultiplier", baseMultiplier = 1 + (distance/100)}
      })
    end
    self.position = false
  end

  if mcontroller.onGround() or mcontroller.liquidMovement() or mcontroller.groundMovement() then
    self.beganFall = false
  end

  if self.timer > 0 then
    self.timer = math.max(self.timer - dt, 0)
    if self.timer == 0 then
      reset()
    end
  end
  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 8 or (world.entityCurrency(self.id, "classtype") ~= 4 and world.entityCurrency(self.id, "classtype") ~= 1) then
    effect.expire()
  end
end

function reset()
  animator.setParticleEmitterActive("embers", false)
  status.setPrimaryDirectives()
  status.clearPersistentEffects("ivrpgflightless")
end

function uninit()
  reset()
end
