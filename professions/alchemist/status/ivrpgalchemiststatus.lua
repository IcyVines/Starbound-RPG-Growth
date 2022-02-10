require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  _,self.damageUpdate = status.damageTakenSince()
  self.id = entity.id()
  if config.getParameter("onInit") then
    status.modifyResourcePercentage(config.getParameter("stat", "health"), config.getParameter("amount", 0))
  end
end

function update(dt)
  effects = {}
  for stat,amount in pairs(config.getParameter("stats", {})) do
    table.insert(effects, {stat = stat, amount = amount})
  end

  allowed = true
  when = config.getParameter("when")
  if when then
    if when == "energyNotMaxed" and status.resource("energy") >= status.resourceMax("energy") then allowed = false end
  end

  if allowed then
    status.setPersistentEffects("ivrpg_alchemist_status", effects)
  else
    effect.expire()
  end
end

function uninit()
  reset()
end

function reset()
  status.clearPersistentEffects("ivrpg_alchemist_status")
end

function damageGiven()
  local notifications = nil
  notifications, self.damageUpdate = status.inflictedDamageSince(self.damageUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageSourceKind then
        for element,timer in pairs(self.elements) do
          if string.find(notification.damageSourceKind, element) then
            self.elements[element] = 10
          end
        end
      end
    end
  end
end