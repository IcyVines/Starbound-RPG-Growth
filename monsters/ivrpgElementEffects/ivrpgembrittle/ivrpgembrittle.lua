function init()
  --animator.setParticleEmitterOffsetRegion("icetrail", mcontroller.boundBox())
  --animator.setParticleEmitterActive("icetrail", true)
  effect.setParentDirectives("border=1;00BBFF;00BBFF")

  --script.setUpdateDelta(5)
  effect.addStatModifierGroup({
    {stat = "physicalResistance", amount = -0.25}
  })
end

function update(dt)

end

function uninit()
  self.id = effect.sourceEntity()
  if status.resource("health") <= 0 then
    local projectileId = world.spawnProjectile(
        "iceplasmaexplosionstatus",
        mcontroller.position(),
        self.id,
        {0,0},
        false,
        {timeToLive = 0.25, power = status.resourceMax("health") * config.getParameter("healthDamageFactor", 1.0)}
      )
  end
end
