require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/ivrpgutil.lua"

function init()
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, 0)
  self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAbility = getAltAbility(self.weapon.elementalType)
  if secondaryAbility then
    self.weapon:addAbility(secondaryAbility)
  end

  message.setHandler("hitEnemyOperative", function(_, _, damage, damageKind, entityId)
    if damage > 0 then status.modifyResource("energy", math.min(damage / 10, 5)) end
  end)

  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  incorrectWeapon()

  status.setPersistentEffects("ivrpgwbreathless", {
    {stat = "energyRegenBlockTime", effectiveMultiplier = 0},
    {stat = "energyRegenPercentageRate", effectiveMultiplier = 0.1}
  })
  status.setResourceLocked("energy", false)

  self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
  status.clearPersistentEffects("ivrpgwbreathless")
  incorrectWeapon(true)
  self.weapon:uninit()
end
