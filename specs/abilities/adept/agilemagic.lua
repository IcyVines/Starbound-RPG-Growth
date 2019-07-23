require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.burstReady = false
  self.speedStatus = config.getParameter("speedStatus")
  self.speedRange = config.getParameter("speedRange")
  self.statusLength = config.getParameter("statusLength")
  self.timer = 0
  --animator.setParticleEmitterOffsetRegion("feathers", mcontroller.boundBox())
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)
  local energy = status.resource("energy")
  local maxEnergy = status.stat("maxEnergy")
  local energyRatio = energy/maxEnergy
  local fullEnergy = energy == maxEnergy
  status.setPersistentEffects("ivrpgfluctuation", {
    {stat = "protection", effectiveMultiplier = 0.5 + energyRatio^4}
  })

  animator.setParticleEmitterActive("embers", fullEnergy)

  if energy < maxEnergy then
    self.burstReady = true
  end

  if self.burstReady and fullEnergy then
    self.burstReady = false
    speedPulse()
  end

  if self.timer > 0 then
    animator.setParticleEmitterEmissionRate("embers", 10)
    mcontroller.controlModifiers({
      speedModifier = 1.2
    })
    self.timer = math.max(self.timer - dt, 0)
    if self.timer == 0 then
      animator.setParticleEmitterEmissionRate("embers", 2)
      animator.setParticleEmitterActive("embers", false)
    end
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 4 or world.entityCurrency(self.id, "classtype") ~= 3 then
    effect.expire()
  end

end

function speedPulse()
  animator.setParticleEmitterActive("embers", true)
  self.timer = self.statusLength
  local targetIds = world.entityQuery(mcontroller.position(), self.speedRange, {
      withoutEntityId = self.id,
      includedTypes = {"creature"}
    })
    for i,id in ipairs(targetIds) do
    if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(self.id, id)) then
      world.sendEntityMessage(id, "addEphemeralEffect", self.speedStatus, self.statusLength, self.id)
    end
    end
end

function uninit()
  status.clearPersistentEffects("ivrpgfluctuation")
  animator.setParticleEmitterActive("embers", false)
end
