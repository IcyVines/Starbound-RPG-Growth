require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

function init()
  activeItem.setCursor("/cursors/reticle5.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, 0)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAttack = getAltAbility(self.weapon.elementalType)
  if secondaryAttack then
    self.weapon:addAbility(secondaryAttack)
  end

  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
  self.weapon:uninit()
end

function Weapon:createBarrier(params)
  status.setPersistentEffects("ivrpg_greaterbarrier", {{stat = "shieldHealth", amount = params.health}})

  local blockPoly = params.poly
  activeItem.setShieldPolys({blockPoly})

  --if self.knockback > 0 then
  local knockback = (params.knockback or 0) * (status.resourcePositive("perfectBlock") and 2 or 1)
  local knockbackDamageSource = {
    poly = blockPoly,
    damage = params.power,
    damageType = params.damageType or "Knockback",
    sourceEntity = activeItem.ownerEntityId(),
    team = activeItem.ownerTeam(),
    knockback = knockback,
    rayCheck = true,
    damageRepeatTimeout = 0.5
  }
  activeItem.setDamageSources({ knockbackDamageSource })
end