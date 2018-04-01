function init()
  effect.setParentDirectives("fade=FFFFFF=0.25?border=1;fffeee;fffaaa")

  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  effect.addStatModifierGroup({
    {stat = "holyResistance", amount = -0.25}
  })
end

function update(dt)
  mcontroller.controlParameters({
    gravityEnabled = true,
    collisionEnabled = true
  })
end

function uninit()
   effect.setParentDirectives()
end
