function init()
  --animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  --animator.setParticleEmitterActive("flames", true)
  --effect.setParentDirectives("fade=BF3300=0.25")
  effect.setParentDirectives("border=1;BF3300;BF3300")
  --animator.playSound("burn", -1)

  status.addEphemeralEffect("burning", effect.duration())

  effect.addStatModifierGroup({
    {stat = "powerMultiplier", effectiveMultiplier = 0.75}
  })
end

function update(dt)
  if effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1}) then
    effect.expire()
  end
end

function uninit()
  
end
