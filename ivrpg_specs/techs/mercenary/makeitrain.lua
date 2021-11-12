require "/scripts/keybinds.lua"
require "/tech/soldiertech/soldierenergypack/soldierenergypack.lua"
require "/tech/ivrpgopenrpgui.lua"

ivrpgOldInit = init
ivrpgOldUpdate = update

function init()
  ivrpgOldInit()
  self.dropTime = self.dashDuration / config.getParameter("dropsPerDash", 1)
  self.dropTimer = 0
  self.drops = config.getParameter("drops", {"molotov", "ivrpgskittergrenade", "ivrpgshockcharge", "ivrpgstungrenade"})
end

function update(args)

  ivrpgOldUpdate(args)
  if self.dashTimer > 0 then
    self.dropTimer = self.dropTimer + args.dt
    if self.dropTimer >= self.dropTime then
      world.spawnProjectile(self.drops[math.random(1,4)], mcontroller.position(), entity.id(), {0,-1}, false, {speed = 20})
      self.dropTimer = 0
    end
  else
    self.dropTimer = 0
  end

end