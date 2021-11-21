require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.sourceId = effect.sourceEntity()
  message.setHandler("ivrpgFateSealed", function(_, _)
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damageSourceKind = "ivrpg_demonicdagger",
      damage = status.resource("health"),
      sourceEntityId = self.sourceId
    })
  end)
  animator.setAnimationState("status", "on")
  script.setUpdateDelta(0)
end

function uninit()
  if status.resource("health") <= 0 then
    local targets = enemyQuery(mcontroller.position(), 30, {withoutEntityId = entity.id()}, self.sourceId, true)
    if targets then
      for _,id in ipairs(targets) do
        world.sendEntityMessage(id, "ivrpgFateSealed")
      end
    end
  end
end