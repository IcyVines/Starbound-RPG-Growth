function init()
  self.spawnedTether = false
end

function update(dt)
  if projectile.timeToLive() > 1 and mcontroller.isColliding() then projectile.setTimeToLive(1) end
  if mcontroller.isColliding() then spawnTether() end
  mcontroller.applyParameters({gravityMultiplier = 0.3})
end

function uninit()
  spawnTether()
end

function spawnTether()
  if not self.spawnedTether then
    self.spawnedTether = true
    local action = projectile.getParameter("spawnTether", nil)
    if action then
      action.config = {timeToLive = math.max(1, projectile.getParameter("speed", 120) / 24)}
      projectile.processAction(action)
    end
  end
end