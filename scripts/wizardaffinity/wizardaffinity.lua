function init()
  self.id = effect.sourceEntity()
  self.resistanceBonusId = effect.addStatModifierGroup({})
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)
  local pamount = 0
  self.heldItem = world.entityHandItem(self.id, "primary")
  self.heldItem2 = world.entityHandItem(self.id, "alt")
  if self.heldItem then
    if root.itemHasTag(self.heldItem, "staff") or root.itemHasTag(self.heldItem, "wand") then
      pamount = 0.1
    end
  end
  if self.heldItem2 then
    if root.itemHasTag(self.heldItem2, "wand") then
      pamount = 0.1
    end
  end

  effect.setStatModifierGroup(self.resistanceBonusId, {
    {stat = "iceResistance", amount = pamount},
    {stat = "fireResistance", amount = pamount},
    {stat = "electricResistance", amount = pamount}
  })

  if pamount > 0 then
    animator.setParticleEmitterActive("embers", true)
  else
    animator.setParticleEmitterActive("embers", false)
  end

  if not status.statPositive("ivrpgclassability") then
  	effect.setParentDirectives("border=1;c132bf20;c132bf00")
  else
  	effect.setParentDirectives()
  end

  if world.entityCurrency(effect.sourceEntity(), "classtype") ~= 2 then
    effect.expire()
  end
end

function uninit()

end
