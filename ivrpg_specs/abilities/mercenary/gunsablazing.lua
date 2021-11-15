require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = effect.sourceEntity()
  self.energyToDamageRatio = 0
  self.previousWeaponry = false
  self.maxEnergy = status.resourceMax("energy")
  animator.setParticleEmitterOffsetRegion("rageEmbers", mcontroller.boundBox())
  animator.setParticleEmitterOffsetRegion("unrageEmbers", mcontroller.boundBox())
end


function update(dt)

  local currentEnergy = status.resource("energy")
  local correctWeaponry = checkWeaponCombo()

  if self.previousWeaponry and correctWeaponry then
    if currentEnergy < self.previousEnergy then
      self.energyToDamageRatio = self.energyToDamageRatio + dt * (1 + self.energyToDamageRatio)
    elseif currentEnergy > self.previousEnergy then
      self.energyToDamageRatio = math.max(self.energyToDamageRatio - dt * (1 + self.energyToDamageRatio), 0)
    end
  else
    self.energyToDamageRatio = 0
  end

  status.setPersistentEffects("ivrpg_gunsablazing", {
    {stat = "powerMultiplier", baseMultiplier = math.min(1 + self.energyToDamageRatio, 4)}
  })
  --[[
  if self.powerTimer > 0 then
    status.setPersistentEffects("ivrpgfightinglion", {
      { stat = "powerMultiplier", baseMultiplier = self.power}
    })
    status.modifyResourcePercentage("energy", dt*self.energy)
    self.powerTimer = math.max(self.powerTimer-dt, 0)
    animator.setParticleEmitterActive("embers", true)
  else
    status.clearPersistentEffects("ivrpgfightinglion")
    animator.setParticleEmitterActive("embers", false)
  end
  ]]
  

  self.previousEnergy = currentEnergy
  self.previousWeaponry = correctWeaponry
  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 9 or not (world.entityCurrency(self.id, "classtype") == 4 or world.entityCurrency(self.id, "classtype") == 5) then
    effect.expire()
  end
end

function uninit()
  status.clearPersistentEffects("ivrpg_gunsablazing")
end

function checkWeaponCombo()
  local weaponTypes = {"smg", "pistol", "machinepistol"}
  self.heldItem = world.entityHandItem(self.id, "primary")
  self.heldItem2 = world.entityHandItem(self.id, "alt")
  if not self.heldItem or not self.heldItem2 then return false end
  for _,tag in ipairs(weaponTypes) do
    for _,tag2 in ipairs(weaponTypes) do
      if root.itemHasTag(self.heldItem, tag) and root.itemHasTag(self.heldItem2, tag2) then
        return true
      end
    end
  end
end
