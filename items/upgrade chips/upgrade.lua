function init()
  self.type = "ivrpguc" .. config.getParameter("type")
  self.stat = "ivrpguc" .. config.getParameter("stat")
end

function activate(fireMode, shiftHeld)
  --sb.logInfo(self.type .. " " .. self.stat)
  if not status.statPositive(self.type) then
    status.setPersistentEffects(self.type, {
      {stat = self.type, amount = 1},
      {stat = self.stat, amount = 1}
    })
    item.consume(1)
  end
end

function uninit()
end
