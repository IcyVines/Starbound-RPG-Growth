function init()
  effect.addStatModifierGroup({
    {stat = "powerMultiplier", baseMultiplier = 0.75}
  })
  animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
  animator.setParticleEmitterOffsetRegion("smoke", {0,1,0,0})
  animator.setParticleEmitterActive("smoke", true)
end

function update(dt)

end

function uninit()
  animator.setParticleEmitterActive("smoke", false)
end
