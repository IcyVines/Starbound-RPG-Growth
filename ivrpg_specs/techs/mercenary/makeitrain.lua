require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/tech/soldiertech/soldierenergypack/soldierenergypack.lua"
require "/tech/ivrpgopenrpgui.lua"

ivrpgOldInit = init
ivrpgOldUpdate = update

function init()
  ivrpgOldInit()
  self.dropTime = self.dashDuration / config.getParameter("dropsPerDash", 1)
  self.dropTimer = 1
  self.drops = config.getParameter("drops", {"molotov", "ivrpgskittergrenade", "ivrpgshockcharge", "ivrpgstungrenade"})
  self.energyCost = config.getParameter("energyCost", 10)
end

function update(args)

  ivrpgOldUpdate(args)
  if self.dashTimer > 0 and not args.moves["run"] then
    if self.dropTimer >= self.dropTime then
      local direction = {-self.hDirection, -self.vDirection}
      if direction[1] == 0 and direction[2] == 0 then direction = {0, -1} end
      if status.overConsumeResource("energy", self.energyCost) then
        for i=-1,1 do
          local newDirection = vec2.rotate(direction, math.pi / 4 * i)
          world.spawnProjectile(self.drops[math.random(#self.drops)], mcontroller.position(), entity.id(), newDirection, false, {speed = 20, power = 10, powerMultiplier = status.stat("powerMultiplier")})
        end
        self.dropTimer = 0
      end
    end
  else
    self.dropTimer = 1
  end

end