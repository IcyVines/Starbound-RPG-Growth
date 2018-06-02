function init()
end

function activate(fireMode, shiftHeld)
  self.specList = root.assetJson("/specList.config")
  if item.name() == "ivrpgscrollresetaffinity" and player.currency("affinitytype") ~= 0 then
    self.affinity = player.currency("affinitytype")
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
    self.affinity = player.currency("affinitytype")
    points = points - (self.affinity > 4 and 8 or (self.affinity > 0 and 3 or 0))
    player.addCurrency("statpoint", points)
    self.statType = {"strength", "agility", "vitality", "vigor", "intelligence", "endurance", "dexterity"}
    self.affinityStats = {
      {0, 0, 0, 3, 0, 0, 0},
      {0, 1, 0, 1, 0, 0, 1},
      {0, 0, 3, 0, 0, 0, 0},
      {0, 3, 0, 0, 0, 0, 0},
      {5, 0, 0, 3, 0, 0, 0},
      {0, 1, 0, 1, 0, 0, 6},
      {0, 0, 3, 0, 0, 5, 0},
      {0, 3, 0, 0, 5, 0, 0}
    }
    for i = 1,7 do
      player.addCurrency(self.statType[i].."point", 1 + (self.affinity > 0 and self.affinityStats[self.affinity][i] or 0))
    end
    self.class = player.currency("classtype")
    self.classList = root.assetJson("/classList.config")
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
  if self.affinity == 1 or self.affinity == 5 then
      --Flame
    player.consumeCurrency("vigorpoint", 3)
  elseif self.affinity == 2 or self.affinity == 6 then
    --Venom
    player.consumeCurrency("vigorpoint", 1)
    player.consumeCurrency("dexteritypoint", 1)
    player.consumeCurrency("agilitypoint", 1)
  elseif self.affinity == 3 or self.affinity == 7 then
    --Frost
    player.consumeCurrency("vitalitypoint", 3)
  elseif self.affinity == 4 or self.affinity == 8 then
    --Shock
    player.consumeCurrency("agilitypoint", 3)
  end

  if self.affinity == 5 then
    --Infernal
    player.consumeCurrency("strengthpoint", 5)
  elseif self.affinity == 6 then
    --Toxic
    player.consumeCurrency("dexteritypoint", 5)
  elseif self.affinity == 7 then
    --Cryo
    player.consumeCurrency("endurancepoint", 5)
  elseif self.affinity == 8 then
    --Arc
    player.consumeCurrency("intelligencepoint", 5)
  end
end