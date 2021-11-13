require "/scripts/ivrpgutil.lua"

function init()
  script.setUpdateDelta(0)
  message.setHandler("kill", projectile.die)
  mcontroller.applyParameters({
    collisionEnabled = false
  })

  message.setHandler("setPower", function(_, _, power)
    projectile.setPower(power)
  end)
end