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

  spawnGlassShards(math.random(7, 12))
end

function spawnGlassShards(count)
  for i=1,count do
    world.spawnProjectile("ivrpg_glassshard", vec2.add(mcontroller.position(), {0, 0.25}), nil, {math.random()*2 - 1, math.random()}, false)
  end
end