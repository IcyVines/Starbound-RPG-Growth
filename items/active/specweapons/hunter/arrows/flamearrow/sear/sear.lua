function init()
  --effect.setParentDirectives("border=1;BF330033;BF330033")
  self.length = effect.duration()
  self.sourceId = effect.sourceEntity()
end

function update(dt)
  if effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1}) then
    effect.expire()
  end
end

function uninit()
  if status.resource("health") <= 0 then
    local projectileId = world.spawnProjectile(
        "fireplasmaexplosionstatus",
        mcontroller.position(),
        self.sourceId,
        {0,0},
        false,
        {timeToLive = 0.25, power = status.resourceMax("health") * config.getParameter("healthDamageFactor", 1.0)}
      )
  end
  world.sendEntityMessage(self.sourceId, "modifyResource", "energy", 10)
end