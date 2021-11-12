function init()
  self.mod = config.getParameter("mod", 0)
end


function update(dt)
  local weaveMod = status.stat("ivrpgelementalweave")
  if weaveMod ~= self.mod then
    effect.expire()
  end
end