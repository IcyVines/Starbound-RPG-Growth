require "/scripts/ivrpgutil.lua"

function init()
  self.timer = 0
  animator.setAnimationState("blink", "blinkout")
  effect.setParentDirectives("?multiply=ffffff00")
  animator.playSound("activate")
  effect.addStatModifierGroup({
      {stat = "invulnerable", amount = 1},
      {stat = "lavaImmunity", amount = 1},
      {stat = "poisonStatusImmunity", amount = 1},
      {stat = "tarImmunity", amount = 1},
      {stat = "waterImmunity", amount = 1},
      {stat = "activeMovementAbilities", amount = 1}
  })
  mcontroller.setVelocity({0,0})
  mcontroller.controlModifiers({
    speedModifier = 0,
    airJumpModifier = 0
  })

  self.id = entity.id()
end

function update(dt)
  mcontroller.setVelocity({0,0})
  mcontroller.controlModifiers({
    speedModifier = 0,
    airJumpModifier = 0
  })
  if animator.animationState("blink") == "none" then
    teleport()
  end
  status.setResourcePercentage("energyRegenBlock", 1.0)
end

function teleport()
  mcontroller.setVelocity({0,0})
  mcontroller.controlModifiers({
    speedModifier = 0,
    airJumpModifier = 0
  })
  local discId = status.statusProperty("translocatorDiscId")
  if discId and world.entityExists(discId) then
    local teleportTarget = world.callScriptedEntity(discId, "teleportPosition", mcontroller.collisionPoly())
    local isNotMissionWorld = ((world.terrestrial() or world.type() == "outpost" or world.type() == "scienceoutpost") and world.dayLength() ~= 100000) or (status.statPositive("admin") or status.statPositive("ivrpgucphaseout"))
    local notThroughWalls = true
    if (teleportTarget) then
      -- notThroughWalls = not world.lineTileCollision(teleportTarget, mcontroller.position())
      notThroughWalls = ivrpgHasPath(mcontroller, teleportTarget)
    else
      notThroughWalls = true
    end
    teleportTarget = (isNotMissionWorld or notThroughWalls) and teleportTarget or nil
    if teleportTarget then
      local agility = status.statusProperty("ivrpgagility", 1)
      local distance = world.magnitude(teleportTarget, mcontroller.position())
      local costPercent = math.min(-(1.06^(distance*2-agility)+20.0)/100.0, -0.05)
      status.modifyResourcePercentage("energy", costPercent)
      status.overConsumeResource("energy", 1)
      mcontroller.setPosition(teleportTarget)
    end
    world.callScriptedEntity(status.statusProperty("translocatorDiscId"), "kill")
  end
  status.setStatusProperty("translocatorDiscId", nil)

  effect.setParentDirectives("")
  animator.burstParticleEmitter("translocate")
  animator.setAnimationState("blink", "blinkin")

  local dps = 0
  local multiplier = 0
  local damage = 0
  local twoHanded = false

  local heldItem = world.entityHandItem(self.id, "primary")
  local heldItem2 = world.entityHandItem(self.id, "alt")
  local itemConf = ivrpgBuildItemConfig(self.id, "primary")
  if itemConf and itemConf.config and itemConf.config.twoHanded then twoHanded = true end

  if twoHanded then
    if heldItem and root.itemHasTag(heldItem, "melee") and not root.itemHasTag(heldItem, "hammer") then
      dps = getDpsFromConfig(itemConf)
      damage = 2 * status.stat("powerMultiplier") * dps
    end
  else
    if heldItem and (root.itemHasTag(heldItem, "melee") or root.itemHasTag(heldItem, "ninja") or root.itemHasTag(heldItem, "claw")) then
      dps = getDpsFromConfig(itemConf)
      multiplier = 1.5
    end
    damage = dps

    dps = 0
    if heldItem2 and (root.itemHasTag(heldItem2, "melee") or root.itemHasTag(heldItem2, "ninja") or root.itemHasTag(heldItem2, "claw")) then
      itemConf = ivrpgBuildItemConfig(self.id, "alt")
      dps = getDpsFromConfig(itemConf)
      multiplier = multiplier == 0 and 1.5 or multiplier * 1.5
    end
    damage = damage + dps
    damage = damage * multiplier * status.stat("powerMultiplier")
  end

  if damage > 0 then
    local damageConfig = {
      power = damage
    }
    animator.playSound("slash")
    world.spawnProjectile("ninjaassassinateswoosh", {mcontroller.xPosition() + mcontroller.facingDirection()*5, mcontroller.yPosition()}, self.id, {0,0}, false, damageConfig)
  end
end

function getDpsFromConfig(config)
  if config and config.config then
    if config.config.primaryAbility then
      return config.config.primaryAbility.baseDps or 1
    elseif config.config.projectileConfig then
      return config.config.projectileConfig.power or 1
    else
      return 1
    end
  else
    return 1
  end
end

function uninit()
  
end
