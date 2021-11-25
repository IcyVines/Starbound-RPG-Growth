function init()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
end

function update(dt)
  if status.resource("health") / status.resourceMax("health") <= 0.15 then
    if not self.electrocuted then
      animator.burstParticleEmitter("statustext")
      self.electrocuted = true
      world.sendEntityMessage(effect.sourceEntity(), "ivrpgElementressOvercharge")
    end
    status.modifyResourcePercentage("health", -1)
  end
end

function uninit()
   effect.setParentDirectives()
   status.setResource("stunned", 0)
end
