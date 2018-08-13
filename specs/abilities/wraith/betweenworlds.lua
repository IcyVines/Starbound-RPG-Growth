require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.timer = 0
  self.damageUpdate = 5
  self.movementParams = mcontroller.baseParameters()
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)

  self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if self.notifications then
    for _,notification in pairs(self.notifications) do
      if notification.healthLost > 0 and not status.statPositive("activeMovementAbilities") then
        self.timer = 2
        animator.playSound("ghostly", -1)
      end
    end
  end

  local oldGravityMultiplier = self.movementParams.gravityMultiplier or 1
  local newGravityMultiplier = 0.05 * oldGravityMultiplier
  mcontroller.controlParameters({
     gravityMultiplier = newGravityMultiplier
  })

  if self.timer > 0 then
    mcontroller.controlParameters({
      collisionEnabled = false
    })
    status.setPersistentEffects("ivrpgbetweenworlds", {
      {stat = "invulnerable", amount = 1}
    })
    self.timer = math.max(0, self.timer - dt)
    animator.setParticleEmitterActive("embers", true)
    status.setPrimaryDirectives("?multiply=77DDAABB")
    if self.timer == 0 or status.statPositive("activeMovementAbilities") then
      reset()
    end
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 6 or not (world.entityCurrency(self.id, "classtype") == 5 or world.entityCurrency(self.id, "classtype") == 2) then
    effect.expire()
  end
end

function reset()
  animator.setParticleEmitterActive("embers", false)
  status.clearPersistentEffects("ivrpgbetweenworlds")
  animator.stopAllSounds("ghostly")
  status.setPrimaryDirectives()
end

function uninit()
  reset()
end
