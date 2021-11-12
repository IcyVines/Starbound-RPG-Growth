require "/scripts/keybinds.lua"

function init()
  self.cooldownTime = config.getParameter("cooldownTime", 60)
  self.cooldownTimer = 0
  Bind.create("f", checkPlacement)
end

function checkPlacement()
  if self.cooldownTimer <= 0 and world.placeObject("ivrpgflagpioneer", {mcontroller.xPosition(), mcontroller.yPosition()-2}, mcontroller.facingDirection()) then
    status.addEphemeralEffect("ivrpgcolonizecooldown", 600)
    self.cooldownTimer = self.cooldownTime
  end
end

function uninit()
  tech.setParentDirectives()
  status.removeEphemeralEffect("ivrpgcolonizecooldown")
end

function update(args)
  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - args.dt)
  end
end
