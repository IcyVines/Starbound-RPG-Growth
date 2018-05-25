function init()
  self.requiredClass = config.getParameter("requiredClass", 7)
  self.requiredClass2 = config.getParameter("requiredClass2", 7)
  self.specType = config.getParameter("specType", 0)
  self.class = player.currency("classtype")
  self.gender = config.getParameter("gender", false)
end

function activate(fireMode, shiftHeld)
  if player.currency("experienceorb") < 122500 then return end
  if self.requiredClass ~= self.class and self.requiredClass2 ~= self.class then return end
  player.consumeCurrency("spectype", player.currency("spectype"))
  player.addCurrency("spectype", self.specType)
  item.consume(1)
end

function uninit()
end