function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterActive("healing", config.getParameter("particles", true))

  script.setUpdateDelta(5)
  self.sourceId = effect.sourceEntity()
  self.id = entity.id()
end

function update(dt)
  checkWeapons()
  status.modifyResourcePercentage("health", dt * 0.01)
end

function checkWeapons()
  self.heldItem = world.entityHandItem(self.id, "primary")
  self.heldItem2 = world.entityHandItem(self.id, "alt")
  if (self.heldItem and (root.itemHasTag(self.heldItem, "staff") or root.itemHasTag(self.heldItem, "wand"))) or (self.heldItem2 and root.itemHasTag(self.heldItem2, "wand")) then
    status.setPersistentEffects("ivrpgodinsblessing", {
      { stat = "powerMultiplier", effectiveMultiplier = 1.33 }
    })
  else
    status.setPersistentEffects("ivrpgodinsblessing", {})
  end
end

function uninit()
  effect.setParentDirectives()
  status.clearPersistentEffects("ivrpgodinsblessing")
end