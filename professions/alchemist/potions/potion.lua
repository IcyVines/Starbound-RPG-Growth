require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.parameters = config.getParameter("parameters")
end

function update(dt)

end

function uninit()
  if self.parameters then
    sb.logInfo(sb.printJson(self.parameters))
    world.spawnProjectile("ivrpg_potionexplosion", mcontroller.position(), nil, {0,0}, false, self.parameters)
  end
end