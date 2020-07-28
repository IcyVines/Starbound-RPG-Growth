function init()
	self.expire = config.getParameter("expireAfterHit", false)
end

function update(dt)
  if projectile.timeToLive() > 1 and mcontroller.isColliding() then projectile.setTimeToLive(1) 
  elseif self.expire and mcontroller.isColliding() then projectile.die() end
  mcontroller.applyParameters({gravityMultiplier = 0.3})
end