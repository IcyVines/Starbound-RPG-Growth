require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  sb.logInfo("explorer drill")
  self.active = false
  self.fireOffset = config.getParameter("fireOffset")
  self.aimAngle = 0
  self.facingDirection = 0
end

function update(dt, fireMode, shiftHeld, moves)
  if fireMode == "primary" and not status.stat("activeMovementAbilities") then
    self.active = true
  else
    self.active = false
  end

  self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.facingDirection)
  activeItem.setArmAngle(self.aimAngle)

  if self.active then
    sb.logInfo("drilling " .. (shiftHeld and "background" or "foreground"))
  end

end