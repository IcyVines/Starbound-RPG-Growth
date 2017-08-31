require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  sb.logInfo("proj")
end

function update(dt)
	--sb.logInfo("update")
  if mcontroller.isColliding() then
  	--sb.logInfo("updateC" .. projectile.power())
    projectile.setPower(projectile.power()*1.1)
  end
end