require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.movementParams = mcontroller.baseParameters()
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)
  self.heldItem = world.entityHandItem(self.id, "primary")
  self.heldItem2 = world.entityHandItem(self.id, "alt")

  if (self.heldItem and (root.itemHasTag(self.heldItem, "whip") or root.itemHasTag(self.heldItem, "warfan")))
  or (self.heldItem2 and (root.itemHasTag(self.heldItem2, "whip") or root.itemHasTag(self.heldItem2, "warfan"))) then
    mcontroller.controlModifiers({
      speedModifier = 1.2
    })
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 3 or world.entityCurrency(self.id, "classtype") ~= 3 then
    effect.expire()
  end
end

function reset()
  animator.setParticleEmitterActive("embers", false)
  status.setPrimaryDirectives()
end

function uninit()
  reset()
end
