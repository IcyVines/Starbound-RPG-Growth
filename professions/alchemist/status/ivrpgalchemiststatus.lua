require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  _,self.damageUpdate = status.damageTakenSince()
  self.id = entity.id()
  self.toxicity = status.statusProperty("ivrpg_alchemic_toxicity", 0)

  self.toxicityModifier = config.getParameter("toxicityModifier", 1)
  if status.isResource("energy") then
    self.lastMaxEnergy = status.resourceMax("energy")
    self.lastEnergy = status.resource("energy")
  end
  self.when = config.getParameter("when")
  self.type = config.getParameter("type")
  self.charges = config.getParameter("charges", 0)

  -- For Effects that happen instantly
  if config.getParameter("onInit") then
    status.modifyResourcePercentage(config.getParameter("stat", "health"), config.getParameter("amount", 0))
  end

  status.setStatusProperty("ivrpg_alchemy_active", true)
end

function update(dt)

  -- Potions with a 'type' supersede other potions of the same type
  if self.type then
    for i = 1,self.charges - 1,1 do
      status.removeEphemeralEffect("ivrpg_alchemic_" .. self.type .. tostring(i))
    end
  end

  -- Add stats to effect table
  effects = {}
  for stat,amount in pairs(config.getParameter("stats", {})) do
    table.insert(effects, {stat = stat, amount = amount})
  end

  -- Check if there is a condition that needs to be fulfilled for stats to trigger.
  allowed = true
  if self.when then
    if self.when == "notDealingDamage" and damageGiven() then allowed = false end
  end

  -- Remove effect if condition fails.
  if allowed then
    status.setPersistentEffects("ivrpg_alchemist_status", effects)
  else
    effect.expire()
  end

  if self.type and self.type == "heal" then
    -- Trigger AutoHeal
    if self.when and status.resource("health") / status.resourceMax("health") <= self.when then
      status.modifyResourcePercentage("health", config.getParameter("autoHeal", 0))
      if self.charges > 1 then status.addEphemeralEffect("ivrpg_alchemic_heal" .. tostring(self.charges - 1)) end
      effect.expire()
    end
  elseif self.type and self.type == "bleed" then
    if status.resource("energy") < status.resourceMax("energy") then
      status.setPersistentEffects("ivrpg_alchemist_status", {
        {stat = "powerMultiplier", amount = 0.2},
        {stat = "ivrpgBleedChance", amount = 0.2}
      })
    elseif self.lastEnergy ~= status.resourceMax("energy") and self.lastMaxEnergy == status.resourceMax("energy") then
      effect.expire()
    else
      status.clearPersistentEffects("ivrpg_alchemist_status")
    end
  end

  if status.isResource("energy") then
    self.lastMaxEnergy = status.resourceMax("energy")
    self.lastEnergy = status.resource("energy")
  end
  damageGiven()

  -- Apply new toxicity
  self.toxicity = status.statusProperty("ivrpg_alchemic_toxicity", 0)
  status.setStatusProperty("ivrpg_alchemic_toxicity", self.toxicity + dt / self.toxicityModifier)
  status.setPersistentEffects("ivrpg_alchemy_active", {
    {stat = "ivrpg_alchemy_active", amount = 1}
  })

end

function uninit()
  reset()
  status.clearPersistentEffects("ivrpg_alchemy_active")
end

function reset()
  status.clearPersistentEffects("ivrpg_alchemist_status")

  if self.charges > 1 and self.type then
    status.addEphemeralEffect("ivrpg_alchemic_" .. self.type .. tostring(self.charges - 1))
  end
end

function damageGiven()
  local notifications = nil
  notifications, self.damageUpdate = status.inflictedDamageSince(self.damageUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageDealt > 0 then
        return true
      end
      --[[if notification.damageSourceKind then
        for element,timer in pairs(self.elements) do
          if string.find(notification.damageSourceKind, element) then
            self.elements[element] = 10
          end
        end
      end]]
    end
  end
end