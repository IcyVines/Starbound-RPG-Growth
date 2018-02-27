function init()
  self.type = "ivrpguc" .. config.getParameter("type")
  self.stat = "ivrpguc" .. config.getParameter("stat")
  self.gendered = config.getParameter("gender", false)
end

function activate(fireMode, shiftHeld)
  --sb.logInfo(self.type .. " " .. self.stat)
  if self.gendered and self.gendered ~= player.gender() then return end;

  if status.statPositive(self.type) then
    local effects = status.getPersistentEffects(self.type)
    local uc = effects[2].stat or "masterypoint"
    player.giveItem(uc)
  end
  status.setPersistentEffects(self.type, {
      {stat = self.type, amount = 1},
      {stat = self.stat, amount = 1}
    })
  item.consume(1)
end

function uninit()
end
