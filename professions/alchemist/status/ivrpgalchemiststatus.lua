require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.damageUpdate = 5
  self.colors = config.getParameter("colors", {})
  self.elements = config.getParameter("elements", {})
  self.id = entity.id()
end

function update(dt)
  --While Underground, gain +10 Armor, +10% Physical Resistance, and +20% Fall Damage Resistance.
  damageGiven()
  reset()

  local directives = ""
  local directivesCount = 0
  for element,timer in pairs(self.elements) do
    if timer > 0 then
      status.addPersistentEffect("ivrpgalchemiststatus", {stat = element .. "Resistance", amount = 0.5})
      if directivesCount < 2 then
        directives = directives .. "?border=1;" .. self.colors[element] .. ";" .. self.colors[element]
        directivesCount = directivesCount + 1
      end
    end
    self.elements[element] = math.max(self.elements[element] - dt, 0)
  end
  effect.setParentDirectives(directives)

end

function uninit()
  reset()
end

function reset()
  status.clearPersistentEffects("ivrpgalchemiststatus")
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