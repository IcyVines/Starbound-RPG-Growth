require "/scripts/util.lua"

function init()
  effect.setParentDirectives("border=1;00BBFF;00BBFF")
  self.effectId = effect.addStatModifierGroup({
    {stat = "physicalResistance", amount = -0.25}
  })
  self.sourceId = effect.sourceEntity()
  self.duration = 0
  if self.sourceId then
    self.message = world.sendEntityMessage(self.sourceId, "hasStat", "ivrpguccoldheart")
  end
end

function update(dt)
  if self.message:result() then
    self.duration = math.min(self.duration + 10*dt, 75)
    effect.setStatModifierGroup(self.effectId, {
      {stat = "physicalResistance", amount = -0.25 - 0.01 * self.duration},
      {stat = "poisonResistance", amount = -0.01 * self.duration},
      {stat = "electricResistance", amount = -0.01 * self.duration},
      {stat = "iceResistance", amount = -0.01 * self.duration}
    })
  end

  if effect.duration() and (hasEphemeralStat("burning") or hasEphemeralStat("melting")) then
    effect.expire()
  end

end

function uninit()
  if status.resource("health") <= 0 then
    local projectileId = world.spawnProjectile(
        "iceplasmaexplosionstatus",
        mcontroller.position(),
        self.sourceId,
        {0,0},
        false,
        {timeToLive = 0.25, power = status.resourceMax("health") * config.getParameter("healthDamageFactor", 1.0)}
      )
  end
end

function hasEphemeralStat(stat)
  ephStats = util.map(status.activeUniqueStatusEffectSummary(),
    function (elem)
      return elem[1]
    end)
  for _,v in pairs(ephStats) do
    if v == stat then return true end
  end
  return false
end