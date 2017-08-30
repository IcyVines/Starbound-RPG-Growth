function init()
  --activateVisualEffects()
  --effect.setParentDirectives("fade=77005F=0.25")
end

function update(dt)
end

function activateVisualEffects()
  --animator.setParticleEmitterOffsetRegion("bloodparticles", mcontroller.boundBox())
  --local statusTextRegion = { 0, 1, 0, 1 }
  --animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  --animator.burstParticleEmitter("statustext")
  --animator.burstParticleEmitter("smoke")
end


function uninit()
  self.id = effect.sourceEntity()
  if world.isMonster(self.id) or world.isNpc(self.id) then
    self.powerMod = 1
  else
    self.powerMod = 1 + world.entityCurrency(self.id, "intelligencepoint")*0.02
  end
  if status.resource("health") <= 0 then
    local projectileId = world.spawnProjectile(
        "iceprimednovaexplosion",
        mcontroller.position(),
        self.id,
        {0,0},
        false,
        {timeToLive = 0.25, power = 140, powerMultiplier = self.powerMod}
      )
  end
end
