require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  _,self.damageUpdate = status.inflictedDamageSince()
  self.id = entity.id()
  self.colors = config.getParameter("colors")
  self.timer = 0
end

function update(dt)
  damageGiven()
  if self.element and self.timer > 0 then
    status.setPersistentEffects("ivrpg_alchemist_status_passive", {
      {stat = self.element .. "Resistance", amount = 0.5}
    })
    local color = self.colors[self.element]
    if color then
      local ratio = self.timer / 10 * 0.5
      effect.setParentDirectives("?fade=" .. color .. "=" .. tostring(ratio))
    end
  else
    reset()
  end
  self.timer = math.max(0, self.timer - dt)
end

function uninit()
  reset()
end

function reset()
  status.clearPersistentEffects("ivrpg_alchemist_status_passive")
  effect.setParentDirectives()
end

function damageGiven()
  local notifications = nil
  notifications, self.damageUpdate = status.inflictedDamageSince(self.damageUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      for element,color in pairs(self.colors) do
        if string.find(notification.damageSourceKind, element) then
          self.timer = 10
          self.element = element
        end
      end
    end
  end
end