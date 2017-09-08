require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  sb.logInfo("explorer drill")
  self.active = false
  self.fireOffset = config.getParameter("fireOffset")
  self.aimAngle = 0
  self.facingDirection = 0
  self.drillSourceOffsets = {{1.0, -2.0}, {1.0, 0.0}, {1.0, 2.0}}
  self.drillTipOffset = {8, 0}
  self.tileDamage =  config.getParameter("tileDamage",10)
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
  end

end

function damageTiles(layer)
  local tipPosition = transformOffset(self.drillTipOffset)
  sb.logInfo("tipPosition: " .. tipPosition[1] .. ", " .. tipPosition[2])
  for _, sourceOffset in ipairs(self.drillSourceOffsets) do
    local sourcePosition = transformOffset(sourceOffset)
    local drillTiles = world.collisionBlocksAlongLine(sourcePosition, tipPosition, nil, 5)--self.damageTileDepth)
    sb.logInfo("sourcePosition: " .. sourcePosition[1] .. ", " .. sourcePosition[2])
    if #drillTiles > 0 then
      sb.logInfo("sourcePositionYes: " .. sourcePosition[1] .. ", " .. sourcePosition[2])
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
