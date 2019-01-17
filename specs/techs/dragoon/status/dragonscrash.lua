function init()
  effect.addStatModifierGroup({
  	{stat = "invulnerable", amount = 1},
  	{stat = "grit", amount = 1}
  })
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
  effect.setParentDirectives("border=3;ff230f20;47090300")
end
