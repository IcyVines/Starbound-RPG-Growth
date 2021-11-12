require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.timer = 0
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)

  if mcontroller.groundMovement() and not mcontroller.running() and not mcontroller.walking() then
    self.timer = self.timer + dt
  else
    self.timer = 0
  end

  status.setPersistentEffects("ivrpgdeadlypatience", {
    {stat = "ivrpgBleedChance", amount = math.min(math.floor(self.timer) * 0.025, 0.5)},
    {stat = "ivrpgBleedLength", amount = math.min(math.floor(self.timer) * 0.05, 1)}
  })

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 2 or world.entityCurrency(self.id, "classtype") ~= 4 then
    effect.expire()
  end
end

function reset()
  animator.setParticleEmitterActive("embers", false)
  status.setPrimaryDirectives()
  status.clearPersistentEffects("ivrpgdeadlypatience")
end

function uninit()
  reset()
end
