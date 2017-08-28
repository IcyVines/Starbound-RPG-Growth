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
  if status.resource("health") <= 0 then
    local projectileId = world.spawnProjectile(
        "fireprimednovaexplosion",
        mcontroller.position(),
        effect.sourceEntity(),
        {0,0},
        false,
        {timeToLive = 0.25, power = 100}
      )
  end
end
