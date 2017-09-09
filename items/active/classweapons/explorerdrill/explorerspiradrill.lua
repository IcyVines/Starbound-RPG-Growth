require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  sb.logInfo("explorer drill")
  self.active = false
  self.fireOffset = config.getParameter("fireOffset")
  self.aimAngle = 0
  self.facingDirection = 0
  self.drillSourceOffsets = config.getParameter("drillSourceOffsets")
  self.drillTipOffset = config.getParameter("drillTipOffset")
  self.tileDamage =  config.getParameter("tileDamage",10)
  self.damageTileDepth = config.getParameter("damageTileDepth",3)
  self.damageSources = config.getParameter("damageSources")
end

function update(dt, fireMode, shiftHeld, moves)
  if fireMode == "primary" and not status.statPositive("activeMovementAbilities") then
    self.active = true
  else
    self.active = false
  end

  self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.facingDirection)
  activeItem.setArmAngle(self.aimAngle)

  if self.active then
    local layer = shiftHeld and "background" or "foreground"
    sb.logInfo("layer" .. layer)
    damageTiles(layer)
    animator.setAnimationState("drill", "active")
    activeItem.setItemDamageSources(self.damageSources)
  else
    animator.setAnimationState("drill", "idle")
  end

end

function damageTiles(layer)
  local tipPosition = transformOffset(self.drillTipOffset)
  for _, sourceOffset in ipairs(self.drillSourceOffsets) do
    local sourcePosition = transformOffset(sourceOffset)
    local drillTiles = world.collisionBlocksAlongLine(sourcePosition, tipPosition, nil, self.damageTileDepth)
    if #drillTiles > 0 then
      world.damageTiles(drillTiles, layer, sourcePosition, "blockish", self.tileDamage, 99)
    end
  end
end

function transformOffset(offset)
  offset = vec2.rotate(offset, self.aimAngle)
  offset[1] = offset[1] * self.facingDirection
  offset = vec2.add(mcontroller.position(), offset)
  return offset
end
