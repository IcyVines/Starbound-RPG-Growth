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

  _, self.damageGivenUpdate = status.inflictedDamageSince() 
  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
  updateDamageGiven()
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

function updateDamageGiven()
  if not self.weapon.healOnHit then return end
  local percentage = 0
  local siphonIds = {}
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageSourceKind == "ivrpg_holynova" and notification.damageDealt > 0 and notification.healthLost > 0 and not siphonIds[targetEntityId] then
        local healthReturn = notification.healthLost or 1
        percentage = percentage + (healthReturn * self.weapon.healOnHit[1] / 100)
        siphonIds[notification.targetEntityId or ""] = true
      end
    end
  end
  if percentage > 0 then triggerHealingNova(math.min(percentage, self.weapon.healOnHit[2])) end
end

function triggerHealingNova(percent)
  world.spawnProjectile("ivrpg_holynovaheal", mcontroller.position(), activeItem.ownerEntityId(), {0,0}, true, {})
  local targets = friendlyQuery(mcontroller.position(), 10, {}, activeItem.ownerEntityId(), true)
  if targets then
    for _,id in ipairs(targets) do
      world.sendEntityMessage(id, "modifyResourcePercentage", "health", percent)
    end
  end
end