function init()
  --Power
  self.damageModifier = config.getParameter("powerModifier")

  effect.addStatModifierGroup({
    {stat = "energyRegenBlockTime", amount = -0.5},
    {stat = "physicalResistance", amount = -.20},
    {stat = "poisonResistance", amount = -.20},
    {stat = "fireResistance", amount = -.20},
    {stat = "electricResistance", amount = -.20},
    {stat = "iceResistance", amount = -.20},
    {stat = "shadowResistance", amount = -.20},
    {stat = "cosmicResistance", amount = -.20},
    {stat = "radioactiveResistance", amount = -.20},
    {stat = "grit", amount = -.20}
  })

  local enableParticles = config.getParameter("particles", true)
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", enableParticles)
  
end


function update(dt)
  mcontroller.controlModifiers({
    speedModifier = 0.75
  })

  local heldItem = world.entityHandItem(entity.id(), "primary")
  local heldItem2 = world.entityHandItem(entity.id(), "alt")

  if (heldItem and root.itemHasTag(heldItem, "ranged")) or (heldItem2 and root.itemHasTag(heldItem2, "ranged")) then
    status.setPersistentEffects("soldierfocus",
    {
      {stat = "powerMultiplier", effectiveMultiplier = self.damageModifier}
    })
  else
    status.clearPersistentEffects("soldierfocus")
  end

end

function uninit()
  status.clearPersistentEffects("soldierfocus")
end
