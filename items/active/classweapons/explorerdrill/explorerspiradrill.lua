require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  --sb.logInfo("explorer drill")
  self.active = false
  self.fireOffset = config.getParameter("fireOffset")
  self.aimAngle = 0
  self.facingDirection = 0
  self.drillSourceOffsets = config.getParameter("drillSourceOffsets")
  self.origDrillSourceOffsets = self.drillSourceOffsets
  self.drillTipOffset = config.getParameter("drillTipOffset")
  self.tileDamage =  config.getParameter("tileDamage",10)
  self.damageTileDepth = config.getParameter("damageTileDepth",3)
  self.cost = config.getParameter("cost", 10)
  self.name = item.name()
  self.damageBonus = config.getParameter("damage", 1)
  self.id = activeItem.ownerEntityId()
  self.spwDamageBonus = 1
  animator.setSoundVolume("active", 0, 0)
  animator.playSound("active", -1)
end

function update(dt, fireMode, shiftHeld, moves)
  if fireMode == "primary" and not status.statPositive("activeMovementAbilities") then
    self.active = true
  else
    self.active = false
  end

  self.spinToWin = status.statPositive("ivrpgucspintowin") and self.name == "explorerspiradrill3"
  self.rightHandMan = status.statPositive("ivrpgucrighthandman") and self.name == "explorerspiradrill3" and activeItem.hand() == "alt"

  if self.spinToWin then
    self.spwDamageBonus = 2
    self.drillSourceOffsets = {{3.4, -1.6}, {3.4, -0.05}, {3.4, 1.5}}
  else
    self.spwDamageBonus = 1
    self.drillSourceOffsets = self.origDrillSourceOffsets
  end

  self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.facingDirection)
  activeItem.setArmAngle(self.aimAngle)

  if self.active and status.overConsumeResource("energy", self.cost*dt*self.spwDamageBonus) then
    if self.name ~= "explorerspiradrill" then
      local dropList = world.itemDropQuery(mcontroller.position(), 10)
      if dropList then
        world.spawnProjectile("spirapullzone", mcontroller.position(), self.id, {0,0}, true)
      end
    end
    local layer = "foreground"
    self.tileGroup = {"Block"}
    if self.rightHandMan then
      layer = "background"
      self.tileGroup = {"None", "Block", "Platform", "Slippery"}
    end
    self.drops = (shiftHeld and self.name == "explorerspiradrill3") and 0 or 99
    animator.setLightActive("glow", true)
    damageTiles(layer)
    local vigor = world.entityCurrency(self.id, "vigorpoint")
    local damageTimeout = 0.4 - vigor/200
    local damageBonus = self.damageBonus + status.stat("powerMultiplier")

    animator.setAnimationState("drill", "active")
    
    activeItem.setItemDamageSources({
        {
          enabled = false,
          attachToPart = drill,
          --poly = {{8, 2.5}, {2, 0.75}, {2, 4.25}},
          poly = {{4.2, -1.55}, {7.85, 0.0}, {4.2, 1.55}},
          damage = damageBonus*self.spwDamageBonus,
          damageSourceKind = "electricplasma",
          damageRepeatTimeout = damageTimeout,
          damageRepeatGroup = "leftArmDrill",
          knockback = 3,
          rayCheck = true
        }
    })
    animator.setSoundVolume("active", 1, 0)
  else
    activeItem.setItemDamageSources()
    animator.setLightActive("glow", false)
    animator.setAnimationState("drill", "idle")
    animator.setSoundVolume("active", 0, 0)
  end

end

function uninit()
  animator.setLightActive("glow", false)
  animator.stopAllSounds("active")
end

function damageTiles(layer)
  local tipPosition = transformOffset(self.drillTipOffset)
  for _, sourceOffset in ipairs(self.drillSourceOffsets) do
    local sourcePosition = transformOffset(sourceOffset)
    local drillTiles = world.collisionBlocksAlongLine(sourcePosition, tipPosition, self.tileGroup, self.damageTileDepth)
    if #drillTiles > 0 then
      world.damageTiles(drillTiles, layer, sourcePosition, "blockish", self.tileDamage, self.drops)
      if self.drops == 0 and layer == "foreground" then
        status.modifyResourcePercentage("energy", #drillTiles * 0.001)
      end
    end
  end
end

function transformOffset(offset)
  offset = vec2.rotate(offset, self.aimAngle)
  offset[1] = offset[1] * self.facingDirection
  offset = vec2.add(mcontroller.position(), offset)
  return offset
end
