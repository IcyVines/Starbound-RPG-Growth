require "/scripts/util.lua"

function init()
  --effect.setParentDirectives("border=1;00BBFF33;00BBFF33")
  self.sourceId = effect.sourceEntity()
end

function uninit()
  if status.resource("health") <= 0 then
    local projectileId = world.spawnProjectile(
        "ivrpgsoulessence",
        mcontroller.position(),
        entity.id(),
        {0,0},
        false,
        {timeToLive = 30, statusEffects = {{effect = "regeneration4", duration = math.min(status.resourceMax("health") ^ 0.25, 10)}}}
      )
  end
end