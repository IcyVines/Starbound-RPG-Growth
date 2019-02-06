function init()
  script.setUpdateDelta(5)
  self.id = entity.id()
  self.elementColors = config.getParameter("elementColors", {})
end

function update(dt)
  local element = status.statusProperty("ivrpgsmithstatuselement")
  if element then
    status.setPersistentEffects("ivrpgsmithstatus", {
      {stat = element .. "Resistance", amount = 0.25}
    })
    time = effect.duration()
    local color = self.elementColors[element]
    if color then
      local ratio = (time / 15)^0.5 * 0.5
      effect.setParentDirectives("?fade=" .. color .. "=" .. tostring(ratio))
    end
  else
    effect.expire()
  end

  if not status.statusProperty("ivrpgprofessionpassive", false) then
    effect.expire()
  end

end

function reset()
  status.setStatusProperty("ivrpgsmithstatuselement", false)
  status.clearPersistentEffects("ivrpgsmithstatus")
  effect.setParentDirectives()
end

function uninit()
  reset()
end
