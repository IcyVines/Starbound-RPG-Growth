function init()
  self.affinityList = root.assetJson("/affinityList.config")
  self.classList = root.assetJson("/classList.config")
end

function activate(fireMode, shiftHeld)
  self.affinity = player.currency("affinitytype")
  self.affinity = self.affinity > 0 and self.affinity or 9
  self.affinityInfo = root.assetJson("/affinities/" .. self.affinityList[self.affinity] .. ".config")

  if item.name() == "ivrpgscrollresetaffinity" and self.affinity ~= 9 then
    consumeAffinityStats()
    consumeAllCurrency("affinitytype")
    item.consume(1)
  elseif item.name() == "ivrpgscrollresetclass" and player.currency("classtype") ~= 0 then
    local points = 0
    points = consumeAllCurrency("agilitypoint")
          + consumeAllCurrency("dexteritypoint")
          + consumeAllCurrency("endurancepoint")
          + consumeAllCurrency("intelligencepoint")
          + consumeAllCurrency("strengthpoint")
          + consumeAllCurrency("vigorpoint")
          + consumeAllCurrency("vitalitypoint")
          - 20
    for k,v in pairs(self.affinityInfo.stats) do
      player.addCurrency(k .. "point", v)
      points = points - v
    end
    local stats = {"strength", "agility", "vitality", "vigor", "intelligence", "endurance", "dexterity"}
    for k,v in ipairs(stats) do
      player.addCurrency(v .. "point", 1)
    end
    player.addCurrency("statpoint", points)
    self.class = player.currency("classtype")
    self.classInfo = root.assetJson("/classes/" .. self.classList[self.class == 0 and 7 or self.class] .. ".config")
    removeTechs()
    consumeAllCurrency("classtype")
    item.consume(1)
  end
end

function consumeAllCurrency(name)
  local amount = player.currency(name)
  player.consumeCurrency(name, amount)
  return amount
end

function uninit()
end

function removeTechs()
  for k,v in ipairs(self.classInfo.techs) do
    player.makeTechUnavailable(v.name)
  end
end

function consumeAffinityStats()
  for k,v in ipairs(self.affinityInfo.stats) do
    player.consumeCurrency(k .. "point", v)
  end
end